import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/scanner_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/product_model.dart';
import 'product_result_screen.dart';
import 'scan_error_screen.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scannerControllerProvider.notifier).initializeCamera();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scannerState = ref.watch(scannerControllerProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (scannerState.isInitialized && scannerState.controller != null)
            CameraPreview(scannerState.controller!)
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          
          // Header: POINT AT PRODUCT
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
                child: const Text(
                  'POINT AT\nPRODUCT',
                  textAlign: TextAlign.center,
                  style: TextStyle(
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
          
          // Focus Box Overlay with UI
          Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: Stack(
                children: [
                  // Corner brackets
                  Align(alignment: Alignment.topLeft, child: _buildCorner(top: true, left: true)),
                  Align(alignment: Alignment.topRight, child: _buildCorner(top: true, left: false)),
                  Align(alignment: Alignment.bottomLeft, child: _buildCorner(top: false, left: true)),
                  Align(alignment: Alignment.bottomRight, child: _buildCorner(top: false, left: false)),
                  
                  // Scanning Line
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: double.infinity,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryAmber,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryAmber.withValues(alpha: 0.6),
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                    ),
                  ),

                  // Scanning Robot Circle
                  Align(
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: () {
                        // Mock Success Scan
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProductResultScreen(product: mockWholeMilk),
                          ),
                        );
                      },
                      onLongPress: () {
                        // Mock Failed Scan
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ScanErrorScreen(),
                          ),
                        );
                      },
                      child: Container(
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
                            Icon(Icons.smart_toy, color: AppTheme.primaryAmber, size: 40),
                            SizedBox(height: 8),
                            Text(
                              'SCANNING',
                              style: TextStyle(
                                color: AppTheme.primaryAmber,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Cancel Bottom Bar
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
          )
        ],
      ),
    );
  }

  Widget _buildCorner({required bool top, required bool left}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          top: top ? const BorderSide(color: AppTheme.primaryAmber, width: 6) : BorderSide.none,
          bottom: !top ? const BorderSide(color: AppTheme.primaryAmber, width: 6) : BorderSide.none,
          left: left ? const BorderSide(color: AppTheme.primaryAmber, width: 6) : BorderSide.none,
          right: !left ? const BorderSide(color: AppTheme.primaryAmber, width: 6) : BorderSide.none,
        ),
      ),
    );
  }
}
