import 'package:flutter/material.dart';

class LoginErrorScreen extends StatelessWidget {
  final String title;
  final String? errorMessage;

  const LoginErrorScreen({
    super.key,
    this.title = 'INVALID\nLOGIN',
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF5A0C1E);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),

            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 340),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 6),
                      boxShadow: const [
                        BoxShadow(color: Colors.black54, blurRadius: 10),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.gpp_maybe, color: Colors.white, size: 72),
                        const SizedBox(height: 32),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            height: 0.95,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          errorMessage ?? 'Check your email and password and try again.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),


            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Semantics(
                button: true,
                label: 'Try Again',
                child: SizedBox(
                  width: double.infinity,
                  height: 88,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: bgColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 10,
                    ),
                    child: const Text(
                      'TRY AGAIN',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
