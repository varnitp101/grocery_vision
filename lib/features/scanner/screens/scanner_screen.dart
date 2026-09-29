import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/scanner_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/yolo_detection.dart';
import 'product_result_screen.dart';
import 'scan_error_screen.dart';
import '../../../services/tts_service.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _analyzeSpinController;
  late AnimationController _progressController;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _analyzeSpinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scannerControllerProvider.notifier).initializeCamera();
    });
  }

  @override
  void dispose() {
    ref.read(ttsServiceProvider).stop();
    _pulseController.dispose();
    _analyzeSpinController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    final phase = ref.read(scannerControllerProvider).phase;
    if (phase == ScanPhase.idle) {
      _progressController.forward(from: 0.0);
      ref.read(scannerControllerProvider.notifier).handleDoubleTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final phase = ref.watch(scannerControllerProvider.select((s) => s.phase));
    final isGemini = phase == ScanPhase.geminiProcessing;
    final isCapturing = phase == ScanPhase.capturing ||
        phase == ScanPhase.barcodeProcessing;
    final isBarcodeChoice = phase == ScanPhase.barcodeChoicePrompt;

    ref.listen<ScannerState>(scannerControllerProvider, (prev, next) {
      if (_hasNavigated) return;

      if (next.phase == ScanPhase.productFound && next.scannedProduct != null) {
        _hasNavigated = true;
        if (mounted) {
          ref.read(scannerControllerProvider.notifier).pauseScanning();
        }
        Navigator.of(context)
            .push(
          MaterialPageRoute(
            builder: (_) => ProductResultScreen(
              product: next.scannedProduct!,
              capturedImage: next.capturedImageBytes,
            ),
          ),
        )
            .then((_) {
          _hasNavigated = false;
          if (mounted) {
            ref.read(scannerControllerProvider.notifier).resetScanner();
          }
        });
      } else if (next.phase == ScanPhase.notFound || next.phase == ScanPhase.error) {
        _hasNavigated = true;
        if (mounted) {
          ref.read(scannerControllerProvider.notifier).pauseScanning();
        }
        Navigator.of(context)
            .push(
          MaterialPageRoute(builder: (_) => const ScanErrorScreen()),
        )
            .then((_) {
          _hasNavigated = false;
          if (mounted) {
            ref.read(scannerControllerProvider.notifier).resetScanner();
          }
        });
      }
    });

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          ref.read(ttsServiceProvider).stop();
          ref.read(scannerControllerProvider.notifier).pauseScanning();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onDoubleTap: _handleDoubleTap,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Camera Preview Layer (never rebuilds on live YOLO detections!)
              const _CameraPreviewLayer(),

              // Live YOLO Bounding Boxes Layer (isolated repaint)
              const _YoloDetectionsLayer(),

              // AI Analyzing Screen
              if (isGemini) _buildAnalyzingScreen(),

              // Capturing / Barcode Scanning Overlay
              if (isCapturing) _buildCapturingOverlay(phase),

              // Barcode Choice Overlay (Fallback Options)
              if (isBarcodeChoice) _buildBarcodeChoiceOverlay(context),

              // Idle Scanner Frame & Guide
              if (phase == ScanPhase.idle) _buildIdleOverlay(context),

              // Bottom Cancel Bar
              if (!isGemini && !isBarcodeChoice) _buildCancelBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdleOverlay(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(190),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryAmber.withAlpha(80), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(120),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, color: AppTheme.primaryAmber, size: 22),
                SizedBox(width: 8),
                Text(
                  'AI VISION SCANNER',
                  style: TextStyle(
                    color: AppTheme.primaryAmber,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Text(
              'Live Detection Active • Double Tap Anywhere To Scan',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapturingOverlay(ScanPhase phase) {
    final isBarcode = phase == ScanPhase.barcodeProcessing;
    return Container(
      color: Colors.black.withAlpha(150),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryAmber.withAlpha(150),
                  width: 3,
                ),
              ),
              child: const Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      color: AppTheme.primaryAmber,
                    ),
                  ),
                  Icon(
                    Icons.center_focus_strong,
                    color: AppTheme.primaryAmber,
                    size: 44,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isBarcode ? 'SCANNING BARCODE' : 'CHECKING PRODUCT',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 3.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'HOLD STEADY',
              style: TextStyle(
                color: Colors.white.withAlpha(170),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// High-contrast accessible choice buttons when barcode is missing (Split Left / Right layout)
  Widget _buildBarcodeChoiceOverlay(BuildContext context) {
    return Container(
      color: const Color(0xF20A0F1C),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF132F4C),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withAlpha(40)),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.barcode_reader,
                      color: AppTheme.primaryAmber,
                      size: 44,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Barcode Not Detected',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Double tap the LEFT side to scan barcode again,\nor double tap the RIGHT side to search through OCR.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Split Left / Right Touch Panels
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // LEFT HALF: SCAN BARCODE AGAIN
                    Expanded(
                      child: Semantics(
                        label: 'Scan Barcode Again. Left half of screen. Double tap here to retry barcode scan.',
                        button: true,
                        child: GestureDetector(
                          onTap: () {
                            ref.read(ttsServiceProvider).stop();
                            ref.read(scannerControllerProvider.notifier).scanBarcodeAgain();
                          },
                          onDoubleTap: () {
                            ref.read(ttsServiceProvider).stop();
                            ref.read(scannerControllerProvider.notifier).scanBarcodeAgain();
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.primaryAmber.withAlpha(120), width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(100),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircleAvatar(
                                  radius: 36,
                                  backgroundColor: Colors.white12,
                                  child: Icon(Icons.refresh_rounded, size: 44, color: AppTheme.primaryAmber),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'SCAN BARCODE\nAGAIN',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: const BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.all(Radius.circular(10)),
                                  ),
                                  child: const Text(
                                    'LEFT SIDE',
                                    style: TextStyle(
                                      color: AppTheme.primaryAmber,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // RIGHT HALF: SEARCH THROUGH OCR
                    Expanded(
                      child: Semantics(
                        label: 'Search through OCR. Right half of screen. Double tap here to extract packaging text and details.',
                        button: true,
                        child: GestureDetector(
                          onTap: () {
                            ref.read(ttsServiceProvider).stop();
                            ref.read(scannerControllerProvider.notifier).searchThroughOcr();
                          },
                          onDoubleTap: () {
                            ref.read(ttsServiceProvider).stop();
                            ref.read(scannerControllerProvider.notifier).searchThroughOcr();
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryAmber,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryAmber.withAlpha(60),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircleAvatar(
                                  radius: 36,
                                  backgroundColor: AppTheme.darkNavy,
                                  child: Icon(Icons.document_scanner_rounded, size: 40, color: AppTheme.primaryAmber),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'SEARCH\nTHROUGH OCR',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppTheme.darkNavy,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.darkNavy,
                                    borderRadius: BorderRadius.all(Radius.circular(10)),
                                  ),
                                  child: const Text(
                                    'RIGHT SIDE',
                                    style: TextStyle(
                                      color: AppTheme.primaryAmber,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Dismiss / Cancel Button
              SizedBox(
                height: 48,
                child: TextButton.icon(
                  onPressed: () {
                    ref.read(ttsServiceProvider).stop();
                    ref.read(scannerControllerProvider.notifier).resetScanner();
                  },
                  icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                  label: const Text(
                    'Dismiss and Resume Camera',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyzingScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A0F1C),
            Color(0xFF111827),
            Color(0xFF0F172A),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _analyzeSpinController,
                    builder: (context, _) {
                      return Transform.rotate(
                        angle: _analyzeSpinController.value * 6.28,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.transparent, width: 3),
                            gradient: SweepGradient(
                              colors: [
                                Colors.transparent,
                                AppTheme.primaryAmber.withAlpha(30),
                                AppTheme.primaryAmber.withAlpha(150),
                                AppTheme.primaryAmber,
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      return Container(
                        width: 120 + (_pulseController.value * 16),
                        height: 120 + (_pulseController.value * 16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryAmber.withAlpha(15),
                          border: Border.all(
                            color: AppTheme.primaryAmber.withAlpha(
                              60 + (_pulseController.value * 40).toInt(),
                            ),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.document_scanner_rounded,
                          color: AppTheme.primaryAmber,
                          size: 48,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            const Text(
              'OCR PACKAGING EXTRACTION',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Reading packaging text, brand, and ingredients via OCR...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withAlpha(150),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(flex: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'Matching extracted OCR text with grocery item repository...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withAlpha(100),
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelBar(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Semantics(
        button: true,
        label: 'Cancel scanning',
        child: GestureDetector(
          onTap: () {
            ref.read(ttsServiceProvider).stop();
            ref.read(scannerControllerProvider.notifier).pauseScanning();
            Navigator.of(context).pop();
          },
          child: Container(
            height: 80 + MediaQuery.of(context).padding.bottom,
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
              color: AppTheme.primaryAmber,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(80),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.close, color: AppTheme.darkNavy, size: 32),
                  SizedBox(width: 12),
                  Text(
                    'CANCEL',
                    style: TextStyle(
                      color: AppTheme.darkNavy,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _YoloBoundingBoxPainter extends CustomPainter {
  final List<YoloDetection> detections;
  final Size screenSize;
  final double cameraAspectRatio;

  _YoloBoundingBoxPainter({
    required this.detections,
    required this.screenSize,
    this.cameraAspectRatio = 4 / 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final detection in detections) {
      final rect = detection.toRect(screenSize, cameraAspectRatio: cameraAspectRatio);

      // Box border
      final boxPaint = Paint()
        ..color = AppTheme.primaryAmber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5;

      // Glow effect
      final glowPaint = Paint()
        ..color = AppTheme.primaryAmber.withAlpha(80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), glowPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), boxPaint);

      // Label background
      final labelText = '${detection.displayName} ${(detection.confidence * 100).toInt()}%';
      final textSpan = TextSpan(
        text: labelText,
        style: const TextStyle(
          color: AppTheme.darkNavy,
          fontSize: 13,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final labelBgRect = Rect.fromLTWH(
        rect.left,
        (rect.top - 24).clamp(0.0, size.height - 24),
        textPainter.width + 12,
        22,
      );

      final bgPaint = Paint()..color = AppTheme.primaryAmber;
      canvas.drawRRect(RRect.fromRectAndRadius(labelBgRect, const Radius.circular(4)), bgPaint);

      textPainter.paint(
        canvas,
        Offset(labelBgRect.left + 6, labelBgRect.top + 3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _YoloBoundingBoxPainter oldDelegate) {
    return oldDelegate.detections != detections ||
        oldDelegate.screenSize != screenSize ||
        oldDelegate.cameraAspectRatio != cameraAspectRatio;
  }
}

class _CameraPreviewLayer extends ConsumerWidget {
  const _CameraPreviewLayer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGemini = ref.watch(
      scannerControllerProvider.select((s) => s.phase == ScanPhase.geminiProcessing),
    );
    if (isGemini) return const SizedBox.shrink();

    final isInitialized = ref.watch(
      scannerControllerProvider.select((s) => s.isInitialized),
    );
    final camera = ref.watch(
      scannerControllerProvider.select((s) => s.controller),
    );

    if (isInitialized && camera != null && camera.value.isInitialized) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final cameraAspect = camera.value.aspectRatio;
          final screenAspect = constraints.maxWidth / constraints.maxHeight;
          var scale = 1.0;
          if (screenAspect < 1.0) {
            scale = 1.0 / (cameraAspect * screenAspect);
          } else {
            scale = cameraAspect / screenAspect;
          }
          if (scale < 1.0) scale = 1.0 / scale;

          return ClipRect(
            child: Transform.scale(
              scale: scale,
              child: Center(
                child: CameraPreview(camera),
              ),
            ),
          );
        },
      );
    }
    return Container(
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryAmber),
      ),
    );
  }
}

class _YoloDetectionsLayer extends ConsumerWidget {
  const _YoloDetectionsLayer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(
      scannerControllerProvider.select((s) => s.phase),
    );
    if (phase != ScanPhase.idle) return const SizedBox.shrink();

    final detections = ref.watch(
      scannerControllerProvider.select((s) => s.detections),
    );
    if (detections.isEmpty) return const SizedBox.shrink();

    final camera = ref.watch(
      scannerControllerProvider.select((s) => s.controller),
    );
    final cameraAspectRatio = camera?.value.aspectRatio ?? (4 / 3);

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _YoloBoundingBoxPainter(
            detections: detections,
            screenSize: Size(constraints.maxWidth, constraints.maxHeight),
            cameraAspectRatio: cameraAspectRatio,
          ),
        );
      },
    );
  }
}
