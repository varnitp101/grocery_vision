import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';

abstract class BarcodeProductRepository {
  Future<void> initialize();
  Future<Product?> getProductByBarcode(String barcode);
}

class LocalBarcodeProductRepository implements BarcodeProductRepository {
  final Map<String, Product> _products = {};
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final jsonString = await rootBundle.loadString('assets/data/product_barcode_mapping.json');
      final Map<String, dynamic> decoded = json.decode(jsonString);

      decoded.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          final product = Product.fromBarcodeJson(value);
          _products[key.trim()] = product;
          if (product.barcode != null && product.barcode!.isNotEmpty) {
            _products[product.barcode!.trim()] = product;
          }
        }
      });
      _initialized = true;
    } catch (e) {
      _initialized = true;
    }
  }

  @override
  Future<Product?> getProductByBarcode(String barcode) async {
    if (!_initialized) {
      await initialize();
    }
    final cleanBarcode = barcode.trim();
    if (_products.containsKey(cleanBarcode)) {
      return _products[cleanBarcode];
    }

    // Try without leading zeros or with fuzzy matches
    for (final entry in _products.entries) {
      if (entry.key.endsWith(cleanBarcode) || cleanBarcode.endsWith(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }
}

final barcodeProductRepositoryProvider = Provider<BarcodeProductRepository>((ref) {
  final repo = LocalBarcodeProductRepository();
  repo.initialize();
  return repo;
});
