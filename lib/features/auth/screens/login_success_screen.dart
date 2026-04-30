import 'package:flutter/material.dart';
import '../../dashboard/screens/dashboard_screen.dart';

class LoginSuccessScreen extends StatelessWidget {
  const LoginSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF0A0A0A);
    const primaryColor = Color(0xFFFFA200);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryColor, width: 6),
                        boxShadow: [
                          BoxShadow(color: primaryColor.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 5),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.check, color: Colors.white, size: 64),
                      ),
                    ),
                    const SizedBox(height: 48),


                    const Text(
                      'LOGIN\nSUCCESSFUL',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Welcome back to\nGrocery Eye.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),


            Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: 24 + MediaQuery.of(context).padding.bottom
              ),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: Semantics(
                button: true,
                label: 'Enter App',
                child: SizedBox(
                  width: double.infinity,
                  height: 112,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const DashboardScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 10,
                      shadowColor: primaryColor.withValues(alpha: 0.3),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'ENTER APP',
                          style: TextStyle(
                            color: bgColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                        ),
                        SizedBox(width: 12),
                        Icon(Icons.arrow_forward, color: bgColor, size: 32),
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
