import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/product_model.dart';
import '../../../services/gemini_service.dart';
import '../../../services/firestore_service.dart';

final scannerControllerProvider = StateNotifierProvider<ScannerControllerNotifier, ScannerState>((ref) {
  return ScannerControllerNotifier();
});


enum ScanPhase {
  idle,
  capturing,
  analyzing,
  found,
  notFound,
  error,
}

class ScannerState {
  final CameraController? controller;
  final bool isInitialized;
  final ScanPhase phase;
  final String statusMessage;
  final Product? scannedProduct;

  final double captureProgress;

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

    if (state.isInitialized &&
        state.controller != null &&
        state.controller!.value.isInitialized) {
      return;
    }


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


  Future<void> _ensureCameraReady() async {
    final ctrl = state.controller;
    if (ctrl == null || !ctrl.value.isInitialized) {

      state = state.copyWith(isInitialized: false);
      await initializeCamera();
    }
  }



  Future<void> captureAndIdentify() async {
    if (_isBusy) return;

    _isBusy = true;

    try {

      await _ensureCameraReady();
      if (state.controller == null || !state.isInitialized) {
        state = state.copyWith(
          phase: ScanPhase.error,
          statusMessage: 'CAMERA UNAVAILABLE',
        );
        _isBusy = false;
        return;
      }


      state = state.copyWith(
        phase: ScanPhase.capturing,
        statusMessage: 'HOLD STEADY...',
        clearProduct: true,
        captureProgress: 0.0,
      );

      final List<Uint8List> capturedImages = [];

      const int burstCount = 3;
      const Duration burstInterval = Duration(milliseconds: 700);

      for (int i = 0; i < burstCount; i++) {
        if (!mounted) break;

        try {

          if (state.controller == null || !state.controller!.value.isInitialized) {
            break;
          }
          final XFile photo = await state.controller!.takePicture();
          final bytes = await photo.readAsBytes();
          capturedImages.add(bytes);
        } catch (e) {

          await Future.delayed(const Duration(milliseconds: 300));
        }


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


      final Uint8List bestImage = capturedImages.reduce(
        (best, current) => current.lengthInBytes > best.lengthInBytes ? current : best,
      );


      state = state.copyWith(
        phase: ScanPhase.analyzing,
        statusMessage: 'AI ANALYZING...',
        capturedImageBytes: bestImage,
      );


      _gemini.initialize();
      final product = await _gemini.identifyProduct(bestImage);

      if (product != null) {
        state = state.copyWith(
          phase: ScanPhase.found,
          statusMessage: 'PRODUCT FOUND!',
          scannedProduct: product,
        );

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



  void resetToIdle() {
    _isBusy = false;
    state = state.copyWith(
      phase: ScanPhase.idle,
      statusMessage: 'DOUBLE TAP TO SCAN',
      clearProduct: true,
      clearImage: true,
      captureProgress: 0.0,
    );

    _ensureCameraReady();
  }

  @override
  void dispose() {
    state.controller?.dispose();
    super.dispose();
  }
}
