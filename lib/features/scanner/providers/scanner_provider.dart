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
  capturing,  // Taking a photo
  analyzing,  // Gemini is processing the image
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

  ScannerState({
    this.controller,
    this.isInitialized = false,
    this.phase = ScanPhase.idle,
    this.statusMessage = 'POINT AT PRODUCT',
    this.scannedProduct,
  });

  ScannerState copyWith({
    CameraController? controller,
    bool? isInitialized,
    ScanPhase? phase,
    String? statusMessage,
    Product? scannedProduct,
    bool clearProduct = false,
  }) {
    return ScannerState(
      controller: controller ?? this.controller,
      isInitialized: isInitialized ?? this.isInitialized,
      phase: phase ?? this.phase,
      statusMessage: statusMessage ?? this.statusMessage,
      scannedProduct: clearProduct ? null : (scannedProduct ?? this.scannedProduct),
    );
  }
}

class ScannerControllerNotifier extends StateNotifier<ScannerState> {
  ScannerControllerNotifier() : super(ScannerState());

  final GeminiService _gemini = GeminiService();
  final FirestoreService _firestore = FirestoreService();
  bool _isBusy = false;

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      state = state.copyWith(statusMessage: 'No cameras found');
      return;
    }

    final camera = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await controller.initialize();
      state = state.copyWith(
        controller: controller,
        isInitialized: true,
        statusMessage: 'POINT AT PRODUCT',
      );
    } catch (e) {
      state = state.copyWith(statusMessage: 'Camera error: $e');
    }
  }

  /// Capture photo → send to Gemini → identify product
  /// Called on double-tap from the scanner screen.
  Future<void> captureAndIdentify() async {
    if (_isBusy) return;
    if (state.controller == null || !state.isInitialized) return;

    _isBusy = true;

    try {
      // Phase 1: Capturing
      state = state.copyWith(
        phase: ScanPhase.capturing,
        statusMessage: 'CAPTURING...',
        clearProduct: true,
      );

      // Take the photo
      final XFile photo = await state.controller!.takePicture();
      final imageBytes = await photo.readAsBytes();

      // Phase 2: Analyzing with Gemini
      state = state.copyWith(
        phase: ScanPhase.analyzing,
        statusMessage: 'AI ANALYZING...',
      );

      // Send to Gemini
      _gemini.initialize();
      final product = await _gemini.identifyProduct(imageBytes);

      if (product != null) {
        // Phase 3: Found!
        state = state.copyWith(
          phase: ScanPhase.found,
          statusMessage: 'PRODUCT FOUND!',
          scannedProduct: product,
        );

        // Log scan to Firestore history
        await _firestore.logScan(product);
      } else {
        // Phase 3: Not found
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

  /// Reset to idle state (after navigating away from result/error)
  void resetToIdle() {
    state = state.copyWith(
      phase: ScanPhase.idle,
      statusMessage: 'POINT AT PRODUCT',
      clearProduct: true,
    );
  }

  @override
  void dispose() {
    state.controller?.dispose();
    super.dispose();
  }
}
