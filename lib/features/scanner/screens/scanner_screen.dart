import 'package:flutter/material.dart';
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
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scannerControllerProvider.notifier).initializeCamera();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    final phase = ref.read(scannerControllerProvider).phase;
    if (phase == ScanPhase.idle) {
      ref.read(scannerControllerProvider.notifier).captureAndIdentify();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scannerState = ref.watch(scannerControllerProvider);

    // Listen for phase changes and navigate accordingly
    ref.listen<ScannerState>(scannerControllerProvider, (prev, next) {
      if (_hasNavigated) return;

      if (next.phase == ScanPhase.found && next.scannedProduct != null) {
        _hasNavigated = true;
        Navigator.of(context)
            .push(
          MaterialPageRoute(
            builder: (_) =>
                ProductResultScreen(product: next.scannedProduct!),
          ),
        )
            .then((_) {
          _hasNavigated = false;
          ref.read(scannerControllerProvider.notifier).resetToIdle();
        });
      } else if (next.phase == ScanPhase.notFound ||
          next.phase == ScanPhase.error) {
        _hasNavigated = true;
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          if (scannerState.isInitialized && scannerState.controller != null)
            CameraPreview(scannerState.controller!)
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Header status message
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 24,
            right: 24,
            child: Semantics(
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  scannerState.statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ),

          // Center scan area with focus box and button
          Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: Stack(
                children: [
                  // Corner brackets
                  Align(
                      alignment: Alignment.topLeft,
                      child: _buildCorner(top: true, left: true)),
                  Align(
                      alignment: Alignment.topRight,
                      child: _buildCorner(top: true, left: false)),
                  Align(
                      alignment: Alignment.bottomLeft,
                      child: _buildCorner(top: false, left: true)),
                  Align(
                      alignment: Alignment.bottomRight,
                      child: _buildCorner(top: false, left: false)),

                  // Scanning line
                  if (scannerState.phase == ScanPhase.idle)
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: double.infinity,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAmber,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppTheme.primaryAmber.withValues(alpha: 0.6),
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                      ),
                    ),

                  // Center circle button — changes based on phase
                  Align(
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onDoubleTap: _handleDoubleTap,
                      child: _buildScanButton(scannerState.phase),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Instruction text above the cancel bar
          if (scannerState.phase == ScanPhase.idle)
            Positioned(
              bottom: 100 + MediaQuery.of(context).padding.bottom + 16,
              left: 24,
              right: 24,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'DOUBLE TAP CENTER BUTTON TO SCAN',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),

          // Cancel bottom bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Semantics(
              button: true,
              label: 'Cancel scanning',
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  height: 100 + MediaQuery.of(context).padding.bottom,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryAmber,
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.close, color: AppTheme.darkNavy, size: 40),
                        SizedBox(width: 16),
                        Text(
                          'CANCEL',
                          style: TextStyle(
                            color: AppTheme.darkNavy,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanButton(ScanPhase phase) {
    switch (phase) {
      case ScanPhase.idle:
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppTheme.darkNavy.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryAmber, width: 2),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt_rounded,
                  color: AppTheme.primaryAmber, size: 40),
              SizedBox(height: 8),
              Text(
                'SCAN',
                style: TextStyle(
                  color: AppTheme.primaryAmber,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        );

      case ScanPhase.capturing:
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: const Center(
            child: Icon(Icons.flash_on_rounded, color: Colors.white, size: 48),
          ),
        );

      case ScanPhase.analyzing:
        return AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.9 + (_pulseController.value * 0.2),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.primaryAmber.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primaryAmber
                        .withValues(alpha: 0.5 + _pulseController.value * 0.5),
                    width: 3,
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome,
                        color: AppTheme.primaryAmber, size: 36),
                    SizedBox(height: 6),
                    Text(
                      'AI',
                      style: TextStyle(
                        color: AppTheme.primaryAmber,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );

      case ScanPhase.found:
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.greenAccent, width: 3),
          ),
          child: const Center(
            child: Icon(Icons.check_rounded, color: Colors.greenAccent, size: 56),
          ),
        );

      case ScanPhase.notFound:
      case ScanPhase.error:
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.redAccent, width: 3),
          ),
          child: const Center(
            child: Icon(Icons.close_rounded, color: Colors.redAccent, size: 56),
          ),
        );
    }
  }

  Widget _buildCorner({required bool top, required bool left}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          top: top
              ? const BorderSide(color: AppTheme.primaryAmber, width: 6)
              : BorderSide.none,
          bottom: !top
              ? const BorderSide(color: AppTheme.primaryAmber, width: 6)
              : BorderSide.none,
          left: left
              ? const BorderSide(color: AppTheme.primaryAmber, width: 6)
              : BorderSide.none,
          right: !left
              ? const BorderSide(color: AppTheme.primaryAmber, width: 6)
              : BorderSide.none,
        ),
      ),
    );
  }
}
