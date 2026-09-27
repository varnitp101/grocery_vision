import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/product_model.dart';
import '../../../services/tts_service.dart';
import '../../cart/providers/cart_provider.dart';
import '../../cart/screens/added_to_cart_screen.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import 'product_details_screen.dart';

class ProductResultScreen extends ConsumerStatefulWidget {
  final Product product;
  final Uint8List? capturedImage;

  const ProductResultScreen({
    super.key,
    required this.product,
    this.capturedImage,
  });

  @override
  ConsumerState<ProductResultScreen> createState() => _ProductResultScreenState();
}

class _ProductResultScreenState extends ConsumerState<ProductResultScreen> {
  @override
  void initState() {
    super.initState();
    _announceResult();
  }

  Future<void> _announceResult() async {
    final tts = ref.read(ttsServiceProvider);
    final String pricePart = widget.product.mrp != null && widget.product.mrp! > 0
        ? 'Price ${widget.product.mrp!.toStringAsFixed(widget.product.mrp!.truncateToDouble() == widget.product.mrp! ? 0 : 2)} rupees.'
        : (widget.product.price != null && widget.product.price!.isNotEmpty
            ? 'Price ${widget.product.price}.'
            : '');

    final String brandPart =
        widget.product.brand.isNotEmpty && widget.product.brand != 'Unknown Brand'
            ? 'Brand: ${widget.product.brand}.'
            : '';

    final String announcement =
        'Result found: ${widget.product.name}. $brandPart $pricePart Category: ${widget.product.category}. '
        'Add to cart, details, repeat info, and scan next options available.';

    await tts.speak(announcement, priority: TtsPriority.immediate);
  }

  @override
  void dispose() {
    ref.read(ttsServiceProvider).stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const navyDeep = Color(0xFF0A1929);
    const navyCard = Color(0xFF132F4C);
    const primaryAmber = Color(0xFFFFBF00);
    final isBarcode = widget.product.source == 'barcode';

    return Scaffold(
      backgroundColor: navyDeep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Top Bar
              SizedBox(
                height: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Semantics(
                      label: 'Close result and return to scanner',
                      button: true,
                      child: GestureDetector(
                        onTap: () {
                          ref.read(ttsServiceProvider).stop();
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: navyCard,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withAlpha(25)),
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                    Semantics(
                      label: 'View Scan History',
                      button: true,
                      child: GestureDetector(
                        onTap: () {
                          ref.read(ttsServiceProvider).stop();
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const DashboardScreen(initialIndex: 1),
                            ),
                            (route) => false,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: navyCard,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withAlpha(25)),
                          ),
                          child: const Icon(Icons.history_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Product Info Card
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: navyCard,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withAlpha(12)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(50),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: widget.capturedImage != null
                                    ? Image.memory(
                                        widget.capturedImage!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      )
                                    : widget.product.imageUrl.isNotEmpty
                                        ? Image.network(
                                            widget.product.imageUrl,
                                            fit: BoxFit.contain,
                                            errorBuilder: (ctx, error, stackTrace) =>
                                                const Icon(
                                              Icons.image_not_supported,
                                              size: 100,
                                              color: Colors.white54,
                                            ),
                                          )
                                        : Container(
                                            color: navyDeep.withAlpha(100),
                                            child: const Center(
                                              child: Icon(
                                                Icons.camera_alt_rounded,
                                                size: 80,
                                                color: Colors.white24,
                                              ),
                                            ),
                                          ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                            child: Column(
                              children: [
                                Text(
                                  widget.product.name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.product.brand,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Price and Category Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: primaryAmber.withAlpha(30),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: primaryAmber.withAlpha(120)),
                                      ),
                                      child: Text(
                                        widget.product.displayPrice,
                                        style: const TextStyle(
                                          color: primaryAmber,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.white.withAlpha(30)),
                                      ),
                                      child: Text(
                                        widget.product.category.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                    if (widget.product.size != null &&
                                        widget.product.size!.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withAlpha(15),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.white.withAlpha(30)),
                                        ),
                                        child: Text(
                                          widget.product.size!,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Verification Badge (Top Right)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isBarcode
                                ? Colors.green.withAlpha(50)
                                : Colors.cyan.withAlpha(50),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isBarcode
                                  ? Colors.greenAccent.withAlpha(150)
                                  : Colors.cyanAccent.withAlpha(150),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isBarcode ? Icons.qr_code_scanner : Icons.auto_awesome,
                                color: isBarcode ? Colors.greenAccent : Colors.cyanAccent,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isBarcode ? 'BARCODE VERIFIED' : 'AI VISUAL SEARCH',
                                style: TextStyle(
                                  color: isBarcode ? Colors.greenAccent : Colors.cyanAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          label: 'Add to Cart',
                          icon: Icons.add_shopping_cart_rounded,
                          iconColor: primaryAmber,
                          bgColor: navyCard,
                          borderColor: Colors.white.withAlpha(50),
                          onTap: () {
                            ref.read(ttsServiceProvider).stop();
                            ref.read(cartProvider.notifier).addProduct(widget.product);
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => AddedToCartScreen(product: widget.product),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionCard(
                          label: 'Details',
                          icon: Icons.info_outline_rounded,
                          iconColor: Colors.white,
                          bgColor: navyCard,
                          borderColor: Colors.white.withAlpha(50),
                          onTap: () {
                            ref.read(ttsServiceProvider).stop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProductDetailsScreen(
                                  product: widget.product,
                                  capturedImage: widget.capturedImage,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          label: 'Repeat',
                          icon: Icons.volume_up_rounded,
                          iconColor: Colors.white.withAlpha(230),
                          bgColor: Colors.white.withAlpha(20),
                          borderColor: Colors.white.withAlpha(25),
                          onTap: _announceResult,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionCard(
                          label: 'Scan Another',
                          icon: Icons.photo_camera_rounded,
                          iconColor: Colors.black,
                          labelColor: Colors.black,
                          bgColor: primaryAmber,
                          borderColor: primaryAmber,
                          onTap: () {
                            ref.read(ttsServiceProvider).stop();
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;
  final Color labelColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
    this.labelColor = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: labelColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
