import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/product_model.dart';
import '../../../services/mall_catalog_service.dart';
import '../../../services/tts_service.dart';
import '../../dashboard/providers/mall_provider.dart';
import 'similar_products_screen.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final Product product;
  final Uint8List? capturedImage;

  const ProductDetailsScreen({
    super.key,
    required this.product,
    this.capturedImage,
  });

  @override
  ConsumerState<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  final TtsService _tts = TtsService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _announceDetails();
      }
    });
  }

  Future<void> _announceDetails() async {
    if (!mounted) return;
    final activeMall = ref.read(mallProvider).displayName;
    final catalogService = ref.read(mallCatalogServiceProvider);
    final category = catalogService.detectCategory(widget.product);
    final similarCount = catalogService.getSimilarProductsCount(
      widget.product,
      categoryFilter: category,
      mallName: activeMall,
    );
    final mallPrice = catalogService.getPriceForProductInMall(widget.product, activeMall);
    final String priceText = mallPrice.isNotEmpty ? 'Price in $activeMall: $mallPrice. ' : '';

    final String announcement = 'Detailed Product View for ${widget.product.name}. $priceText'
        '${widget.product.honestTake != null ? "Product Overview: ${widget.product.honestTake}. " : ""}'
        '${widget.product.shelfLife != null ? "Shelf life: ${widget.product.shelfLife}. " : ""}'
        '${widget.product.usageInstructions != null ? "Usage: ${widget.product.usageInstructions}. " : ""}'
        '${widget.product.isFood && widget.product.allergens.isNotEmpty ? "Contains allergens: ${widget.product.allergens.join(', ')}. " : ""}'
        '${widget.product.isFood ? "Ingredients: ${widget.product.ingredients}." : ""}'
        'Explore $similarCount other $category inside $activeMall using the similar products button.';
    if (!mounted) return;
    await _tts.speak(announcement, priority: TtsPriority.immediate);
  }

  @override
  void dispose() {
    try {
      _tts.stop();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bgNavy = Color(0xFF0A192F);
    const surfaceNavy = Color(0xFF112240);
    const primaryAmber = Color(0xFFFFBF00);

    final mallState = ref.watch(mallProvider);
    final activeMall = mallState.displayName;
    final catalogService = ref.watch(mallCatalogServiceProvider);
    final category = catalogService.detectCategory(widget.product);
    final similarCount = catalogService.getSimilarProductsCount(
      widget.product,
      categoryFilter: category,
      mallName: activeMall,
    );
    final exactCatalogItem = catalogService.findExactCatalogItem(widget.product.name);
    final mallPrice = catalogService.getPriceForProductInMall(widget.product, activeMall);

    return Scaffold(
      backgroundColor: bgNavy,
      body: SafeArea(
        child: Column(
          children: [

            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: surfaceNavy.withAlpha(128))),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Semantics(
                        button: true,
                        label: 'Back',
                        child: GestureDetector(
                          onTap: () {
                            _tts.stop();
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: surfaceNavy,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withAlpha(25)),
                            ),
                            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          widget.product.brand.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: primaryAmber.withAlpha(200),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),


            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [

                  if (widget.capturedImage != null) ...[
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withAlpha(25)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(
                          widget.capturedImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],


                  Semantics(
                    label: 'Stop Summary',
                    button: true,
                    child: ElevatedButton(
                      onPressed: () => _tts.stop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAmber,
                        foregroundColor: bgNavy,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        elevation: 8,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.stop_circle_rounded, size: 36),
                          SizedBox(width: 8),
                          Text(
                            'STOP SUMMARY',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),



                  Row(
                    children: [
                      if (widget.product.isFood)
                        Expanded(
                          child: _StatCard(
                            label: 'Calories',
                            value: widget.product.calories.toString(),
                            surfaceNavy: surfaceNavy,
                            primaryAmber: primaryAmber,
                          ),
                        ),
                      if (widget.product.isFood) const SizedBox(width: 16),
                      if (widget.product.price != null || widget.product.mrp != null || mallPrice.isNotEmpty)
                        Expanded(
                          child: _StatCard(
                            label: 'Price in $activeMall',
                            value: mallPrice.isNotEmpty ? mallPrice : widget.product.displayPrice,
                            subtext: (exactCatalogItem != null && exactCatalogItem.mrp > 0)
                                ? 'MRP: ${exactCatalogItem.formattedMrp}'
                                : null,
                            surfaceNavy: surfaceNavy,
                            primaryAmber: primaryAmber,
                          ),
                        ),
                      if (widget.product.price != null || widget.product.mrp != null || mallPrice.isNotEmpty) const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          label: 'Size',
                          value: widget.product.size ?? widget.product.servingSize.split(' ').first,
                          subtext: widget.product.size == null ? widget.product.servingSize : null,
                          surfaceNavy: surfaceNavy,
                          primaryAmber: primaryAmber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ============================================
                  // MALL AVAILABILITY & SIMILAR PRODUCTS CARD
                  // ============================================
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF132F4C),
                          surfaceNavy,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: primaryAmber.withAlpha(160), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: primaryAmber.withAlpha(20),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryAmber.withAlpha(30),
                                shape: BoxShape.circle,
                                border: Border.all(color: primaryAmber.withAlpha(120)),
                              ),
                              child: const Icon(
                                Icons.storefront_rounded,
                                color: primaryAmber,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          'MALL AVAILABILITY • ${activeMall.toUpperCase()}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: primaryAmber,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Live catalog comparison for $activeMall',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        if (exactCatalogItem != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(10),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withAlpha(20)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'PRICE IN $activeMall',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      exactCatalogItem.formattedPriceForMall(activeMall),
                                      style: const TextStyle(
                                        color: primaryAmber,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'MRP (MAX)',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      exactCatalogItem.formattedMrp,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),
                        // Action button inside detail view
                        Semantics(
                          label: widget.product.source == 'mall_catalog'
                              ? 'Back to similar products in $activeMall'
                              : 'Suggest similar $category inside $activeMall',
                          button: true,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _tts.stop();
                              if (widget.product.source == 'mall_catalog') {
                                Navigator.of(context).pop();
                              } else {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => SimilarProductsScreen(
                                      scannedProduct: widget.product,
                                    ),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryAmber,
                              foregroundColor: bgNavy,
                              minimumSize: const Size(double.infinity, 54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 4,
                            ),
                            icon: Icon(
                              widget.product.source == 'mall_catalog'
                                  ? Icons.arrow_back_rounded
                                  : Icons.recommend_rounded,
                              size: 24,
                            ),
                            label: Text(
                              widget.product.source == 'mall_catalog'
                                  ? 'BACK TO SIMILAR PRODUCTS'
                                  : similarCount > 0
                                      ? 'SUGGEST SIMILAR $category IN $activeMall ($similarCount)'
                                          .toUpperCase()
                                      : 'NO OTHER $category IN $activeMall'
                                          .toUpperCase(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (widget.product.isFood && widget.product.nutritionInfo.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          const Text(
                            'NUTRITION FACTS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                            ),
                          ),
                          if (widget.product.servingSize != 'N/A' && widget.product.servingSize.isNotEmpty)
                            Expanded(
                              child: Text(
                                widget.product.servingSize,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  color: primaryAmber,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 2.5,
                      ),
                      itemCount: widget.product.nutritionInfo.length,
                      itemBuilder: (context, index) {
                        final key = widget.product.nutritionInfo.keys.elementAt(index);
                        final value = widget.product.nutritionInfo.values.elementAt(index);
                        final alphas = [255, 128, 76, 204];
                        final alpha = alphas[index % alphas.length];

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: surfaceNavy.withAlpha(150),
                            borderRadius: BorderRadius.circular(12),
                            border: Border(left: BorderSide(color: primaryAmber.withAlpha(alpha), width: 4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                key.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              Text(
                                value,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],


                  if (widget.product.ingredients != 'N/A' && widget.product.ingredients != 'Not available') ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        'COMPOSITION / INGREDIENTS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: surfaceNavy,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withAlpha(25)),
                      ),
                      child: Text(
                        widget.product.ingredients,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],


                  if (widget.product.isFood && widget.product.allergens.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: surfaceNavy,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: primaryAmber, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: primaryAmber.withAlpha(25),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.warning_rounded, color: primaryAmber, size: 36),
                              SizedBox(width: 12),
                              Text(
                                'ALLERGEN WARNING',
                                style: TextStyle(
                                  color: primaryAmber,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'CONTAINS: ${widget.product.allergens.join(", ").toUpperCase()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],


                  if (widget.product.honestTake != null && widget.product.honestTake!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryAmber.withAlpha(50),
                            surfaceNavy,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: primaryAmber.withAlpha(100), width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.lightbulb_rounded, color: primaryAmber, size: 28),
                              const SizedBox(width: 12),
                              Text(
                                'PRODUCT INSIGHTS',
                                style: TextStyle(
                                  color: primaryAmber,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.product.honestTake!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ],
              ),
            ),


            // Bottom Navigation & Actions inside Detail
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: surfaceNavy,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(100),
                    blurRadius: 30,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Similar Products in Mall Button inside Detail Screen
                  Semantics(
                    label: widget.product.source == 'mall_catalog'
                        ? 'Back to similar products in $activeMall'
                        : 'Explore similar products in $activeMall',
                    button: true,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _tts.stop();
                        if (widget.product.source == 'mall_catalog') {
                          Navigator.of(context).pop();
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SimilarProductsScreen(
                                scannedProduct: widget.product,
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAmber,
                        foregroundColor: bgNavy,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      icon: Icon(
                        widget.product.source == 'mall_catalog'
                            ? Icons.arrow_back_rounded
                            : Icons.storefront_rounded,
                        size: 24,
                      ),
                      label: Text(
                        widget.product.source == 'mall_catalog'
                            ? 'BACK TO SIMILAR PRODUCTS'
                            : similarCount > 0
                                ? 'SIMILAR IN ${activeMall.toUpperCase()} ($similarCount OPTIONS)'
                                : 'NO OTHER $category IN ${activeMall.toUpperCase()}'
                                    .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Semantics(
                    label: 'Go back',
                    button: true,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _tts.stop();
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withAlpha(60), width: 1.5),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_back_rounded, size: 22),
                      label: const Text(
                        'BACK',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
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
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtext;
  final Color surfaceNavy;
  final Color primaryAmber;

  const _StatCard({
    required this.label,
    required this.value,
    this.subtext,
    required this.surfaceNavy,
    required this.primaryAmber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(25)),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: primaryAmber.withAlpha(200),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (subtext != null) ...[
            const SizedBox(height: 2),
            Text(
              "($subtext)",
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
