import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/mall_catalog_item.dart';
import '../../../models/product_model.dart';
import '../../../services/haptic_service.dart';
import '../../../services/mall_catalog_service.dart';
import '../../../services/tts_service.dart';
import '../../cart/providers/cart_provider.dart';
import '../../dashboard/providers/mall_provider.dart';
import 'product_result_screen.dart';

class SimilarProductsScreen extends ConsumerStatefulWidget {
  final Product? scannedProduct;

  const SimilarProductsScreen({
    super.key,
    this.scannedProduct,
  });

  @override
  ConsumerState<SimilarProductsScreen> createState() => _SimilarProductsScreenState();
}

class _SimilarProductsScreenState extends ConsumerState<SimilarProductsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _announceSuggestions();
      }
    });
  }

  String get _currentMall {
    return ref.read(mallProvider).displayName;
  }

  String _getEffectiveCategory(MallCatalogService catalogService) {
    if (widget.scannedProduct != null) {
      return catalogService.detectCategory(widget.scannedProduct!);
    }
    return 'Tea & Beverages';
  }

  Future<void> _announceSuggestions() async {
    if (!mounted) return;
    final catalogService = ref.read(mallCatalogServiceProvider);
    final activeMall = _currentMall;
    final category = _getEffectiveCategory(catalogService);
    final items = catalogService.getSimilarProducts(
      scannedProduct: widget.scannedProduct,
      categoryFilter: category,
      mallName: activeMall,
    );

    if (items.isEmpty) {
      final speech = widget.scannedProduct != null
          ? 'No other $category found in $activeMall for ${widget.scannedProduct!.name}.'
          : 'No $category found in $activeMall.';
      if (!mounted) return;
      await ref.read(ttsServiceProvider).speak(speech, priority: TtsPriority.immediate);
      return;
    }

    String speech = widget.scannedProduct != null
        ? 'Similar $category found in $activeMall for ${widget.scannedProduct!.name}. '
        : 'Showing $category available in $activeMall. ';
    speech += 'Found ${items.length} options inside $activeMall. ';

    if (items.isNotEmpty) {
      final top3 = items.take(3).map((item) {
        final price = item.formattedPriceForMall(activeMall);
        return '${item.name}, $price, ${item.weight}';
      }).join('; ');
      speech += 'Top options include: $top3. Tap any product to view details, or tap add to cart.';
    }

    if (!mounted) return;
    await ref.read(ttsServiceProvider).speak(speech, priority: TtsPriority.immediate);
  }

  @override
  void dispose() {
    try {
      ref.read(ttsServiceProvider).stop();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bgNavy = Color(0xFF0A192F);
    const surfaceNavy = Color(0xFF112240);
    const cardNavy = Color(0xFF1B2A4A);
    const primaryAmber = Color(0xFFFFBF00);

    final catalogService = ref.watch(mallCatalogServiceProvider);
    final activeMall = _currentMall;
    final category = _getEffectiveCategory(catalogService);
    final items = catalogService.getSimilarProducts(
      scannedProduct: widget.scannedProduct,
      categoryFilter: category,
      mallName: activeMall,
    );
    final scannedPrice = widget.scannedProduct != null
        ? catalogService.getPriceForProductInMall(widget.scannedProduct!, activeMall)
        : '';

    return Scaffold(
      backgroundColor: bgNavy,
      appBar: AppBar(
        backgroundColor: surfaceNavy,
        elevation: 0,
        leading: Semantics(
          label: 'Back to product result',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 26),
            onPressed: () {
              ref.read(ttsServiceProvider).stop();
              Navigator.of(context).pop();
            },
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SIMILAR $category'.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            Text(
              'Inside $activeMall',
              style: const TextStyle(
                color: primaryAmber,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Semantics(
            label: 'Read similar products out loud',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.volume_up_rounded, color: primaryAmber, size: 26),
              onPressed: _announceSuggestions,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Scanned product reference banner
            if (widget.scannedProduct != null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: surfaceNavy,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryAmber.withAlpha(90)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(60),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: primaryAmber.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primaryAmber.withAlpha(150)),
                      ),
                      child: const Icon(
                        Icons.qr_code_2_rounded,
                        color: primaryAmber,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primaryAmber,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'SCANNED ITEM',
                                  style: TextStyle(
                                    color: bgNavy,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  category.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.scannedProduct!.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Price in $activeMall: $scannedPrice',
                            style: TextStyle(
                              color: primaryAmber.withAlpha(220),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Section Header: Other products in this specific category & mall
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'OTHER ${category.toUpperCase()} IN ${activeMall.toUpperCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryAmber.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: primaryAmber.withAlpha(80)),
                    ),
                    child: Text(
                      '${items.length} OPTIONS',
                      style: const TextStyle(
                        color: primaryAmber,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Products List (strictly in the scanned product's category & mall)
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Colors.white.withAlpha(80),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No other $category found in $activeMall',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _SimilarProductCard(
                          item: item,
                          activeMall: activeMall,
                          cardBg: cardNavy,
                          primaryAmber: primaryAmber,
                          onOpenDetails: () {
                            ref.read(ttsServiceProvider).stop();
                            final prod = item.toProduct(activeMall: activeMall);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProductResultScreen(product: prod),
                              ),
                            );
                          },
                          onAddToCart: () {
                            final prod = item.toProduct(activeMall: activeMall);
                            ref.read(cartProvider.notifier).addProduct(prod);
                            ref.read(hapticServiceProvider).detectionStable();
                            ref.read(ttsServiceProvider).speak(
                                  'Added ${item.name} to cart.',
                                  priority: TtsPriority.immediate,
                                );

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF0F382A),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: Colors.greenAccent),
                                ),
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded,
                                        color: Colors.greenAccent),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Added ${item.name} to Cart (${item.formattedPriceForMall(activeMall)})',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
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

class _SimilarProductCard extends StatelessWidget {
  final MallCatalogItem item;
  final String activeMall;
  final Color cardBg;
  final Color primaryAmber;
  final VoidCallback onOpenDetails;
  final VoidCallback onAddToCart;

  const _SimilarProductCard({
    required this.item,
    required this.activeMall,
    required this.cardBg,
    required this.primaryAmber,
    required this.onOpenDetails,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final mallPrice = item.priceForMall(activeMall);
    final savings = item.savingsForMall(activeMall);
    final savingsPercent = item.savingsPercentForMall(activeMall);

    final semanticDescription =
        '${item.name}, brand ${item.brand}, weight ${item.weight}. '
        'Price at $activeMall is ₹${mallPrice.toStringAsFixed(0)}. '
        'MRP ₹${item.mrp.toStringAsFixed(0)}. '
        '${savings > 0 ? "You save ₹${savings.toStringAsFixed(0)}." : ""} '
        'Double tap to view full product details, or double tap add to cart button.';

    return Semantics(
      label: semanticDescription,
      container: true,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withAlpha(25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(45),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onOpenDetails,
            borderRadius: BorderRadius.circular(18),
            splashColor: primaryAmber.withAlpha(30),
            highlightColor: Colors.white.withAlpha(15),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand, Size & Details Pill Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.brand.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.cyan.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.cyan.withAlpha(80)),
                        ),
                        child: Text(
                          item.weight,
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Clickable Details indicator chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: primaryAmber.withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: primaryAmber.withAlpha(120)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'DETAILS',
                              style: TextStyle(
                                color: primaryAmber,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(Icons.chevron_right_rounded, size: 14, color: primaryAmber),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Product Name
                  Text(
                    item.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Price & Savings Row (Inside this mall only)
                  Row(
                    children: [
                      // Mall Price Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryAmber.withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: primaryAmber.withAlpha(150)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.formattedPriceForMall(activeMall),
                              style: TextStyle(
                                color: primaryAmber,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'at $activeMall',
                              style: TextStyle(
                                color: primaryAmber.withAlpha(200),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // MRP strike-through
                      if (item.mrp > mallPrice) ...[
                        Text(
                          item.formattedMrp,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 15,
                            decoration: TextDecoration.lineThrough,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.greenAccent.withAlpha(120)),
                          ),
                          child: Text(
                            'SAVE ${item.formattedSavingsForMall(activeMall)} ($savingsPercent%)',
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Dual Action Buttons: Details and Add to Cart
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Semantics(
                          label: 'View details for ${item.name}',
                          button: true,
                          child: OutlinedButton.icon(
                            onPressed: onOpenDetails,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withAlpha(70),
                                width: 1.2,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.info_outline_rounded, size: 18),
                            label: const Text(
                              'DETAILS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 5,
                        child: Semantics(
                          label: 'Add ${item.name} to cart for ${item.formattedPriceForMall(activeMall)}',
                          button: true,
                          child: ElevatedButton.icon(
                            onPressed: onAddToCart,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryAmber,
                              foregroundColor: const Color(0xFF0A192F),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'ADD TO CART',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
