import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/product_model.dart';
import '../../../services/gemini_service.dart';
import '../../../services/firestore_service.dart';

final scannerControllerProvider = StateNotifierProvider<ScannerControllerNotifier, ScannerState>((ref) {
  return ScannerControllerNotifier();
});

/// Possible scanner phases
enum ScanPhase {
  idle,       // Camera live, waiting for user action
  capturing,  // Taking burst photos (~2 seconds)
  analyzing,  // Gemini is processing the best image (camera dismissed)
  found,      // Product identified
  notFound,   // Product not recognized
  error,      // Something went wrong
}

class ScannerState {
  final CameraController? controller;
  final bool isInitialized;
  final ScanPhase phase;
  final String statusMessage;
  final Product? scannedProduct;
  /// Progress during capture burst: 0.0 to 1.0
  final double captureProgress;
  /// The best captured image bytes from burst capture
  final Uint8List? capturedImageBytes;

  ScannerState({
    this.controller,
    this.isInitialized = false,
    this.phase = ScanPhase.idle,
    this.statusMessage = 'DOUBLE TAP TO SCAN',
    this.scannedProduct,
    this.captureProgress = 0.0,
    this.capturedImageBytes,
  });

  ScannerState copyWith({
    CameraController? controller,
    bool? isInitialized,
    ScanPhase? phase,
    String? statusMessage,
    Product? scannedProduct,
    bool clearProduct = false,
    double? captureProgress,
    Uint8List? capturedImageBytes,
    bool clearImage = false,
  }) {
    return ScannerState(
      controller: controller ?? this.controller,
      isInitialized: isInitialized ?? this.isInitialized,
      phase: phase ?? this.phase,
      statusMessage: statusMessage ?? this.statusMessage,
      scannedProduct: clearProduct ? null : (scannedProduct ?? this.scannedProduct),
      captureProgress: captureProgress ?? this.captureProgress,
      capturedImageBytes: clearImage ? null : (capturedImageBytes ?? this.capturedImageBytes),
    );
  }
}

class ScannerControllerNotifier extends StateNotifier<ScannerState> {
  ScannerControllerNotifier() : super(ScannerState());

  final GeminiService _gemini = GeminiService();
  final FirestoreService _firestore = FirestoreService();
  bool _isBusy = false;
  CameraDescription? _cameraDescription;

  Future<void> initializeCamera() async {
    // If we already have a working controller, skip
    if (state.isInitialized &&
        state.controller != null &&
        state.controller!.value.isInitialized) {
      return;
    }

    // Dispose any old controller first
    try {
      await state.controller?.dispose();
    } catch (_) {}

    try {
      if (_cameraDescription == null) {
        final cameras = await availableCameras();
        if (cameras.isEmpty) {
          state = state.copyWith(statusMessage: 'No cameras found');
          return;
        }
        _cameraDescription = cameras.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );
      }

      final controller = CameraController(
        _cameraDescription!,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();
      state = state.copyWith(
        controller: controller,
        isInitialized: true,
        phase: ScanPhase.idle,
        statusMessage: 'DOUBLE TAP TO SCAN',
      );
    } catch (e) {
      state = state.copyWith(
        isInitialized: false,
        statusMessage: 'Camera error — reopen scanner',
      );
    }
  }

  /// Reinitialize camera if it crashed or got disposed.
  Future<void> _ensureCameraReady() async {
    final ctrl = state.controller;
    if (ctrl == null || !ctrl.value.isInitialized) {
      // Force re-create the controller
      state = state.copyWith(isInitialized: false);
      await initializeCamera();
    }
  }

  /// Burst-capture 3 photos over ~2 seconds, pick the sharpest one,
  /// then send it to Gemini for identification.
  Future<void> captureAndIdentify() async {
    if (_isBusy) return;

    _isBusy = true;

    try {
      // Make sure camera is alive before we start
      await _ensureCameraReady();
      if (state.controller == null || !state.isInitialized) {
        state = state.copyWith(
          phase: ScanPhase.error,
          statusMessage: 'CAMERA UNAVAILABLE',
        );
        _isBusy = false;
        return;
      }

      // Phase 1: Burst capture
      state = state.copyWith(
        phase: ScanPhase.capturing,
        statusMessage: 'HOLD STEADY...',
        clearProduct: true,
        captureProgress: 0.0,
      );

      final List<Uint8List> capturedImages = [];
      // 3 photos with 700ms gaps = ~2.1s total (safer for device cameras)
      const int burstCount = 3;
      const Duration burstInterval = Duration(milliseconds: 700);

      for (int i = 0; i < burstCount; i++) {
        if (!mounted) break;

        try {
          // Check controller is still valid before each shot
          if (state.controller == null || !state.controller!.value.isInitialized) {
            break;
          }
          final XFile photo = await state.controller!.takePicture();
          final bytes = await photo.readAsBytes();
          capturedImages.add(bytes);
        } catch (e) {
          // Camera may have errored — wait and try again for next shot
          await Future.delayed(const Duration(milliseconds: 300));
        }

        // Update progress
        state = state.copyWith(
          captureProgress: (i + 1) / burstCount,
        );

        if (i < burstCount - 1) {
          await Future.delayed(burstInterval);
        }
      }

      if (capturedImages.isEmpty) {
        state = state.copyWith(
          phase: ScanPhase.error,
          statusMessage: 'CAPTURE FAILED',
        );
        _isBusy = false;
        return;
      }

      // Pick best image — larger file = sharper/more detail (JPEG compression)
      final Uint8List bestImage = capturedImages.reduce(
        (best, current) => current.lengthInBytes > best.lengthInBytes ? current : best,
      );

      // Phase 2: Analyzing — full-screen overlay replaces camera
      state = state.copyWith(
        phase: ScanPhase.analyzing,
        statusMessage: 'AI ANALYZING...',
        capturedImageBytes: bestImage,
      );

      // Send to Gemini
      _gemini.initialize();
      final product = await _gemini.identifyProduct(bestImage);

      if (product != null) {
        state = state.copyWith(
          phase: ScanPhase.found,
          statusMessage: 'PRODUCT FOUND!',
          scannedProduct: product,
        );
        // Log scan to Firestore history (don't block on this)
        _firestore.logScan(product);
      } else {
        state = state.copyWith(
          phase: ScanPhase.notFound,
          statusMessage: 'NOT RECOGNIZED',
        );
      }
    } catch (e) {
      state = state.copyWith(
        phase: ScanPhase.error,
        statusMessage: 'SCAN FAILED',
      );
    } finally {
      _isBusy = false;
    }
  }

  /// Reset to idle state so user can scan again.
  /// Also re-initializes camera if it died during the last scan.
  void resetToIdle() {
    _isBusy = false;
    state = state.copyWith(
      phase: ScanPhase.idle,
      statusMessage: 'DOUBLE TAP TO SCAN',
      clearProduct: true,
      clearImage: true,
      captureProgress: 0.0,
    );
    // Re-init camera in background if it died
    _ensureCameraReady();
  }

  @override
  void dispose() {
    state.controller?.dispose();
    super.dispose();
  }
}
