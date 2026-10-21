import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../scanner/screens/scanner_screen.dart';
import '../providers/mall_provider.dart';
import '../widgets/mall_selector_gate_view.dart';
import 'dashboard_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mallState = ref.watch(mallProvider);

    // Step 1: If user hasn't selected their mall yet, show the Mall Selector first!
    if (!mallState.isMallConfirmed) {
      return const MallSelectorGateView();
    }

    // Step 2: After selecting mall, show the current home screen!
    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = user?.photoURL;
    final displayName = user?.displayName ?? 'User';
    final initials = displayName.isNotEmpty
        ? displayName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: AppTheme.darkNavy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Store Status Chip with Change Button
              GestureDetector(
                onTap: () {
                  ref.read(mallProvider.notifier).resetMallSelection();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F2042),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryAmber.withAlpha(140),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(40),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.storefront_rounded,
                        color: AppTheme.primaryAmber,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'MALL: ${mallState.displayName.toUpperCase()}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAmber.withAlpha(35),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.primaryAmber.withAlpha(100)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'CHANGE',
                              style: TextStyle(
                                color: AppTheme.primaryAmber,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(Icons.sync_rounded, color: AppTheme.primaryAmber, size: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // System Ready Status & Profile
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryAmber,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'SYSTEM READY',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),

                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const DashboardScreen(initialIndex: 3)),
                      );
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primaryAmber.withAlpha(80), width: 2),
                      ),
                      child: ClipOval(
                        child: photoUrl != null && photoUrl.isNotEmpty
                            ? Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, e, s) => Center(
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      color: AppTheme.primaryAmber,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    color: AppTheme.primaryAmber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tap to Scan Button
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ScannerScreen()),
                    );
                  },
                  child: Semantics(
                    label: 'Start scanning. Tap to open camera.',
                    button: true,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryAmber,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryAmber.withValues(alpha: 0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildBlackIconBlock(Icons.auto_awesome),
                              const SizedBox(width: 14),
                              _buildBlackIconBlock(Icons.camera_alt, isLarge: true),
                              const SizedBox(width: 14),
                              _buildBlackIconBlock(Icons.search_rounded),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'TAP TO\nSCAN\nPRODUCT',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.darkNavy,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'AI POWERED',
                            style: TextStyle(
                              color: AppTheme.darkNavy,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 3.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 30,
                            height: 3,
                            color: AppTheme.darkNavy,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Bottom Row: My Cart and History
              Expanded(
                flex: 1,
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        label: 'Go to Cart',
                        button: true,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const DashboardScreen(initialIndex: 2)),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F2042),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_cart,
                                  color: AppTheme.primaryAmber,
                                  size: 28,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'My Cart',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Semantics(
                        label: 'Go to History',
                        button: true,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const DashboardScreen(initialIndex: 1)),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F2042),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history_rounded,
                                  color: AppTheme.primaryAmber,
                                  size: 28,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'History',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlackIconBlock(IconData icon, {bool isLarge = false}) {
    final double size = isLarge ? 80 : 64;
    final double iconSize = isLarge ? 40 : 32;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.darkNavy,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isLarge
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ]
            : null,
      ),
      child: Icon(
        icon,
        color: AppTheme.primaryAmber,
        size: iconSize,
      ),
    );
  }
}
