import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'login_error_screen.dart';
import 'login_success_screen.dart';


class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authControllerProvider).signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginSuccessScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LoginErrorScreen()),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final user = await ref.read(authControllerProvider).signInWithGoogle();
      if (user != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginSuccessScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LoginErrorScreen()),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF020617);
    const surfaceNavColor = Color(0xFF0F172A);
    const accentNavColor = Color(0xFF1E293B);
    const primaryColor = Color(0xFFFFB300);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [

            Padding(
              padding: const EdgeInsets.only(top: 32, left: 32, right: 32, bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 40,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(color: primaryColor.withValues(alpha: 0.4), blurRadius: 15),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'LOGIN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.medical_services_outlined, color: primaryColor.withValues(alpha: 0.4), size: 36),
                ],
              ),
            ),


            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: surfaceNavColor,
                        border: Border.all(color: accentNavColor),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildModernInput(
                            label: 'EMAIL ADDRESS',
                            icon: Icons.alternate_email,
                            hint: 'name@clinic.com',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            surfaceNavColor: surfaceNavColor,
                            accentNavColor: accentNavColor,
                            primaryColor: primaryColor,
                            bgColor: bgColor,
                          ),
                          const SizedBox(height: 24),
                          _buildModernInput(
                            label: 'PASSWORD',
                            icon: Icons.lock_person_outlined,
                            hint: '••••••••',
                            controller: _passwordController,
                            isSecure: true,
                            surfaceNavColor: surfaceNavColor,
                            accentNavColor: accentNavColor,
                            primaryColor: primaryColor,
                            bgColor: bgColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                        );
                      },
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),


            Container(
              padding: const EdgeInsets.all(24).copyWith(bottom: 24 + MediaQuery.of(context).padding.bottom),
              decoration: const BoxDecoration(
                color: surfaceNavColor,
                border: Border(top: BorderSide(color: accentNavColor)),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 80,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'LOG IN',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.0,
                                ),
                              ),
                              SizedBox(width: 12),
                              Icon(Icons.login, color: Colors.black, size: 28),
                            ],
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 80,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _loginWithGoogle,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey.shade300, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.g_mobiledata, color: Colors.black, size: 48),
                          SizedBox(width: 12),
                          Text(
                            'Sign in with Google',
                            style: TextStyle(
                              color: Color(0xFF020617),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const SignupScreen()),
                          );
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFFFFB300),
                            decorationThickness: 2,
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernInput({
    required String label,
    required IconData icon,
    required String hint,
    required TextEditingController controller,
    bool isSecure = false,
    TextInputType keyboardType = TextInputType.text,
    required Color surfaceNavColor,
    required Color accentNavColor,
    required Color primaryColor,
    required Color bgColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              color: primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
        ),
        SizedBox(
          height: 80,
          child: TextField(
            controller: controller,
            obscureText: isSecure,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 20),
            decoration: InputDecoration(
              filled: true,
              fillColor: bgColor,
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white30),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 20, right: 12),
                child: Icon(icon, color: Colors.white54, size: 28),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: accentNavColor, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: accentNavColor, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
