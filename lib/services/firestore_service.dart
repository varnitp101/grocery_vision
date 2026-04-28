import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';
import '../models/cart_item.dart';

/// Handles all Firestore operations for cart persistence and scan history.
/// Data is scoped per authenticated user: users/{uid}/cart and users/{uid}/scanHistory.
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ─── Cart Operations ───────────────────────────────────────────────

  /// Save the entire cart to Firestore (overwrites).
  Future<void> saveCart(List<CartItem> items) async {
    final uid = _uid;
    if (uid == null) return;

    final batch = _db.batch();
    final cartRef = _db.collection('users').doc(uid).collection('cart');

    // Delete all existing cart items first
    final existing = await cartRef.get();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }

    // Add all current items
    for (final item in items) {
      final docRef = cartRef.doc(item.product.id);
      batch.set(docRef, {
        'product': item.product.toFirestore(),
        'quantity': item.quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  /// Load cart from Firestore.
  Future<List<CartItem>> loadCart() async {
    final uid = _uid;
    if (uid == null) return [];

    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('cart')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final product = Product.fromFirestore(data['product'] as Map<String, dynamic>);
      final quantity = (data['quantity'] as num?)?.toInt() ?? 1;
      return CartItem(product: product, quantity: quantity);
    }).toList();
  }

  // ─── Scan History Operations ───────────────────────────────────────

  /// Log a successful scan to history.
  Future<void> logScan(Product product) async {
    final uid = _uid;
    if (uid == null) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('scanHistory')
        .add({
      'product': product.toFirestore(),
      'scannedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get recent scan history (last 20 scans).
  Future<List<Map<String, dynamic>>> getRecentScans() async {
    final uid = _uid;
    if (uid == null) return [];

    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('scanHistory')
        .orderBy('scannedAt', descending: true)
        .limit(20)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'product': Product.fromFirestore(data['product'] as Map<String, dynamic>),
        'scannedAt': (data['scannedAt'] as Timestamp?)?.toDate(),
      };
    }).toList();
  }
}
