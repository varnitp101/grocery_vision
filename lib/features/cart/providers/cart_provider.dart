import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/cart_item.dart';
import '../../../models/product_model.dart';
import '../../../services/firestore_service.dart';

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  final FirestoreService _firestore = FirestoreService();


  Future<void> loadFromFirestore() async {
    try {
      final items = await _firestore.loadCart();
      state = items;
    } catch (_) {

    }
  }

  void addProduct(Product product) {
    final hasItem = state.any((item) => item.product.id == product.id);
    if (hasItem) {
      state = state.map((item) {
        if (item.product.id == product.id) {
          return item.copyWith(quantity: item.quantity + 1);
        }
        return item;
      }).toList();
    } else {
      state = [...state, CartItem(product: product, quantity: 1)];
    }
    _syncToFirestore();
  }

  void removeProduct(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
    _syncToFirestore();
  }

  void updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeProduct(productId);
      return;
    }
    state = state.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(quantity: newQuantity);
      }
      return item;
    }).toList();
    _syncToFirestore();
  }

  int get totalItems {
    return state.fold(0, (sum, item) => sum + item.quantity);
  }


  Future<void> _syncToFirestore() async {
    try {
      await _firestore.saveCart(state);
    } catch (_) {

    }
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});
