import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../scanner/screens/product_details_screen.dart';
import '../providers/history_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                border: Border(bottom: BorderSide(color: Colors.white.withAlpha(18))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Scan\nHistory',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.15,
                      letterSpacing: -0.5,
                    ),
                  ),
                  // Refresh button
                  GestureDetector(
                    onTap: () => ref.invalidate(historyProvider),
                    child: Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(8),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withAlpha(40)),
                      ),
                      child: const Icon(Icons.refresh_rounded, color: AppTheme.primaryAmber, size: 24),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: historyAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryAmber),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded, color: Colors.redAccent.withAlpha(200), size: 64),
                      const SizedBox(height: 16),
                      const Text(
                        'Failed to load history',
                        style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => ref.invalidate(historyProvider),
                        child: const Text('Retry', style: TextStyle(color: AppTheme.primaryAmber)),
                      ),
                    ],
                  ),
                ),
                data: (entries) {
                  if (entries.isEmpty) {
                    return _EmptyHistoryView();
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(historyProvider);
                      // Wait briefly for the provider to start fetching
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    color: AppTheme.primaryAmber,
                    backgroundColor: const Color(0xFF1A1A1A),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return _HistoryCard(entry: entry);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistoryView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryAmber.withAlpha(15),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryAmber.withAlpha(40), width: 2),
              ),
              child: Icon(
                Icons.history_rounded,
                size: 56,
                color: AppTheme.primaryAmber.withAlpha(128),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Scans Yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your scanned products will\nappear here',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withAlpha(120),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final HistoryEntry entry;
  const _HistoryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final product = entry.product;
    final timeStr = _formatTime(entry.scannedAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProductDetailsScreen(product: product),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(12)),
            ),
            child: Row(
              children: [
                // Product Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryAmber.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryAmber.withAlpha(40)),
                  ),
                  child: Icon(
                    _categoryIcon(product.category),
                    color: AppTheme.primaryAmber,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            product.brand,
                            style: TextStyle(
                              color: Colors.white.withAlpha(128),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(60),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryAmber.withAlpha(20),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              product.category,
                              style: const TextStyle(
                                color: AppTheme.primaryAmber,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: Colors.white.withAlpha(80),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withAlpha(50),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return 'Just now';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  IconData _categoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('dairy') || cat.contains('milk')) return Icons.water_drop_rounded;
    if (cat.contains('snack') || cat.contains('chip')) return Icons.cookie_rounded;
    if (cat.contains('beverage') || cat.contains('drink')) return Icons.local_drink_rounded;
    if (cat.contains('fruit') || cat.contains('vegetable')) return Icons.eco_rounded;
    if (cat.contains('meat') || cat.contains('poultry')) return Icons.lunch_dining_rounded;
    if (cat.contains('bread') || cat.contains('bakery')) return Icons.bakery_dining_rounded;
    if (cat.contains('frozen')) return Icons.ac_unit_rounded;
    if (cat.contains('sauce') || cat.contains('condiment')) return Icons.water_drop_outlined;
    return Icons.inventory_2_rounded;
  }
}
