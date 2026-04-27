import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final scannerControllerProvider = StateNotifierProvider<ScannerControllerNotifier, ScannerState>((ref) {
  return ScannerControllerNotifier();
});

class ScannerState {
  final CameraController? controller;
  final bool isInitialized;
  final bool isProcessing;
  final String statusMessage;
  final double luminosity;

  ScannerState({
    this.controller,
    this.isInitialized = false,
    this.isProcessing = false,
    this.statusMessage = 'System Ready',
    this.luminosity = 100.0,
  });

  ScannerState copyWith({
    CameraController? controller,
    bool? isInitialized,
    bool? isProcessing,
    String? statusMessage,
    double? luminosity,
  }) {
    return ScannerState(
      controller: controller ?? this.controller,
      isInitialized: isInitialized ?? this.isInitialized,
      isProcessing: isProcessing ?? this.isProcessing,
      statusMessage: statusMessage ?? this.statusMessage,
      luminosity: luminosity ?? this.luminosity,
    );
  }
}

class ScannerControllerNotifier extends StateNotifier<ScannerState> {
  ScannerControllerNotifier() : super(ScannerState());

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
        statusMessage: 'Point at product',
      );
      
      // Start image stream for luminosity/barcode processing later
      // controller.startImageStream((image) => _processCameraImage(image));
    } catch (e) {
      state = state.copyWith(statusMessage: 'Camera error: $e');
    }
  }

  @override
  void dispose() {
    state.controller?.dispose();
    super.dispose();
  }
}
