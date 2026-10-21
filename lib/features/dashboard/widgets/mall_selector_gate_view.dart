import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/haptic_service.dart';
import '../../../services/tts_service.dart';
import '../providers/mall_provider.dart';

class MallSelectorGateView extends ConsumerStatefulWidget {
  const MallSelectorGateView({super.key});

  @override
  ConsumerState<MallSelectorGateView> createState() => _MallSelectorGateViewState();
}

class _MallSelectorGateViewState extends ConsumerState<MallSelectorGateView> {
  final TextEditingController _customStoreController = TextEditingController();
  bool _showCustomInput = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ttsServiceProvider).speak(
            'Select your mall: DMart, Reliance Smart Bazaar, or Others to continue.',
            priority: TtsPriority.immediate,
          );
    });
  }

  @override
  void dispose() {
    _customStoreController.dispose();
    super.dispose();
  }

  void _onMallChosen(String mallName) {
    ref.read(hapticServiceProvider).productFound();
    ref.read(mallProvider.notifier).confirmMall(mallName);
    ref.read(ttsServiceProvider).speak(
          'Selected $mallName. Opening home screen.',
          priority: TtsPriority.immediate,
        );
  }

  void _onCustomMallConfirmed() {
    final customName = _customStoreController.text.trim();
    if (customName.isEmpty) return;
    ref.read(hapticServiceProvider).productFound();
    ref.read(mallProvider.notifier).confirmCustomMall(customName);
    ref.read(ttsServiceProvider).speak(
          'Selected $customName. Opening home screen.',
          priority: TtsPriority.immediate,
        );
  }

  @override
  Widget build(BuildContext context) {
    final mallState = ref.watch(mallProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkNavy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Brand Tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryAmber,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'GROCERY VISION',
                        style: TextStyle(
                          color: AppTheme.primaryAmber,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.5,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'STEP 1 OF 1',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Title Header
              const Text(
                'SELECT YOUR MALL',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose where you are shopping today to calibrate scanning and product details.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // Mall Option Cards
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Option 1: DMart
                    _buildMallCard(
                      name: 'DMart',
                      tagline: 'Everyday Low Prices & Bulk Grocery',
                      icon: Icons.shopping_basket_rounded,
                      badgeText: 'POPULAR',
                      onTap: () => _onMallChosen('DMart'),
                    ),
                    const SizedBox(height: 16),

                    // Option 2: Reliance Smart Bazaar
                    _buildMallCard(
                      name: 'Reliance Smart Bazaar',
                      tagline: 'Big Savings on Daily Essentials',
                      icon: Icons.shopping_bag_rounded,
                      badgeText: 'FEATURED',
                      onTap: () => _onMallChosen('Reliance Smart Bazaar'),
                    ),
                    const SizedBox(height: 16),

                    // Option 3: Others
                    _buildMallCard(
                      name: 'Others',
                      tagline: 'Local Kirana, Spencer\'s, Nature\'s Basket, etc.',
                      icon: Icons.storefront_rounded,
                      isOthers: true,
                      onTap: () {
                        setState(() {
                          _showCustomInput = !_showCustomInput;
                        });
                        ref.read(hapticServiceProvider).detectionStable();
                        if (_showCustomInput) {
                          ref.read(ttsServiceProvider).speak(
                                'Type your custom store name and tap confirm.',
                                priority: TtsPriority.immediate,
                              );
                        }
                      },
                    ),

                    // Custom Store Input Field
                    if (_showCustomInput) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F2042),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primaryAmber,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'STORE / SUPERMARKET NAME',
                              style: TextStyle(
                                color: AppTheme.primaryAmber,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _customStoreController,
                              autofocus: true,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                hintText: 'e.g. Spencer\'s, Nature\'s Basket, Kirana',
                                hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                                filled: true,
                                fillColor: AppTheme.darkNavy,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Colors.white.withAlpha(40)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: AppTheme.primaryAmber, width: 2),
                                ),
                              ),
                              onSubmitted: (_) => _onCustomMallConfirmed(),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton(
                              onPressed: _onCustomMallConfirmed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryAmber,
                                foregroundColor: AppTheme.darkNavy,
                                minimumSize: const Size(double.infinity, 52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'CONFIRM & CONTINUE',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Bottom note
              Center(
                child: Text(
                  'Current selection: ${mallState.displayName}',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMallCard({
    required String name,
    required String tagline,
    required IconData icon,
    String? badgeText,
    bool isOthers = false,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: 'Select $name. $tagline',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFF0F2042),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.primaryAmber.withAlpha(140),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(50),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primaryAmber,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.darkNavy,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),

              // Texts
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (badgeText != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAmber.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.primaryAmber.withAlpha(90)),
                        ),
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                            color: AppTheme.primaryAmber,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tagline,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              // Trailing arrow
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOthers ? Icons.edit_note_rounded : Icons.arrow_forward_rounded,
                  color: AppTheme.primaryAmber,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
