import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/product_model.dart';
import '../../../models/yolo_detection.dart';
import '../../../services/barcode_product_repository.dart';
import '../../../services/barcode_service.dart';
import '../../../services/firestore_service.dart';
import '../../../services/gemini_service.dart';
import '../../../services/haptic_service.dart';
import '../../../services/local_history_service.dart';
import '../../../services/tts_service.dart';
import '../../../services/yolo_service.dart';
import '../../../utils/image_converter.dart';
import 'package:path_provider/path_provider.dart';

enum ScanPhase {
  idle,
  capturing,
  barcodeProcessing,
  barcodeChoicePrompt,
  geminiProcessing,
  productFound,
  notFound,
  error,
}

class ScannerState {
  final CameraController? controller;
  final bool isInitialized;
  final ScanPhase phase;
  final String statusMessage;
  final Product? scannedProduct;
  final List<YoloDetection> detections;
  final double captureProgress;
  final Uint8List? capturedImageBytes;
  final String? capturedImagePath;

  ScannerState({
    this.controller,
    this.isInitialized = false,
    this.phase = ScanPhase.idle,
    this.statusMessage = 'DOUBLE TAP TO RECOGNIZE PRODUCT',
    this.scannedProduct,
    this.detections = const [],
    this.captureProgress = 0.0,
    this.capturedImageBytes,
    this.capturedImagePath,
  });

  ScannerState copyWith({
    CameraController? controller,
    bool? isInitialized,
    ScanPhase? phase,
    String? statusMessage,
    Product? scannedProduct,
    bool clearProduct = false,
    List<YoloDetection>? detections,
    double? captureProgress,
    Uint8List? capturedImageBytes,
    String? capturedImagePath,
    bool clearImage = false,
  }) {
    return ScannerState(
      controller: controller ?? this.controller,
      isInitialized: isInitialized ?? this.isInitialized,
      phase: phase ?? this.phase,
      statusMessage: statusMessage ?? this.statusMessage,
      scannedProduct: clearProduct ? null : (scannedProduct ?? this.scannedProduct),
      detections: detections ?? this.detections,
      captureProgress: captureProgress ?? this.captureProgress,
      capturedImageBytes: clearImage ? null : (capturedImageBytes ?? this.capturedImageBytes),
      capturedImagePath: clearImage ? null : (capturedImagePath ?? this.capturedImagePath),
    );
  }
}

class ScannerControllerNotifier extends StateNotifier<ScannerState> {
  final Ref _ref;
  ScannerControllerNotifier(this._ref) : super(ScannerState());

  final GeminiService _gemini = GeminiService();
  final FirestoreService _firestore = FirestoreService();
  CameraDescription? _cameraDescription;

  bool _isBusy = false;
  bool _isStreaming = false;
  bool _isProcessingFrame = false;
  DateTime _lastFrameInferenceTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const int inferenceThrottleMs = 150;

  Timer? _silenceTimer;
  Completer<Uint8List>? _frameCaptureCompleter;

  YoloService get _yolo => _ref.read(yoloServiceProvider);
  BarcodeService get _barcode => _ref.read(barcodeServiceProvider);
  BarcodeProductRepository get _barcodeRepo => _ref.read(barcodeProductRepositoryProvider);
  TtsService get _tts => _ref.read(ttsServiceProvider);
  HapticService get _haptic => _ref.read(hapticServiceProvider);
  LocalHistoryService get _localHistory => _ref.read(localHistoryServiceProvider);

  Future<void> initializeCamera({bool forceRecreate = false}) async {
    if (!forceRecreate &&
        state.isInitialized &&
        state.controller != null &&
        state.controller!.value.isInitialized) {
      await _startLiveStream();
      _startSilenceChecker();
      return;
    }

    try {
      await _stopLiveStream();
      final oldCtrl = state.controller;
      if (oldCtrl != null) {
        try {
          await oldCtrl.dispose();
        } catch (_) {}
      }
    } catch (_) {}

    try {
      await _yolo.initialize();
      await _barcodeRepo.initialize();

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
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.yuv420 : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();
      try {
        await controller.setFocusMode(FocusMode.auto);
      } catch (_) {}
      try {
        await controller.setExposureMode(ExposureMode.auto);
      } catch (_) {}

      state = state.copyWith(
        controller: controller,
        isInitialized: true,
        phase: ScanPhase.idle,
        statusMessage: 'DOUBLE TAP TO RECOGNIZE PRODUCT',
      );

      await _startLiveStream();
      _startSilenceChecker();
    } catch (e, stack) {
      debugPrint('initializeCamera error: $e\n$stack');
      state = state.copyWith(
        isInitialized: false,
        statusMessage: 'Camera error — reopen scanner',
      );
    }
  }

  void _startSilenceChecker() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (state.phase == ScanPhase.idle && _isStreaming) {
        if (_yolo.shouldTriggerSilenceReminder()) {
          _tts.speak(
            'Looking for grocery items. Move closer or adjust angle.',
            priority: TtsPriority.guidance,
          );
        }
      }
    });
  }

  Future<void> _startLiveStream() async {
    final ctrl = state.controller;
    if (ctrl == null || !ctrl.value.isInitialized) {
      debugPrint('_startLiveStream: controller not initialized, skipping');
      return;
    }

    try {
      // If controller is already streaming images, stop it first to ensure clean state
      if (ctrl.value.isStreamingImages) {
        debugPrint('_startLiveStream: stopping lingering stream first...');
        try {
          await ctrl.stopImageStream();
        } catch (_) {}
      }

      // Try to resume preview if paused by Android ImageCapture
      try {
        await ctrl.resumePreview();
      } catch (_) {}

      _isStreaming = true;
      _isProcessingFrame = false;
      debugPrint('Starting camera image stream...');
      await ctrl.startImageStream((CameraImage image) {
        _onFrameReceived(image);
      });
      debugPrint('Camera image stream started successfully!');
    } catch (e, stack) {
      debugPrint('ERROR in startImageStream: $e\n$stack');
      _isStreaming = false;
      // If startImageStream failed (e.g. surface lost), recreate camera cleanly
      debugPrint('Recreating camera to restore live video feed...');
      await initializeCamera(forceRecreate: true);
    }
  }

  Future<void> _stopLiveStream() async {
    _isStreaming = false;
    final ctrl = state.controller;
    if (ctrl != null && ctrl.value.isInitialized) {
      try {
        if (ctrl.value.isStreamingImages) {
          debugPrint('Stopping camera image stream...');
          await ctrl.stopImageStream();
          debugPrint('Camera image stream stopped successfully.');
        }
      } catch (e) {
        debugPrint('Error stopping image stream: $e');
      }
    }
  }

  void _onFrameReceived(CameraImage image) async {
    final sensorOrientation = _cameraDescription?.sensorOrientation ?? 90;

    // Check if an instant frame capture was requested (via double tap)
    if (_frameCaptureCompleter != null && !_frameCaptureCompleter!.isCompleted) {
      try {
        final jpeg = ImageConverter.convertCameraImageToJpeg(
          image,
          sensorOrientation: sensorOrientation,
        );
        if (jpeg != null) {
          _frameCaptureCompleter!.complete(jpeg);
        }
      } catch (e) {
        debugPrint('Error converting live frame: $e');
      }
    }

    // Drop frame immediately if previous inference is still active
    if (_isProcessingFrame || state.phase != ScanPhase.idle || !_isStreaming) return;

    final now = DateTime.now();
    if (now.difference(_lastFrameInferenceTime).inMilliseconds < inferenceThrottleMs) {
      return;
    }
    _isProcessingFrame = true;
    _lastFrameInferenceTime = now;

    try {
      final detections = await _yolo.detectFromCameraImage(
        image,
        sensorOrientation: sensorOrientation,
        confidenceThreshold: 0.25,
      );

      if (!mounted || state.phase != ScanPhase.idle) {
        _isProcessingFrame = false;
        return;
      }

      state = state.copyWith(detections: detections);

      final productName = _yolo.processTemporalStability(detections);
      if (productName != null) {
        _haptic.detectionStable();
        _tts.speak(productName, priority: TtsPriority.normal);
      }
    } catch (e, stack) {
      debugPrint('Error in _onFrameReceived: $e\n$stack');
    } finally {
      _isProcessingFrame = false;
    }
  }

  /// Pause all active scanning, camera stream, speech, and silence guidance
  Future<void> pauseScanning() async {
    _silenceTimer?.cancel();
    _silenceTimer = null;
    await _stopLiveStream();
    _tts.stop();
    _yolo.resetStability();
    _isProcessingFrame = false;
    if (mounted) {
      state = state.copyWith(detections: []);
    }
  }

  /// Resume scanning when screen becomes active
  void resumeScanning() {
    if (state.phase == ScanPhase.idle && state.isInitialized) {
      _startLiveStream();
      _startSilenceChecker();
    }
  }

  /// Triggered by accessible double-tap gesture on the camera screen
  Future<void> handleDoubleTap() async {
    if (_isBusy || state.phase != ScanPhase.idle) return;
    _isBusy = true;

    try {
      await _haptic.captureTriggered();
      await _tts.speak('Checking product...', priority: TtsPriority.immediate);

      state = state.copyWith(
        phase: ScanPhase.capturing,
        statusMessage: 'CHECKING PRODUCT...',
        detections: [],
        clearProduct: true,
        captureProgress: 0.2,
      );

      Uint8List? bytes;
      String? imagePath;

      // 1. Instant crash-free capture from live camera stream (no hardware session reconfigure)
      _frameCaptureCompleter = Completer<Uint8List>();
      try {
        bytes = await _frameCaptureCompleter!.future.timeout(const Duration(milliseconds: 600));
      } catch (_) {
        debugPrint('Live frame capture timed out, attempting fallback...');
      } finally {
        _frameCaptureCompleter = null;
      }

      if (bytes != null && bytes.isNotEmpty) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/scan_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await file.writeAsBytes(bytes, flush: true);
        imagePath = file.path;
      } else {
        // Fallback: take picture via controller if live stream was inactive
        final ctrl = state.controller;
        if (ctrl != null && ctrl.value.isInitialized) {
          await pauseScanning();
          await Future.delayed(const Duration(milliseconds: 150));
          final XFile photo = await ctrl.takePicture();
          bytes = await photo.readAsBytes();
          imagePath = photo.path;
        }
      }

      if (bytes == null || imagePath == null) {
        state = state.copyWith(
          phase: ScanPhase.error,
          statusMessage: 'CAMERA CAPTURE ERROR',
        );
        _isBusy = false;
        return;
      }

      state = state.copyWith(
        phase: ScanPhase.barcodeProcessing,
        statusMessage: 'SCANNING BARCODE...',
        capturedImageBytes: bytes,
        capturedImagePath: imagePath,
        captureProgress: 0.5,
      );

      final barcodeValue = await _barcode.scanImage(imagePath);
      debugPrint('MLKit Barcode value detected: "$barcodeValue"');

      if (barcodeValue != null && barcodeValue.isNotEmpty) {
        final product = await _barcodeRepo.getProductByBarcode(barcodeValue);
        debugPrint('Product from repository: ${product?.name}');
        if (product != null) {
          await _onProductSuccessfullyIdentified(product);
          _isBusy = false;
          return;
        }
      }

      await _haptic.failureOrRetry();
      state = state.copyWith(
        phase: ScanPhase.barcodeChoicePrompt,
        statusMessage: 'BARCODE NOT FOUND — CHOOSE OPTION',
        captureProgress: 0.7,
      );

      await _tts.speak(
        'Barcode not recognized. Double tap on the left side to scan barcode again, or double tap on the right side to search through OCR.',
        priority: TtsPriority.immediate,
      );
    } catch (e) {
      state = state.copyWith(
        phase: ScanPhase.error,
        statusMessage: 'SCAN ERROR',
      );
      _tts.speak('Scan failed. Please try again.', priority: TtsPriority.immediate);
    } finally {
      _isBusy = false;
    }
  }

  Future<void> scanBarcodeAgain() async {
    _tts.stop();
    resetScanner();
  }

  Future<void> searchThroughOcr() async {
    if (_isBusy || state.capturedImageBytes == null) return;
    _isBusy = true;

    try {
      await _haptic.captureTriggered();
      await _tts.speak('Extracting packaging text and details through OCR...', priority: TtsPriority.immediate);

      state = state.copyWith(
        phase: ScanPhase.geminiProcessing,
        statusMessage: 'SEARCHING THROUGH OCR...',
        captureProgress: 0.85,
      );

      _gemini.initialize();
      final product = await _gemini.identifyProduct(state.capturedImageBytes!);

      if (product != null) {
        await _onProductSuccessfullyIdentified(product);
      } else {
        await _haptic.failureOrRetry();
        state = state.copyWith(
          phase: ScanPhase.notFound,
          statusMessage: 'PRODUCT NOT RECOGNIZED',
        );
        await _tts.speak(
          'Product could not be recognized. Try another angle or lighting.',
          priority: TtsPriority.immediate,
        );
      }
    } catch (e) {
      state = state.copyWith(
        phase: ScanPhase.error,
        statusMessage: 'OCR EXTRACTION ERROR',
      );
      _tts.speak('Could not extract details. Please try again.', priority: TtsPriority.immediate);
    } finally {
      _isBusy = false;
    }
  }

  // Alias for backward compatibility
  Future<void> getDetailsFromWeb() => searchThroughOcr();

  Future<void> _onProductSuccessfullyIdentified(Product product) async {
    await _haptic.productFound();
    await _localHistory.saveScan(product);
    _firestore.logScan(product);

    state = state.copyWith(
      phase: ScanPhase.productFound,
      statusMessage: 'PRODUCT FOUND!',
      scannedProduct: product,
      captureProgress: 1.0,
    );

    final priceSpeech = product.mrp != null && product.mrp! > 0
        ? 'Price ${product.mrp!.toStringAsFixed(product.mrp!.truncateToDouble() == product.mrp! ? 0 : 2)} rupees.'
        : (product.price != null && product.price!.isNotEmpty ? 'Price ${product.price}.' : '');

    final brandSpeech = product.brand.isNotEmpty && product.brand != 'Unknown Brand'
        ? 'by ${product.brand}.'
        : '';

    final summary = '${product.name} $brandSpeech $priceSpeech Double tap Add to Cart or Scan Another.';
    await _tts.speak(summary, priority: TtsPriority.immediate);
  }

  Future<void> resetScanner() async {
    _isBusy = false;
    _isProcessingFrame = false;
    _yolo.resetStability();
    state = state.copyWith(
      phase: ScanPhase.idle,
      statusMessage: 'DOUBLE TAP TO RECOGNIZE PRODUCT',
      clearProduct: true,
      clearImage: true,
      captureProgress: 0.0,
      detections: [],
    );

    final ctrl = state.controller;
    if (ctrl == null || !ctrl.value.isInitialized) {
      debugPrint('resetScanner: Controller uninitialized, recreating camera...');
      await initializeCamera(forceRecreate: true);
      return;
    }

    try {
      if (ctrl.value.isStreamingImages) {
        try {
          await ctrl.stopImageStream();
        } catch (_) {}
      }

      try {
        await ctrl.resumePreview();
      } catch (_) {}

      await _startLiveStream();
      _startSilenceChecker();
    } catch (e) {
      debugPrint('resetScanner error: $e. Recreating camera...');
      await initializeCamera(forceRecreate: true);
    }
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _silenceTimer = null;
    _isStreaming = false;
    _stopLiveStream();
    _tts.stop();
    _yolo.resetStability();
    state.controller?.dispose();
    super.dispose();
  }
}

final scannerControllerProvider =
    StateNotifierProvider.autoDispose<ScannerControllerNotifier, ScannerState>((ref) {
  return ScannerControllerNotifier(ref);
});
