import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_vision/models/product_model.dart';

void main() {
  group('Product Model Tests', () {
    test('Product.fromBarcodeJson parses valid data correctly', () {
      final json = {
        'barcode': '8901499008542',
        'name': "Haldiram's Bhujia Sev",
        'brand': "Haldiram's",
        'category': 'Snacks & Namkeen',
        'net_quantity': '200g',
        'mrp': 55.0,
        'ingredients': ['Moth Dal Flour', 'Besan', 'Salt'],
        'allergens': 'May contain traces of peanuts.',
        'shelf_life': '6 months from packaging',
        'description': 'Crispy spicy snack.',
      };

      final product = Product.fromBarcodeJson(json);

      expect(product.name, "Haldiram's Bhujia Sev");
      expect(product.brand, "Haldiram's");
      expect(product.barcode, '8901499008542');
      expect(product.mrp, 55.0);
      expect(product.source, 'barcode');
      expect(product.displayPrice, '₹55');
      expect(product.ingredients, 'Moth Dal Flour, Besan, Salt');
      expect(product.allergens, ['May contain traces of peanuts.']);
    });

    test('Product.displayPrice formats correctly', () {
      const p1 = Product(
        id: '1',
        name: 'Item 1',
        brand: 'Brand',
        calories: 100,
        servingSize: '100g',
        nutritionInfo: {},
        ingredients: 'None',
        allergens: [],
        mrp: 14.0,
      );
      expect(p1.displayPrice, '₹14');

      const p2 = Product(
        id: '2',
        name: 'Item 2',
        brand: 'Brand',
        calories: 100,
        servingSize: '100g',
        nutritionInfo: {},
        ingredients: 'None',
        allergens: [],
        mrp: 55.50,
      );
      expect(p2.displayPrice, '₹55.50');

      const p3 = Product(
        id: '3',
        name: 'Item 3',
        brand: 'Brand',
        calories: 100,
        servingSize: '100g',
        nutritionInfo: {},
        ingredients: 'None',
        allergens: [],
        price: '₹90',
      );
      expect(p3.displayPrice, '₹90');
    });

    test('Product serialization and deserialization roundtrip', () {
      final original = Product(
        id: 'test_123',
        name: 'Doritos Cheese',
        brand: 'Doritos',
        category: 'Snacks',
        calories: 150,
        servingSize: '30g',
        nutritionInfo: const {'Fat': '8g'},
        ingredients: 'Corn, Oil, Salt',
        allergens: const ['Milk'],
        barcode: '8901491101838',
        mrp: 30.0,
        source: 'barcode',
      );

      final map = original.toFirestore();
      final restored = Product.fromFirestore(map);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.barcode, original.barcode);
      expect(restored.mrp, original.mrp);
      expect(restored.source, original.source);
    });
  });
}
