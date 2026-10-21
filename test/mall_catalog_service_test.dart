import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_vision/models/product_model.dart';
import 'package:grocery_vision/services/mall_catalog_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MallCatalogService service;

  setUp(() {
    service = MallCatalogService();
  });

  group('MallCatalogService CSV Matching & Pricing Tests', () {
    test('Matches Chaizup Premix variant to Chaizop Tea Mix with correct CSV prices', () {
      final item = service.findExactCatalogItem('Chaizup Instant Premix Cardamom Tea');
      expect(item, isNotNull);
      expect(item!.name, 'Chaizop Tea Mix');
      expect(item.category, 'Tea & Beverages');
      expect(item.formattedPriceForMall('DMart'), '₹115');
      expect(item.formattedPriceForMall('Reliance Smart Bazaar'), '₹118');
      expect(item.mrp, 150.0);
    });

    test('Matches Dark Fantasy Bourbon and retrieves DMart and Reliance prices', () {
      final item = service.findExactCatalogItem('Sunfeast Dark Fantasy Bourbon');
      expect(item, isNotNull);
      expect(item!.name, 'Dark Fantasy Bourbon');
      expect(item.category, 'Biscuits & Cookies');
      expect(item.formattedPriceForMall('DMart'), '₹25');
      expect(item.formattedPriceForMall('Reliance Smart Bazaar'), '₹23');
    });

    test('Matches WishCare Shampoo with correct mall prices', () {
      final item = service.findExactCatalogItem('WishCare Fermented Rice Water Shampoo');
      expect(item, isNotNull);
      expect(item!.name, 'WishCare Shampoo');
      expect(item.category, 'Shampoo & Personal Care');
      expect(item.formattedPriceForMall('DMart'), '₹180');
      expect(item.formattedPriceForMall('Reliance Smart Bazaar'), '₹210');
    });

    test('getPriceForProductInMall returns CSV price for DMart and Reliance', () {
      const scannedChaizup = Product(
        id: '1',
        name: 'Chaizup Cardamom Tea Premix',
        brand: 'Chaizup',
        calories: 60,
        servingSize: '1 sachet',
        nutritionInfo: {},
        ingredients: 'Tea, Cardamom',
        allergens: [],
        price: '₹130',
      );

      final dmartPrice = service.getPriceForProductInMall(scannedChaizup, 'DMart');
      expect(dmartPrice, '₹115');

      final reliancePrice = service.getPriceForProductInMall(scannedChaizup, 'Reliance Smart Bazaar');
      expect(reliancePrice, '₹118');
    });

    test('calibrateProductWithCsv updates Product price and MRP with CSV data', () {
      const scannedChaizup = Product(
        id: '1',
        name: 'Chaizup Instant Premix Cardamom Tea',
        brand: 'Chaizup',
        calories: 60,
        servingSize: '1 sachet',
        nutritionInfo: {},
        ingredients: 'Tea, Cardamom',
        allergens: [],
        price: '₹130',
      );

      final calibrated = service.calibrateProductWithCsv(scannedChaizup, 'DMart');
      expect(calibrated.price, '₹115');
      expect(calibrated.mrp, 150.0);
      expect(calibrated.category, 'Tea & Beverages');
      expect(calibrated.displayPrice, '₹150'); // displayPrice prefers MRP when available
    });
  });

  group('MallCatalogService Similar Products Filtering Tests', () {
    test('Strictly excludes scanned tea product from similar products list', () {
      const scannedChaizup = Product(
        id: '1',
        name: 'Chaizup Instant Premix Cardamom Tea',
        brand: 'Chaizup',
        category: 'Tea & Beverages',
        calories: 60,
        servingSize: '1 sachet',
        nutritionInfo: {},
        ingredients: 'Tea',
        allergens: [],
      );

      final similar = service.getSimilarProducts(
        scannedProduct: scannedChaizup,
        mallName: 'DMart',
      );

      // Verify that Chaizop Tea Mix is NOT in the similar products list
      final containsChaizop = similar.any((item) => item.name == 'Chaizop Tea Mix');
      expect(containsChaizop, false);

      // Verify that all results are strictly in Tea & Beverages
      for (final item in similar) {
        expect(item.category, 'Tea & Beverages');
      }

      // Verify count matches
      final count = service.getSimilarProductsCount(
        scannedChaizup,
        categoryFilter: 'Tea & Beverages',
        mallName: 'DMart',
      );
      expect(count, similar.length);
      expect(similar.isNotEmpty, true);
    });

    test('Strictly excludes scanned biscuit from similar products list', () {
      const scannedBourbon = Product(
        id: '2',
        name: 'Dark Fantasy Bourbon',
        brand: 'Sunfeast',
        category: 'Biscuits & Cookies',
        calories: 120,
        servingSize: '2 biscuits',
        nutritionInfo: {},
        ingredients: 'Flour, sugar, cocoa',
        allergens: ['Wheat'],
      );

      final similar = service.getSimilarProducts(
        scannedProduct: scannedBourbon,
        mallName: 'DMart',
      );

      final containsDarkBourbon = similar.any((item) => item.name == 'Dark Fantasy Bourbon');
      expect(containsDarkBourbon, false);

      // Verify all results are biscuits
      for (final item in similar) {
        expect(item.category, 'Biscuits & Cookies');
      }
    });

    test('Strictly excludes scanned shampoo from similar products list', () {
      const scannedShampoo = Product(
        id: '3',
        name: 'WishCare Fermented Rice Water Shampoo',
        brand: 'WishCare',
        category: 'Shampoo & Personal Care',
        calories: 0,
        servingSize: '10ml',
        nutritionInfo: {},
        ingredients: 'Aqua, fermented rice water',
        allergens: [],
        isFood: false,
      );

      final similar = service.getSimilarProducts(
        scannedProduct: scannedShampoo,
        mallName: 'DMart',
      );

      final containsWishCare = similar.any((item) => item.name == 'WishCare Shampoo');
      expect(containsWishCare, false);

      // Verify all results are shampoos
      for (final item in similar) {
        expect(item.category, 'Shampoo & Personal Care');
      }
    });

    test('Non-catalog products like footwear never return biscuits and return 0 similar items', () {
      const scannedSneakers = Product(
        id: '4',
        name: 'Ducati High-Top Sneakers',
        brand: 'Ducati',
        category: 'FOOTWEAR',
        calories: 0,
        servingSize: 'N/A',
        nutritionInfo: {},
        ingredients: 'Leather, rubber sole',
        allergens: [],
        price: '₹6',
      );

      final detected = service.detectCategory(scannedSneakers);
      expect(detected, 'Footwear');
      expect(detected, isNot('Biscuits & Cookies'));

      final similar = service.getSimilarProducts(
        scannedProduct: scannedSneakers,
        mallName: 'DMart',
      );
      expect(similar.isEmpty, true);

      final count = service.getSimilarProductsCount(
        scannedSneakers,
        mallName: 'DMart',
      );
      expect(count, 0);
    });

    test('Non-catalog electronics or stationery products return 0 similar options in DMart', () {
      const scannedItem = Product(
        id: '5',
        name: 'Logitech Wireless Mouse',
        brand: 'Logitech',
        category: 'Electronics',
        calories: 0,
        servingSize: '1 unit',
        nutritionInfo: {},
        ingredients: '',
        allergens: [],
      );

      final detected = service.detectCategory(scannedItem);
      expect(detected, 'Electronics');

      final count = service.getSimilarProductsCount(scannedItem, mallName: 'DMart');
      expect(count, 0);
    });
  });
}
