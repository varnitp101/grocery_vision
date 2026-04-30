import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'login_error_screen.dart';
import 'login_success_screen.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  void _signup() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authControllerProvider).signUpWithEmail(
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

  void _googleSignup() async {
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF021220);
    const surfaceDark = Color(0xFF0A253A);
    const surfaceInput = Color(0xFF051828);
    const primaryAmber = Color(0xFFFFBF00);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Semantics(
                    button: true,
                    label: 'Go Back',
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.arrow_back, color: Colors.white70, size: 32),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.graphic_eq, color: primaryAmber, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'VOICE ACTIVE',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),


            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                        children: [
                          TextSpan(text: 'Sign ', style: TextStyle(color: Colors.white)),
                          TextSpan(text: 'Up', style: TextStyle(color: primaryAmber)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create an account to personalize your assistant.',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),


                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceDark,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white10),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildInputField(
                            label: 'FULL NAME',
                            icon: Icons.badge_outlined,
                            hint: 'John Doe',
                            controller: _nameController,
                            colorConfig: const {'surfaceInput': surfaceInput, 'primaryAmber': primaryAmber},
                          ),
                          const SizedBox(height: 16),
                          _buildInputField(
                            label: 'EMAIL',
                            icon: Icons.email_outlined,
                            hint: 'you@example.com',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            colorConfig: const {'surfaceInput': surfaceInput, 'primaryAmber': primaryAmber},
                          ),
                          const SizedBox(height: 16),
                          _buildInputField(
                            label: 'PASSWORD',
                            icon: Icons.lock_outline,
                            hint: '••••••••',
                            controller: _passwordController,
                            isSecure: _obscurePassword,
                            colorConfig: const {'surfaceInput': surfaceInput, 'primaryAmber': primaryAmber},
                            suffixIcon: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              child: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: primaryAmber, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Strong passwords ensure better clinical data security.',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),


            Container(
              padding: const EdgeInsets.all(24),
              color: bgColor,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAmber,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 10,
                        shadowColor: primaryAmber.withValues(alpha: 0.3),
                      ),
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.black) : const Text(
                        'CREATE ACCOUNT',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _googleSignup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.grey[100],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          Icon(Icons.g_mobiledata, color: Colors.black, size: 40),
                          SizedBox(width: 8),
                          Text(
                            'Sign in with Google',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
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
                        'Already have an account? ',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                        child: const Text(
                          'Log In',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: primaryAmber,
                            decorationThickness: 2,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required String hint,
    required TextEditingController controller,
    bool isSecure = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    required Map<String, Color> colorConfig,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: colorConfig['primaryAmber'], size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: colorConfig['primaryAmber'],
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isSecure,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white30),
            filled: true,
            fillColor: colorConfig['surfaceInput'],
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorConfig['primaryAmber']!, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
