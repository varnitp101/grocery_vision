import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/scanner_provider.dart';
import '../../../core/theme/app_theme.dart';
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
    super.dispose();
  }

  void _handleDoubleTap() {
    final phase = ref.read(scannerControllerProvider).phase;
    if (phase == ScanPhase.idle) {
      HapticFeedback.mediumImpact();
      _progressController.forward(from: 0.0);
      ref.read(scannerControllerProvider.notifier).captureAndIdentify();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scannerState = ref.watch(scannerControllerProvider);
    final isAnalyzing = scannerState.phase == ScanPhase.analyzing;
    final isCapturing = scannerState.phase == ScanPhase.capturing;

    // Listen for phase changes and navigate accordingly
    ref.listen<ScannerState>(scannerControllerProvider, (prev, next) {
      if (_hasNavigated) return;

      // Double haptic when analysis begins
      if (prev?.phase != ScanPhase.analyzing && next.phase == ScanPhase.analyzing) {
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 100), () {
          HapticFeedback.heavyImpact();
        });
      }

      if (next.phase == ScanPhase.found && next.scannedProduct != null) {
        _hasNavigated = true;
        HapticFeedback.heavyImpact();
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
          ref.read(scannerControllerProvider.notifier).resetToIdle();
        });
      } else if (next.phase == ScanPhase.notFound ||
          next.phase == ScanPhase.error) {
        _hasNavigated = true;
        HapticFeedback.heavyImpact();
        Navigator.of(context)
            .push(
          MaterialPageRoute(builder: (_) => const ScanErrorScreen()),
        )
            .then((_) {
          _hasNavigated = false;
          ref.read(scannerControllerProvider.notifier).resetToIdle();
        });
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        // Full-screen double-tap to scan
        onDoubleTap: _handleDoubleTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Camera preview (hidden during analyzing phase)
            if (!isAnalyzing)
              _buildCameraLayer(scannerState),

            // Full-screen modern analyzing overlay
            if (isAnalyzing)
              _buildAnalyzingScreen(),

            // Capturing overlay (shows on top of camera during burst)
            if (isCapturing)
              _buildCapturingOverlay(scannerState),

            // Idle state UI (corners + instruction)
            if (scannerState.phase == ScanPhase.idle)
              _buildIdleOverlay(context),

            // Cancel button at bottom (only during idle + capturing)
            if (!isAnalyzing)
              _buildCancelBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraLayer(ScannerState scannerState) {
    if (scannerState.isInitialized && scannerState.controller != null) {
      final camera = scannerState.controller!;
      return LayoutBuilder(
        builder: (context, constraints) {
          // Use FittedBox with cover to maintain aspect ratio without stretching
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

  Widget _buildIdleOverlay(BuildContext context) {
    return Stack(
      children: [
        // Corner brackets
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
                // Scanning line
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

        // Status text + instruction at top
        Positioned(
          top: MediaQuery.of(context).padding.top + 24,
          left: 24,
          right: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(200),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryAmber.withAlpha(60)),
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

  Widget _buildCapturingOverlay(ScannerState scannerState) {
    return Container(
      color: Colors.black.withAlpha(120),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Flash animation
            AnimatedBuilder(
              animation: _progressController,
              builder: (context, _) {
                return Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withAlpha(
                        (100 + (_progressController.value * 155)).toInt(),
                      ),
                      width: 4,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Circular progress
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: scannerState.captureProgress,
                          strokeWidth: 6,
                          color: AppTheme.primaryAmber,
                          backgroundColor: Colors.white.withAlpha(30),
                        ),
                      ),
                      // Photo count
                      Text(
                        '${(scannerState.captureProgress * 3).ceil()}/3',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'CAPTURING',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 4.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'HOLD STEADY',
              style: TextStyle(
                color: Colors.white.withAlpha(150),
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

  /// Full-screen modern AI analyzing overlay — replaces the camera view entirely.
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

            // Spinning AI ring
            SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer spinning ring
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
                  // Inner glow circle
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

            // Text
            const Text(
              'ANALYZING',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 6.0,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'AI is identifying your product...',
              style: TextStyle(
                color: Colors.white.withAlpha(130),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 48),

            // Shimmer loading dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    final offset = i * 0.3;
                    final value = ((_pulseController.value + offset) % 1.0);
                    return Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryAmber.withAlpha(
                          (80 + value * 175).toInt(),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),

            const Spacer(flex: 3),

            // Tip text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'This usually takes a few seconds.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withAlpha(80),
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
          onTap: () => Navigator.of(context).pop(),
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
