import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../../dashboard/screens/dashboard_screen.dart';

class AddedToCartScreen extends ConsumerStatefulWidget {
  final Product product;

  const AddedToCartScreen({super.key, required this.product});

  @override
  ConsumerState<AddedToCartScreen> createState() => _AddedToCartScreenState();
}

class _AddedToCartScreenState extends ConsumerState<AddedToCartScreen> {
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _announceAdded();
  }

  Future<void> _announceAdded() async {


    final totalItems = ref.read(cartProvider.notifier).totalItems;
    final String announcement = 'Success. ${widget.product.name} added to cart. '
        'Total items are now $totalItems. Double tap top button to view cart or bottom button to scan more.';
    await _tts.speak(announcement);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF050F25);
    const primaryAmber = Color(0xFFFFA200);
    final totalItems = ref.watch(cartProvider.notifier).totalItems;

    return Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24),
          child: Column(
            children: [

              const Padding(
                padding: EdgeInsets.only(top: 24, bottom: 16),
                child: Text(
                  'ADDED\nTO CART',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    letterSpacing: 2.0,
                  ),
                ),
              ),


              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                        decoration: BoxDecoration(
                          color: primaryAmber,
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(128),
                              blurRadius: 60,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: navy,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(50),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 64,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              widget.product.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: navy,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                                letterSpacing: -1.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.product.size?.toUpperCase() ?? '1 ITEM',
                              style: TextStyle(
                                color: navy.withAlpha(200),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),


                      Text(
                        'CART SUMMARY',
                        style: TextStyle(
                          color: Colors.white.withAlpha(150),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Total Items:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            totalItems.toString(),
                            style: const TextStyle(
                              color: primaryAmber,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ),
              ),


              Column(
                children: [
                  Semantics(
                    label: 'Go to Cart',
                    button: true,
                    child: ElevatedButton(
                      onPressed: () {
                        _tts.stop();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const DashboardScreen(initialIndex: 2),
                          ),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAmber,
                        foregroundColor: navy,
                        minimumSize: const Size(double.infinity, 80),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 10,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_rounded, size: 32),
                          SizedBox(width: 12),
                          Text(
                            'GO TO CART',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    label: 'Continue Scanning',
                    button: true,
                    child: OutlinedButton(
                      onPressed: () {
                        _tts.stop();
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 80),
                        side: BorderSide(color: Colors.white.withAlpha(76), width: 3),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_scanner_rounded, size: 32),
                          SizedBox(width: 12),
                          Text(
                            'CONTINUE SCANNING',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                    ),
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
