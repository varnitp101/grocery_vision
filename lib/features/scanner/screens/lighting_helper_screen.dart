import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class LightingHelperScreen extends StatefulWidget {
  const LightingHelperScreen({super.key});

  @override
  State<LightingHelperScreen> createState() => _LightingHelperScreenState();
}

class _LightingHelperScreenState extends State<LightingHelperScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1B1D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // TOP BLOCK: LIGHTING
              Expanded(
                child: Semantics(
                  label: 'Warning: Lighting too low. Lumens at 12 percent.',
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Decorative Ruler Left
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: Opacity(
                            opacity: 0.2,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(6, (index) => Container(
                                width: index % 2 == 0 ? 8 : 16,
                                height: 1,
                                color: Colors.white,
                                margin: const EdgeInsets.only(left: 8),
                              )),
                            ),
                          ),
                        ),
                        
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                children: [
                                  const Icon(Icons.wb_sunny_outlined, color: Colors.white, size: 72),
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryAmber,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(color: AppTheme.primaryAmber.withValues(alpha: 0.8), blurRadius: 10),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'LIGHTING STATUS',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 3.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'TOO DARK',
                                style: TextStyle(
                                  color: AppTheme.primaryAmber,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('LUM: 12%', style: TextStyle(color: Colors.white60, fontSize: 12, fontFamily: 'monospace')),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 64,
                                      height: 4,
                                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          width: 64 * 0.12,
                                          height: 4,
                                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(2)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // CENTRAL FOCAL POINT (The "Hinge")
              SizedBox(
                height: 120,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(width: 2, height: 120, color: Colors.white10),
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.primaryAmber.withValues(alpha: 0.2), width: 1),
                          ),
                        ),
                      ),
                      ScaleTransition(
                        scale: Tween<double>(begin: 1.0, end: 1.1).animate(_pulseController),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B1B1D),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.primaryAmber, width: 4),
                            boxShadow: [
                              BoxShadow(color: AppTheme.primaryAmber.withValues(alpha: 0.5), blurRadius: 20),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryAmber,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // BOTTOM BLOCK: POSITION
              Expanded(
                child: Semantics(
                  label: 'Distance: Move Phone Back plus 6 inches.',
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Decorative Ruler Right
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: Opacity(
                            opacity: 0.2,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(6, (index) => Container(
                                width: index % 2 == 0 ? 8 : 16,
                                height: 1,
                                color: Colors.white,
                                margin: const EdgeInsets.only(right: 8),
                              )),
                            ),
                          ),
                        ),
                        
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Note: SVG rotation equivalent for a material icon representing a phone or straightness
                              const Icon(Icons.straighten, color: Colors.white, size: 72),
                              const SizedBox(height: 16),
                              const Text(
                                'DISTANCE',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 3.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              RichText(
                                textAlign: TextAlign.center,
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    height: 1.1,
                                  ),
                                  children: [
                                    TextSpan(text: 'MOVE PHONE\n', style: TextStyle(color: Colors.white)),
                                    TextSpan(text: 'BACK', style: TextStyle(color: AppTheme.primaryAmber)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.arrow_downward, color: AppTheme.primaryAmber, size: 20),
                                  const SizedBox(width: 8),
                                  const Text('+ 6 inches', style: TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'monospace')),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // FOOTER CANCEL
              Semantics(
                button: true,
                label: 'Cancel scan and close helper',
                child: SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: AppTheme.primaryAmber,
                      side: BorderSide(color: AppTheme.primaryAmber.withValues(alpha: 0.5), width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.close, size: 28),
                        SizedBox(width: 12),
                        Text(
                          'CANCEL SCAN',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
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
    );
  }
}
