import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mall_catalog_item.dart';
import '../models/product_model.dart';

class MallCatalogService {
  List<MallCatalogItem> _items = [];
  bool _initialized = false;

  static const List<MallCatalogItem> defaultCatalog = [
    // --- Tea & Beverages ---
    MallCatalogItem(
      name: 'Chaizop Tea Mix',
      category: 'Tea & Beverages',
      weight: '140 g',
      mrp: 150.0,
      dmartPrice: 115.0,
      reliancePrice: 118.0,
    ),
    MallCatalogItem(
      name: 'Red Label Tea',
      category: 'Tea & Beverages',
      weight: '250 g',
      mrp: 135.0,
      dmartPrice: 96.0,
      reliancePrice: 104.0,
    ),
    MallCatalogItem(
      name: 'Tata Tea Gold',
      category: 'Tea & Beverages',
      weight: '250 g',
      mrp: 180.0,
      dmartPrice: 159.0,
      reliancePrice: 140.0,
    ),
    MallCatalogItem(
      name: 'Society Leaf Tea',
      category: 'Tea & Beverages',
      weight: '250 g',
      mrp: 155.0,
      dmartPrice: 145.0,
      reliancePrice: 147.0,
    ),
    MallCatalogItem(
      name: 'Wagh Bakri Premium Tea',
      category: 'Tea & Beverages',
      weight: '500 g',
      mrp: 325.0,
      dmartPrice: 300.0,
      reliancePrice: 295.0,
    ),
    MallCatalogItem(
      name: 'Taj Mahal Tea',
      category: 'Tea & Beverages',
      weight: '250 g',
      mrp: 220.0,
      dmartPrice: 205.0,
      reliancePrice: 214.0,
    ),

    // --- Biscuits & Cookies ---
    MallCatalogItem(
      name: 'Dark Fantasy Bourbon',
      category: 'Biscuits & Cookies',
      weight: '99 g',
      mrp: 30.0,
      dmartPrice: 25.0,
      reliancePrice: 23.0,
    ),
    MallCatalogItem(
      name: 'Britannia Marie Gold',
      category: 'Biscuits & Cookies',
      weight: '68 g',
      mrp: 10.0,
      dmartPrice: 9.0,
      reliancePrice: 9.0,
    ),
    MallCatalogItem(
      name: 'Parle Hide And Seek Black Bourbon',
      category: 'Biscuits & Cookies',
      weight: '300 g',
      mrp: 160.0,
      dmartPrice: 140.0,
      reliancePrice: 130.0,
    ),
    MallCatalogItem(
      name: 'Britannia Bourbon',
      category: 'Biscuits & Cookies',
      weight: '50 g',
      mrp: 10.0,
      dmartPrice: 9.0,
      reliancePrice: 9.0,
    ),
    MallCatalogItem(
      name: 'Sunfeast Dark Fantasy Choco Fills',
      category: 'Biscuits & Cookies',
      weight: '20 g',
      mrp: 10.0,
      dmartPrice: 9.0,
      reliancePrice: 9.0,
    ),
    MallCatalogItem(
      name: 'Dark Fantasy Sandwich Creme',
      category: 'Biscuits & Cookies',
      weight: '79 g',
      mrp: 30.0,
      dmartPrice: 20.0,
      reliancePrice: 20.0,
    ),
    MallCatalogItem(
      name: 'Britannia Little Hearts',
      category: 'Biscuits & Cookies',
      weight: '75 g',
      mrp: 30.0,
      dmartPrice: 25.0,
      reliancePrice: 23.0,
    ),
    MallCatalogItem(
      name: 'Hide And Seek Choco Chip Sandwich Creme',
      category: 'Biscuits & Cookies',
      weight: '400 g',
      mrp: 150.0,
      dmartPrice: 135.0,
      reliancePrice: 125.0,
    ),
    MallCatalogItem(
      name: 'Britannia Milk Bikis Milky Sandwich Creme',
      category: 'Biscuits & Cookies',
      weight: '188 g',
      mrp: 55.0,
      dmartPrice: 50.0,
      reliancePrice: 40.0,
    ),
    MallCatalogItem(
      name: 'Britannia 50-50 Sweet & Salty',
      category: 'Biscuits & Cookies',
      weight: '63 g',
      mrp: 10.0,
      dmartPrice: 8.0,
      reliancePrice: 9.0,
    ),
    MallCatalogItem(
      name: 'Parle Monaco',
      category: 'Biscuits & Cookies',
      weight: '65 g',
      mrp: 10.0,
      dmartPrice: 9.0,
      reliancePrice: 8.0,
    ),
    MallCatalogItem(
      name: 'Britannia Treat Jim Jam',
      category: 'Biscuits & Cookies',
      weight: '57 g',
      mrp: 10.0,
      dmartPrice: 9.0,
      reliancePrice: 8.0,
    ),
    MallCatalogItem(
      name: 'Cadbury Oreo',
      category: 'Biscuits & Cookies',
      weight: '41.75 g',
      mrp: 10.0,
      dmartPrice: 9.0,
      reliancePrice: 10.0,
    ),
    MallCatalogItem(
      name: 'Britannia NutriChoice Digestive Biscuits',
      category: 'Biscuits & Cookies',
      weight: '100 g',
      mrp: 25.0,
      dmartPrice: 22.0,
      reliancePrice: 20.0,
    ),
    MallCatalogItem(
      name: 'Britannia Good Day Butter Cookies',
      category: 'Biscuits & Cookies',
      weight: '120 g',
      mrp: 25.0,
      dmartPrice: 20.0,
      reliancePrice: 23.0,
    ),

    // --- Shampoo & Haircare ---
    MallCatalogItem(
      name: 'WishCare Shampoo',
      category: 'Shampoo & Personal Care',
      weight: '120 ml',
      mrp: 259.0,
      dmartPrice: 180.0,
      reliancePrice: 210.0,
    ),
    MallCatalogItem(
      name: 'Head And Shoulders Shampoo',
      category: 'Shampoo & Personal Care',
      weight: '180 ml',
      mrp: 218.0,
      dmartPrice: 179.0,
      reliancePrice: 185.0,
    ),
    MallCatalogItem(
      name: 'Tresemme Shampoo',
      category: 'Shampoo & Personal Care',
      weight: '180 ml',
      mrp: 172.0,
      dmartPrice: 135.0,
      reliancePrice: 150.0,
    ),
    MallCatalogItem(
      name: 'Dove Shampoo',
      category: 'Shampoo & Personal Care',
      weight: '340 ml',
      mrp: 435.0,
      dmartPrice: 395.0,
      reliancePrice: 350.0,
    ),
    MallCatalogItem(
      name: 'Sunsilk Shampoo',
      category: 'Shampoo & Personal Care',
      weight: '180 ml',
      mrp: 135.0,
      dmartPrice: 125.0,
      reliancePrice: 120.0,
    ),
    MallCatalogItem(
      name: 'Himalaya Shampoo',
      category: 'Shampoo & Personal Care',
      weight: '340 ml',
      mrp: 319.0,
      dmartPrice: 169.0,
      reliancePrice: 170.0,
    ),
    MallCatalogItem(
      name: 'Pantene Shampoo',
      category: 'Shampoo & Personal Care',
      weight: '500 ml',
      mrp: 806.0,
      dmartPrice: 654.0,
      reliancePrice: 689.0,
    ),
    MallCatalogItem(
      name: 'L\'Oreal Paris Shampoo',
      category: 'Shampoo & Personal Care',
      weight: '340 ml',
      mrp: 519.0,
      dmartPrice: 345.0,
      reliancePrice: 389.0,
    ),
  ];

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final csvString = await rootBundle.loadString('assets/data/grocery_vision_catalog.csv');
      final lines = csvString.split('\n');
      final List<MallCatalogItem> parsedItems = [];

      // Skip header line
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final parts = line.split(',');
        if (parts.length >= 5) {
          final name = parts[0].trim();
          final dmartRaw = parts[1].replaceAll(RegExp(r'[^0-9.]'), '');
          final relianceRaw = parts[2].replaceAll(RegExp(r'[^0-9.]'), '');
          final mrpRaw = parts[3].replaceAll(RegExp(r'[^0-9.]'), '');
          final weight = parts[4].trim();

          final dmart = double.tryParse(dmartRaw);
          final reliance = double.tryParse(relianceRaw);
          final mrp = double.tryParse(mrpRaw) ?? 0.0;

          parsedItems.add(
            MallCatalogItem(
              name: name,
              category: _detectCategoryFromStrings([name]) ?? 'Biscuits & Cookies',
              weight: weight,
              mrp: mrp,
              dmartPrice: dmart,
              reliancePrice: reliance,
            ),
          );
        }
      }

      if (parsedItems.isNotEmpty) {
        _items = parsedItems;
      } else {
        _items = List.from(defaultCatalog);
      }
      _initialized = true;
    } catch (_) {
      _items = List.from(defaultCatalog);
      _initialized = true;
    }
  }

  List<MallCatalogItem> get allItems {
    if (!_initialized || _items.isEmpty) {
      return defaultCatalog;
    }
    return _items;
  }

  /// Categorize product based on its title, brand, or existing category
  String detectCategory(Product product) {
    // 1. Direct match with catalog item
    final matched = findExactCatalogItem(product.name);
    if (matched != null) {
      return matched.category;
    }

    // 2. Keyword detection from product fields (tea, biscuits, shampoo)
    final detected = _detectCategoryFromStrings([
      product.name,
      product.category,
      product.brand,
      product.ingredients,
      product.honestTake ?? '',
    ]);
    if (detected != null) {
      return detected;
    }

    // 3. Fallback to product's own detected/extracted category (e.g. Footwear, Electronics)
    final rawCat = product.category.trim();
    if (rawCat.isNotEmpty &&
        rawCat.toLowerCase() != 'general' &&
        rawCat.toLowerCase() != 'unknown' &&
        rawCat.toLowerCase() != 'product' &&
        rawCat.toLowerCase() != 'item') {
      if (rawCat == rawCat.toUpperCase() && rawCat.length > 2) {
        return rawCat[0].toUpperCase() + rawCat.substring(1).toLowerCase();
      }
      return rawCat;
    }

    return 'Other';
  }

  static String? _detectCategoryFromStrings(List<String> textPieces) {
    final combined = textPieces.join(' ').toLowerCase();

    // Biscuits & Cookies
    if (combined.contains('biscuit') ||
        combined.contains('cookie') ||
        combined.contains('bourbon') ||
        combined.contains('oreo') ||
        combined.contains('marie') ||
        combined.contains('jim jam') ||
        combined.contains('jimjam') ||
        combined.contains('monaco') ||
        combined.contains('50-50') ||
        combined.contains('50 50') ||
        combined.contains('little heart') ||
        combined.contains('choco fill') ||
        combined.contains('hide and seek') ||
        combined.contains('hide & seek') ||
        combined.contains('digestive') ||
        combined.contains('parle-g') ||
        combined.contains('parle g') ||
        combined.contains('good day') ||
        combined.contains('goodday') ||
        combined.contains('krackjack') ||
        combined.contains('dark fantasy') ||
        combined.contains('milk bikis') ||
        combined.contains('sandwich creme') ||
        combined.contains('sandwich cream') ||
        combined.contains('wafer') ||
        combined.contains('rusk')) {
      return 'Biscuits & Cookies';
    }

    // Tea & Beverages
    if (combined.contains('tea') ||
        combined.contains('chai') ||
        combined.contains('chaizop') ||
        combined.contains('chaizup') ||
        combined.contains('premix') ||
        combined.contains('wagh bakri') ||
        combined.contains('waghbakri') ||
        combined.contains('red label') ||
        combined.contains('taj mahal') ||
        combined.contains('leaf tea') ||
        combined.contains('coffee') ||
        combined.contains('bru') ||
        combined.contains('nescafe') ||
        combined.contains('green tea') ||
        combined.contains('beverage')) {
      return 'Tea & Beverages';
    }

    // Shampoo & Personal Care
    if (combined.contains('shampoo') ||
        combined.contains('hair cleanser') ||
        combined.contains('hair wash') ||
        combined.contains('conditioner') ||
        combined.contains('tresemme') ||
        combined.contains('tresemmé') ||
        combined.contains('wishcare') ||
        combined.contains('wish care') ||
        combined.contains('dove') ||
        combined.contains('sunsilk') ||
        combined.contains('pantene') ||
        combined.contains('head and shoulders') ||
        combined.contains('head & shoulders') ||
        combined.contains('himalaya') ||
        combined.contains('l\'oreal') ||
        combined.contains('loreal')) {
      return 'Shampoo & Personal Care';
    }

    // Never blindly return a fallback category like 'Biscuits & Cookies'!
    return null;
  }

  /// Find exact match in catalog if exists, using full name, keyword aliases, or specific brand mapping
  MallCatalogItem? findExactCatalogItem(String productName) {
    final clean = productName.toLowerCase().trim();
    if (clean.isEmpty) return null;

    // 1. Direct exact or substring matches
    for (final item in allItems) {
      final itemLower = item.name.toLowerCase().trim();
      if (itemLower == clean || clean.contains(itemLower) || itemLower.contains(clean)) {
        return item;
      }
    }

    // 2. Specific alias mappings for all 29 items from grocery_vision_catalog.csv
    // Tea & Beverages
    if (clean.contains('chaizop') || clean.contains('chaizup')) {
      return _getItemByName('Chaizop Tea Mix');
    }
    if (clean.contains('red label')) {
      return _getItemByName('Red Label Tea');
    }
    if (clean.contains('tata tea') || clean.contains('tata gold')) {
      return _getItemByName('Tata Tea Gold');
    }
    if (clean.contains('society')) {
      return _getItemByName('Society Leaf Tea');
    }
    if (clean.contains('wagh bakri') || clean.contains('waghbakri')) {
      return _getItemByName('Wagh Bakri Premium Tea');
    }
    if (clean.contains('taj mahal')) {
      return _getItemByName('Taj Mahal Tea');
    }

    // Biscuits & Cookies
    if (clean.contains('choco fill') || clean.contains('choco fills')) {
      return _getItemByName('Sunfeast Dark Fantasy Choco Fills');
    }
    if (clean.contains('sandwich creme') || clean.contains('sandwich cream')) {
      if (clean.contains('hide') && clean.contains('seek')) {
        return _getItemByName('Hide And Seek Choco Chip Sandwich Creme');
      }
      if (clean.contains('milk bikis')) {
        return _getItemByName('Britannia Milk Bikis Milky Sandwich Creme');
      }
      return _getItemByName('Dark Fantasy Sandwich Creme');
    }
    if (clean.contains('dark fantasy') && (clean.contains('bourbon') || clean.contains('biscuit'))) {
      return _getItemByName('Dark Fantasy Bourbon');
    }
    if (clean.contains('black bourbon')) {
      return _getItemByName('Parle Hide And Seek Black Bourbon');
    }
    if (clean.contains('bourbon')) {
      if (clean.contains('britannia')) {
        return _getItemByName('Britannia Bourbon');
      }
      if (clean.contains('dark fantasy') || clean.contains('sunfeast')) {
        return _getItemByName('Dark Fantasy Bourbon');
      }
      if (clean.contains('parle') || clean.contains('hide')) {
        return _getItemByName('Parle Hide And Seek Black Bourbon');
      }
      return _getItemByName('Dark Fantasy Bourbon');
    }
    if (clean.contains('marie')) {
      return _getItemByName('Britannia Marie Gold');
    }
    if (clean.contains('little heart') || clean.contains('little hearts')) {
      return _getItemByName('Britannia Little Hearts');
    }
    if (clean.contains('milk bikis')) {
      return _getItemByName('Britannia Milk Bikis Milky Sandwich Creme');
    }
    if (clean.contains('50-50') || clean.contains('50 50') || clean.contains('sweet & salty') || clean.contains('fifty fifty')) {
      return _getItemByName('Britannia 50-50 Sweet & Salty');
    }
    if (clean.contains('monaco')) {
      return _getItemByName('Parle Monaco');
    }
    if (clean.contains('jim jam') || clean.contains('jimjam')) {
      return _getItemByName('Britannia Treat Jim Jam');
    }
    if (clean.contains('oreo')) {
      return _getItemByName('Cadbury Oreo');
    }
    if (clean.contains('nutrichoice') || clean.contains('digestive')) {
      return _getItemByName('Britannia NutriChoice Digestive Biscuits');
    }
    if (clean.contains('good day') || clean.contains('goodday')) {
      return _getItemByName('Britannia Good Day Butter Cookies');
    }

    // Shampoo & Personal Care
    if (clean.contains('wishcare') || clean.contains('wish care')) {
      return _getItemByName('WishCare Shampoo');
    }
    if (clean.contains('head') && clean.contains('shoulder')) {
      return _getItemByName('Head And Shoulders Shampoo');
    }
    if (clean.contains('tresemme') || clean.contains('tresemmé')) {
      return _getItemByName('Tresemme Shampoo');
    }
    if (clean.contains('dove')) {
      return _getItemByName('Dove Shampoo');
    }
    if (clean.contains('sunsilk')) {
      return _getItemByName('Sunsilk Shampoo');
    }
    if (clean.contains('himalaya')) {
      return _getItemByName('Himalaya Shampoo');
    }
    if (clean.contains('pantene')) {
      return _getItemByName('Pantene Shampoo');
    }
    if (clean.contains('l\'oreal') || clean.contains('loreal')) {
      return _getItemByName('L\'Oreal Paris');
    }

    return null;
  }

  MallCatalogItem? _getItemByName(String exactName) {
    for (final item in allItems) {
      if (item.name.toLowerCase().trim() == exactName.toLowerCase().trim()) {
        return item;
      }
    }
    return null;
  }

  /// Check if a catalog item represents the same product as the scanned product
  bool isSameProduct(MallCatalogItem item, Product product) {
    final cleanItem = item.name.toLowerCase().trim();
    final cleanProduct = product.name.toLowerCase().trim();

    if (cleanItem == cleanProduct) return true;

    // Check if the product matches this item via exact catalog lookup
    final matched = findExactCatalogItem(product.name);
    if (matched != null && matched.name.toLowerCase().trim() == cleanItem) {
      return true;
    }

    // Check if one contains the other
    if (cleanProduct.contains(cleanItem) || cleanItem.contains(cleanProduct)) {
      return true;
    }

    return false;
  }

  /// Returns the price for a product from the CSV catalog for the given mall.
  /// If the product is not in the CSV catalog, falls back to product.displayPrice.
  String getPriceForProductInMall(Product product, String mallName) {
    final matched = findExactCatalogItem(product.name);
    if (matched != null) {
      return matched.formattedPriceForMall(mallName);
    }
    return product.displayPrice;
  }

  /// Calibrate and enrich a scanned product with CSV catalog information
  Product calibrateProductWithCsv(Product product, String mallName) {
    final matched = findExactCatalogItem(product.name);
    if (matched == null) return product;

    final mallPrice = matched.formattedPriceForMall(mallName);
    return product.copyWith(
      price: mallPrice,
      mrp: matched.mrp,
      size: (product.size != null && product.size!.isNotEmpty) ? product.size : matched.weight,
      category: matched.category,
    );
  }

  /// Get similar products within the selected mall for a given scanned product or category.
  /// Strictly EXCLUDES the scanned product so it never appears again in the similar list!
  List<MallCatalogItem> getSimilarProducts({
    Product? scannedProduct,
    String? categoryFilter,
    required String mallName,
  }) {
    final category = categoryFilter ??
        (scannedProduct != null ? detectCategory(scannedProduct) : 'All');

    // Filter items in the category (or all items if category == 'All')
    final categoryItems = (category == 'All'
            ? allItems
            : allItems.where((item) =>
                item.category.toLowerCase().trim() == category.toLowerCase().trim()))
        .where((item) {
          // STRICTLY EXCLUDE the scanned product!
          if (scannedProduct != null && isSameProduct(item, scannedProduct)) {
            return false;
          }
          return true;
        })
        .toList();

    // Sort by savings for the active mall (highest savings first)
    categoryItems.sort((a, b) {
      final savingsA = a.savingsForMall(mallName);
      final savingsB = b.savingsForMall(mallName);
      return savingsB.compareTo(savingsA);
    });

    return categoryItems;
  }

  /// Count of similar products available in mall (excluding scanned product)
  int getSimilarProductsCount(
    Product? scannedProduct, {
    String? categoryFilter,
    String mallName = 'DMart',
  }) {
    return getSimilarProducts(
      scannedProduct: scannedProduct,
      categoryFilter: categoryFilter,
      mallName: mallName,
    ).length;
  }
}

final mallCatalogServiceProvider = Provider<MallCatalogService>((ref) {
  final service = MallCatalogService();
  service.initialize();
  return service;
});
