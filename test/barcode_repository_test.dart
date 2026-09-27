import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_vision/models/product_model.dart';

void main() {
  group('Barcode Repository JSON Mapping Tests', () {
    test('Sample barcode mapping JSON contains required fields and parses properly', () {
      const sampleJson = '''
      {
        "8901499008542": {
          "barcode": "8901499008542",
          "name": "Haldiram's Bhujia Sev",
          "brand": "Haldiram's",
          "category": "Snacks & Namkeen",
          "net_quantity": "200g",
          "mrp": 55.0,
          "price": 50.0,
          "ingredients": ["Moth Dal Flour", "Besan", "Salt"],
          "allergens": "May contain traces of peanuts.",
          "shelf_life": "6 months from packaging"
        }
      }
      ''';

      final Map<String, dynamic> decoded = jsonDecode(sampleJson);
      expect(decoded.containsKey('8901499008542'), isTrue);

      final product = Product.fromBarcodeJson(decoded['8901499008542']);
      expect(product.name, "Haldiram's Bhujia Sev");
      expect(product.mrp, 55.0);
      expect(product.barcode, '8901499008542');
      expect(product.source, 'barcode');
    });
  });
}
