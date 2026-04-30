import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ScanErrorScreen extends StatefulWidget {
  const ScanErrorScreen({super.key});

  @override
  State<ScanErrorScreen> createState() => _ScanErrorScreenState();
}

class _ScanErrorScreenState extends State<ScanErrorScreen>
    with SingleTickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  late AnimationController _breatheController;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _announceError();
  }

  Future<void> _announceError() async {
    await _tts.speak('Product not recognized. Tap Retry to go back and try again.');
  }

  @override
  void dispose() {
    _tts.stop();
    _breatheController.dispose();
    super.dispose();
  }

  void _retry() {
    HapticFeedback.mediumImpact();
    _tts.stop();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    const errorColor = Color(0xFFB00020);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1C),
      body: SafeArea(
        child: Column(
          children: [

            Expanded(
              flex: 55,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _breatheController,
                      builder: (context, _) {
                        return Container(
                          width: 120 + (_breatheController.value * 12),
                          height: 120 + (_breatheController.value * 12),
                          decoration: BoxDecoration(
                            color: errorColor.withAlpha(30),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: errorColor.withAlpha(
                                100 + (_breatheController.value * 80).toInt(),
                              ),
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.search_off_rounded,
                            color: Colors.white,
                            size: 64,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'NOT\nRECOGNIZED',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Try holding the product closer\nwith the label facing the camera.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withAlpha(180),
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),


            Expanded(
              flex: 45,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Expanded(
                      child: SizedBox(
                        width: double.infinity,
                        child: Semantics(
                          label: 'Retry scan',
                          button: true,
                          child: ElevatedButton(
                            onPressed: _retry,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: errorColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              elevation: 10,
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.refresh_rounded, size: 48),
                                SizedBox(height: 8),
                                Text(
                                  'RETRY',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 3.0,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'TAP TO GO BACK',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
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
            ),
          ],
        ),
      ),
    );
  }
}
