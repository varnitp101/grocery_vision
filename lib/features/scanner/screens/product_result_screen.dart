import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../models/product_model.dart';
import '../../cart/providers/cart_provider.dart';
import '../../cart/screens/added_to_cart_screen.dart';
import 'product_details_screen.dart';

class ProductResultScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductResultScreen({super.key, required this.product});

  @override
  ConsumerState<ProductResultScreen> createState() => _ProductResultScreenState();
}

class _ProductResultScreenState extends ConsumerState<ProductResultScreen> {
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _announceResult();
  }

  Future<void> _announceResult() async {
    final String announcement = 'Result found: ${widget.product.name}. Brand: ${widget.product.brand}. '
        'Category: ${widget.product.category}. Add to cart, details, repeat info, and scan next options available.';
    await _tts.speak(announcement);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const navyDeep = Color(0xFF0A1929);
    const navyCard = Color(0xFF132F4C);
    const primaryAmber = Color(0xFFFFBF00);

    return Scaffold(
      backgroundColor: navyDeep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header
              SizedBox(
                height: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Semantics(
                      label: 'Close result',
                      button: true,
                      child: GestureDetector(
                        onTap: () {
                          _tts.stop();
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
                          // TODO: History screen
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
              
              // Main Card
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
                              padding: const EdgeInsets.all(24.0),
                              child: Image.network(
                                widget.product.imageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (ctx, error, stackTrace) => const Icon(Icons.image_not_supported, size: 100, color: Colors.white54),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                Text(
                                  widget.product.name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.product.brand,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: primaryAmber.withAlpha(30),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: primaryAmber.withAlpha(80)),
                                  ),
                                  child: Text(
                                    widget.product.category.toUpperCase(),
                                    style: const TextStyle(
                                      color: primaryAmber,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      // Match Badge
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withAlpha(50),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.green.withAlpha(128)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 14),
                              SizedBox(width: 4),
                              Text(
                                '98% MATCH',
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
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
              
              // Navigation / Actions
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
                            _tts.stop();
                            ref.read(cartProvider.notifier).addProduct(widget.product);
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => AddedToCartScreen(product: widget.product)),
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
                            _tts.stop();
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: widget.product)),
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
                          label: 'Scan Next',
                          icon: Icons.photo_camera_rounded,
                          iconColor: Colors.black,
                          labelColor: Colors.black,
                          bgColor: primaryAmber,
                          borderColor: primaryAmber,
                          onTap: () {
                            _tts.stop();
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
