import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/theme/app_theme.dart';
import 'permissions_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final FlutterTts _flutterTts = FlutterTts();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  void _navigateToPermissions() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const PermissionsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0); // Start from bottom
          const end = Offset.zero;
          const curve = Curves.easeInOutBack;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToPermissions();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipOnboarding() {
    _navigateToPermissions();
  }

  void _simulateHaptics() async {
    // Speak custom audio
    await _flutterTts.setSpeechRate(0.5);
    _flutterTts.speak("Hey there");
    
    // Generate an escalating vibration pattern as a simulation
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 200));
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 200));
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    // Forced dark mode matching requested UI
    return Scaffold(
      backgroundColor: AppTheme.darkNavy.withValues(alpha: 0.95), // very dark background
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header / Progress
            Padding(
              padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildProgressIndicator(0),
                      const SizedBox(width: 8),
                      _buildProgressIndicator(1),
                      const SizedBox(width: 8),
                      _buildProgressIndicator(2),
                    ],
                  ),
                  Text(
                    'STEP ${_currentPage + 1}/3',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  )
                ],
              ),
            ),

            // Page View Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Only navigate with buttons
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                  if (index == 1) {
                    _simulateHaptics();
                  }
                },
                children: [
                  _buildPage1(),
                  _buildPage2(),
                  _buildPage3(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(int pageIndex) {
    final bool isActive = _currentPage == pageIndex;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 8,
      width: isActive ? 64 : 32,
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryAmber : Colors.white24,
        borderRadius: BorderRadius.circular(4),
        boxShadow: isActive
            ? [BoxShadow(color: AppTheme.primaryAmber.withValues(alpha: 0.5), blurRadius: 10)]
            : [],
      ),
    );
  }

  // --- PAGE 1: AI Vision Assistant ---
  Widget _buildPage1() {
    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Semantics(
                label: 'AI Vision Assistant. This app helps you identify groceries using your camera.',
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAmber.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: Colors.white10, width: 6),
                        ),
                        child: const Center(
                          child: Icon(Icons.remove_red_eye_outlined, size: 120, color: AppTheme.primaryAmber),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
              const Text(
                'AI Vision\nAssistant',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'This app helps you identify\ngroceries using your camera.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        _buildFooterSplitButtons(
          leftIcon: Icons.fast_forward,
          leftText: 'SKIP',
          onLeftTab: _skipOnboarding,
          rightIcon: Icons.arrow_forward,
          rightText: 'NEXT',
          onRightTap: _nextPage,
        )
      ],
    );
  }

  // --- PAGE 2: Audio & Haptics ---
  Widget _buildPage2() {
    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Semantics(
                label: 'Audio & Haptics. We use distinct sounds and vibrations to guide your hand.',
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white10, width: 4),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.smartphone, size: 100, color: Colors.white),
                      const Positioned(
                        right: -10,
                        bottom: -10,
                        child: CircleAvatar(
                          backgroundColor: AppTheme.primaryAmber,
                          radius: 28,
                          child: Icon(Icons.volume_up, color: Colors.black, size: 32),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                  children: [
                    TextSpan(text: 'Audio &\n', style: TextStyle(color: Colors.white)),
                    TextSpan(text: 'Haptics', style: TextStyle(color: AppTheme.primaryAmber)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'We use distinct sounds and vibrations to guide your hand to the right product on the shelf.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildFooterSplitButtons(
          leftIcon: Icons.arrow_back,
          leftText: 'BACK',
          onLeftTab: _previousPage,
          rightIcon: Icons.arrow_forward,
          rightText: 'NEXT',
          onRightTap: _nextPage,
        )
      ],
    );
  }

  // --- PAGE 3: Offline Mode ---
  Widget _buildPage3() {
    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Semantics(
                label: 'Offline Mode. Your lists are saved locally.',
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFF162032),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white10),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.cloud_off, size: 100, color: AppTheme.primaryAmber),
                      Positioned(
                        top: 24,
                        right: 24,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.red.withValues(alpha: 0.6), blurRadius: 10),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
              const Text(
                'Offline Mode',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your lists are saved locally.\nNo signal required.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.25,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _navigateToPermissions,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAmber,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'GET STARTED',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
                SizedBox(height: 8),
                Icon(Icons.keyboard_arrow_down, color: Colors.black, size: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterSplitButtons({
    required IconData leftIcon,
    required String leftText,
    required VoidCallback onLeftTab,
    required IconData rightIcon,
    required String rightText,
    required VoidCallback onRightTap,
  }) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.25,
      child: Row(
        children: [
          // Left Button
          Expanded(
            child: Semantics(
              button: true,
              label: leftText,
              child: GestureDetector(
                onTap: onLeftTab,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF121212),
                    border: Border(top: BorderSide(color: Colors.white10, width: 4)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.darkNavy,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 2),
                        ),
                        child: Icon(leftIcon, color: Colors.white54, size: 36),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        leftText,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(width: 4, color: Colors.black), // Divider
          // Right Button
          Expanded(
            child: Semantics(
              button: true,
              label: rightText,
              child: GestureDetector(
                onTap: onRightTap,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryAmber,
                    border: Border(top: BorderSide(color: Colors.black, width: 4)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black26, width: 4),
                        ),
                        child: Icon(rightIcon, color: Colors.black, size: 36),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        rightText,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
