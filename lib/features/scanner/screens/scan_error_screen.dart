import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ScanErrorScreen extends StatefulWidget {
  const ScanErrorScreen({super.key});

  @override
  State<ScanErrorScreen> createState() => _ScanErrorScreenState();
}

class _ScanErrorScreenState extends State<ScanErrorScreen> {
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _announceError();
  }

  Future<void> _announceError() async {
    await _tts.speak('Item not found. Please move the phone closer and double-tap to try again.');
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const errorClinical = Color(0xFFB00020);

    return Scaffold(
      backgroundColor: errorClinical,
      body: SafeArea(
        child: Column(
          children: [
            // Top Half: Status Indicator
            Expanded(
              flex: 55, // Takes ~55% height
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const Icon(
                          Icons.search_off_rounded,
                          color: Colors.white,
                          size: 84,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'ITEM\nNOT FOUND',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Please move the phone closer to the product.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Half: Giant Touch Target (45% height)
            Expanded(
              flex: 45,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16).copyWith(bottom: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withAlpha(50),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Semantics(
                  label: 'Retry Scan. Double tap to try again.',
                  button: true,
                  child: ElevatedButton(
                    onPressed: () {
                      _tts.stop();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: errorClinical,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      elevation: 10,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.refresh_rounded, size: 56, color: errorClinical),
                        const SizedBox(height: 8),
                        const Text(
                          'RETRY',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'DOUBLE TAP SCREEN',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: errorClinical.withAlpha(150),
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
    );
  }
}
