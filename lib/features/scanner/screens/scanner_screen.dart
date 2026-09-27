import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/scanner_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/yolo_detection.dart';
import 'product_result_screen.dart';
import 'scan_error_screen.dart';

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
    _pulseController.dispose();
    _analyzeSpinController.dispose();
    _progressController.dispose();
    ref.read(scannerControllerProvider.notifier).pauseScanning();
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
        ref.read(scannerControllerProvider.notifier).pauseScanning();
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
          ref.read(scannerControllerProvider.notifier).resetScanner();
        });
      } else if (next.phase == ScanPhase.notFound || next.phase == ScanPhase.error) {
        _hasNavigated = true;
        ref.read(scannerControllerProvider.notifier).pauseScanning();
        Navigator.of(context)
            .push(
          MaterialPageRoute(builder: (_) => const ScanErrorScreen()),
        )
            .then((_) {
          _hasNavigated = false;
          ref.read(scannerControllerProvider.notifier).resetScanner();
        });
      }
    });

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
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
    return Stack(
      children: [
        Center(
          child: SizedBox(
            width: 280,
            height: 280,
            child: Stack(
              children: [
                Align(alignment: Alignment.topLeft, child: _buildCorner(top: true, left: true)),
                Align(alignment: Alignment.topRight, child: _buildCorner(top: true, left: false)),
                Align(alignment: Alignment.bottomLeft, child: _buildCorner(top: false, left: true)),
                Align(alignment: Alignment.bottomRight, child: _buildCorner(top: false, left: false)),
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    return Positioned(
                      top: 20 + (_pulseController.value * 240),
                      left: 20,
                      right: 20,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppTheme.primaryAmber.withAlpha(200),
                              AppTheme.primaryAmber,
                              AppTheme.primaryAmber.withAlpha(200),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryAmber.withAlpha(100),
                              blurRadius: 12,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // Header instructions
        Positioned(
          top: MediaQuery.of(context).padding.top + 24,
          left: 24,
          right: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(200),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryAmber.withAlpha(80)),
            ),
            child: const Column(
              children: [
                Text(
                  'POINT AT PRODUCT',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'DOUBLE TAP ANYWHERE TO SCAN',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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

  /// High-contrast accessible choice buttons when barcode is missing
  Widget _buildBarcodeChoiceOverlay(BuildContext context) {
    return Container(
      color: const Color(0xEA0A0F1C),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF132F4C),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withAlpha(30)),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.barcode_reader,
                      color: AppTheme.primaryAmber,
                      size: 56,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Barcode Not Detected',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Would you like to try scanning the barcode again, or fetch details using AI web vision?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Button 1: Scan Barcode Again
              Semantics(
                label: 'Scan Barcode Again. Returns to live camera.',
                button: true,
                child: SizedBox(
                  height: 68,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withAlpha(20),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      side: const BorderSide(color: Colors.white54, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      ref.read(scannerControllerProvider.notifier).scanBarcodeAgain();
                    },
                    icon: const Icon(Icons.refresh, size: 28),
                    label: const Text(
                      'SCAN BARCODE AGAIN',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Button 2: Get Details from Web (Gemini)
              Semantics(
                label: 'Get Details from Web. Uses AI to analyze the full captured image.',
                button: true,
                child: SizedBox(
                  height: 68,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryAmber,
                      foregroundColor: AppTheme.darkNavy,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      ref.read(scannerControllerProvider.notifier).getDetailsFromWeb();
                    },
                    icon: const Icon(Icons.auto_awesome, size: 28),
                    label: const Text(
                      'GET DETAILS FROM WEB',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Cancel button
              TextButton(
                onPressed: () {
                  ref.read(scannerControllerProvider.notifier).resetScanner();
                },
                child: const Text(
                  'Dismiss and Resume',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                          Icons.auto_awesome,
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
              'AI VISUAL SEARCH',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 4.0,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Analyzing packaging and text details...',
              style: TextStyle(
                color: Colors.white.withAlpha(150),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(flex: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'Searching across grocery database and web...',
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

  Widget _buildCorner({required bool top, required bool left}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        border: Border(
          top: top
              ? const BorderSide(color: AppTheme.primaryAmber, width: 5)
              : BorderSide.none,
          bottom: !top
              ? const BorderSide(color: AppTheme.primaryAmber, width: 5)
              : BorderSide.none,
          left: left
              ? const BorderSide(color: AppTheme.primaryAmber, width: 5)
              : BorderSide.none,
          right: !left
              ? const BorderSide(color: AppTheme.primaryAmber, width: 5)
              : BorderSide.none,
        ),
      ),
    );
  }
}

class _YoloBoundingBoxPainter extends CustomPainter {
  final List<YoloDetection> detections;
  final Size screenSize;

  _YoloBoundingBoxPainter({required this.detections, required this.screenSize});

  @override
  void paint(Canvas canvas, Size size) {
    for (final detection in detections) {
      final rect = detection.toRect(screenSize);

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
    return oldDelegate.detections != detections;
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
          return ClipRect(
            child: OverflowBox(
              alignment: Alignment.center,
              maxWidth: double.infinity,
              maxHeight: double.infinity,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxWidth * camera.value.aspectRatio,
                  child: CameraPreview(camera),
                ),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _YoloBoundingBoxPainter(
            detections: detections,
            screenSize: Size(constraints.maxWidth, constraints.maxHeight),
          ),
        );
      },
    );
  }
}
