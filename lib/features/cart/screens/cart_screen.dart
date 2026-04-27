import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cart_provider.dart';
import '../../../models/cart_item.dart';
import '../../dashboard/screens/dashboard_screen.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const navyDeep = Color(0xFF050F25);
    const navyLight = Color(0xFF0F2042);
    const primaryAmber = Color(0xFFFFA200);

    final cartItems = ref.watch(cartProvider);
    final totalItems = ref.watch(cartProvider.notifier).totalItems;
    final totalPrice = ref.watch(cartProvider.notifier).totalPrice;

    return Scaffold(
      backgroundColor: navyDeep,
      body: SafeArea(
        child: Column(
          children: [
            // Header Config
            Container(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              decoration: BoxDecoration(
                color: navyDeep,
                border: Border(bottom: BorderSide(color: Colors.white.withAlpha(50))),
              ),
              child: const Center(
                child: Text(
                  'MY CART',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
            ),

            // Top Total Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: navyDeep,
                border: Border(bottom: BorderSide(color: Colors.white.withAlpha(25))),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                decoration: BoxDecoration(
                  color: navyLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primaryAmber, width: 2),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'ITEMS',
                            style: TextStyle(
                              color: Colors.white.withAlpha(180),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            totalItems.toString(),
                            style: const TextStyle(
                              color: primaryAmber,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 60, color: Colors.white.withAlpha(25)),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'TOTAL',
                            style: TextStyle(
                              color: Colors.white.withAlpha(180),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: primaryAmber,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Cart Items List
            Expanded(
              child: cartItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.white.withAlpha(50)),
                          const SizedBox(height: 16),
                          Text(
                            'YOUR CART IS EMPTY',
                            style: TextStyle(
                              color: Colors.white.withAlpha(150),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 120), // Padding bottom for fixed Add bar
                      itemCount: cartItems.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _buildCartItemCard(
                          cartItems[index],
                          ref,
                          navyDeep,
                          navyLight,
                          primaryAmber,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        decoration: BoxDecoration(
          color: navyDeep,
          border: Border(top: BorderSide(color: Colors.white.withAlpha(50))),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(128), blurRadius: 40, offset: const Offset(0, -10)),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            // TODO: Route to barcode scan or search? Maybe just back to the Dashboard's Scanner tab.
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const DashboardScreen(initialIndex: 0)), // 0 is Home/Scanner
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryAmber,
            foregroundColor: navyDeep,
            minimumSize: const Size(double.infinity, 70),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 10,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_rounded, size: 36),
              SizedBox(width: 12),
              Text(
                'ADD NEW ITEM',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartItemCard(CartItem item, WidgetRef ref, Color navyDeep, Color navyLight, Color primaryAmber) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: navyDeep,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryAmber.withAlpha(200), width: 3),
        boxShadow: [
          BoxShadow(color: primaryAmber.withAlpha(30), blurRadius: 30),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: primaryAmber,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${item.product.price.toStringAsFixed(2)}  •  ${item.product.brand}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(25)),
            ),
            child: Column(
              children: [
                const Text(
                  'QUANTITY',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _QuantityButton(
                      icon: Icons.remove_rounded,
                      onTap: () {
                        ref.read(cartProvider.notifier).updateQuantity(item.product.id, item.quantity - 1);
                      },
                      primaryAmber: primaryAmber,
                      navyLight: navyLight,
                    ),
                    Text(
                      item.quantity.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                        letterSpacing: -2.0,
                      ),
                    ),
                    _QuantityButton(
                      icon: Icons.add_rounded,
                      onTap: () {
                        ref.read(cartProvider.notifier).updateQuantity(item.product.id, item.quantity + 1);
                      },
                      primaryAmber: primaryAmber,
                      navyLight: navyLight,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(cartProvider.notifier).removeProduct(item.product.id);
              },
              icon: const Icon(Icons.delete_rounded),
              label: const Text(
                'REMOVE ITEM',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent.shade100,
                side: BorderSide(color: Colors.redAccent.withAlpha(100), width: 2),
                backgroundColor: Colors.white.withAlpha(12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color primaryAmber;
  final Color navyLight;

  const _QuantityButton({
    required this.icon,
    required this.onTap,
    required this.primaryAmber,
    required this.navyLight,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: navyLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(76), width: 2),
        ),
        child: Icon(icon, color: Colors.white, size: 36),
      ),
    );
  }
}
