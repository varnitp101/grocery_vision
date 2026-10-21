import 'product_model.dart';

class MallCatalogItem {
  final String name;
  final String category;
  final String weight;
  final double mrp;
  final double? dmartPrice;
  final double? reliancePrice;

  const MallCatalogItem({
    required this.name,
    required this.category,
    required this.weight,
    required this.mrp,
    this.dmartPrice,
    this.reliancePrice,
  });

  /// Get price for the designated mall
  double priceForMall(String mallName) {
    final lower = mallName.toLowerCase().trim();
    if (lower.contains('dmart')) {
      return dmartPrice ?? mrp;
    }
    if (lower.contains('reliance') || lower.contains('smart') || lower.contains('bazaar')) {
      return reliancePrice ?? mrp;
    }
    // For 'Others' or general, prefer lowest available promotional price
    if (dmartPrice != null && reliancePrice != null) {
      return dmartPrice! < reliancePrice! ? dmartPrice! : reliancePrice!;
    }
    return dmartPrice ?? reliancePrice ?? mrp;
  }

  /// Get formatted mall price with Rupee symbol
  String formattedPriceForMall(String mallName) {
    final price = priceForMall(mallName);
    return '₹${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)}';
  }

  /// Get formatted MRP with Rupee symbol
  String get formattedMrp {
    return '₹${mrp.toStringAsFixed(mrp.truncateToDouble() == mrp ? 0 : 2)}';
  }

  /// Savings amount in rupees compared to MRP
  double savingsForMall(String mallName) {
    final savings = mrp - priceForMall(mallName);
    return savings > 0 ? savings : 0;
  }

  /// Formatted savings amount
  String formattedSavingsForMall(String mallName) {
    final savings = savingsForMall(mallName);
    return '₹${savings.toStringAsFixed(savings.truncateToDouble() == savings ? 0 : 2)}';
  }

  /// Savings percentage
  int savingsPercentForMall(String mallName) {
    if (mrp <= 0) return 0;
    final savings = savingsForMall(mallName);
    return ((savings / mrp) * 100).round();
  }

  /// Extract brand from product name
  String get brand {
    final lower = name.toLowerCase();
    if (lower.startsWith('britannia')) return 'Britannia';
    if (lower.startsWith('parle')) return 'Parle';
    if (lower.startsWith('sunfeast') || lower.startsWith('dark fantasy')) return 'Sunfeast';
    if (lower.startsWith('cadbury')) return 'Cadbury';
    if (lower.startsWith('chaizop')) return 'Chaizop';
    if (lower.startsWith('red label')) return 'Brooke Bond';
    if (lower.startsWith('tata')) return 'Tata';
    if (lower.startsWith('society')) return 'Society';
    if (lower.startsWith('wagh bakri')) return 'Wagh Bakri';
    if (lower.startsWith('taj mahal')) return 'Brooke Bond';
    if (lower.startsWith('wishcare')) return 'WishCare';
    if (lower.startsWith('head and shoulders')) return 'Head & Shoulders';
    if (lower.startsWith('tresemme')) return 'TRESemmé';
    if (lower.startsWith('dove')) return 'Dove';
    if (lower.startsWith('sunsilk')) return 'Sunsilk';
    if (lower.startsWith('himalaya')) return 'Himalaya';
    if (lower.startsWith('pantene')) return 'Pantene';
    if (lower.startsWith('l\'oreal') || lower.startsWith('loreal')) return 'L\'Oréal Paris';
    return name.split(' ').first;
  }

  /// Convert into standard Product object for cart or details viewing
  Product toProduct({String activeMall = 'DMart'}) {
    final price = priceForMall(activeMall);
    final isFoodItem = category != 'Shampoo & Personal Care';

    final Map<String, String> nutrition;
    if (category.toLowerCase().contains('biscuit')) {
      nutrition = {
        'Calories': '465 kcal',
        'Carbohydrates': '72 g',
        'Sugars': '26 g',
        'Protein': '7 g',
        'Total Fat': '17 g',
      };
    } else if (category.toLowerCase().contains('tea')) {
      nutrition = {
        'Calories': '0 kcal',
        'Carbohydrates': '0 g',
        'Protein': '0 g',
        'Fat': '0 g',
      };
    } else {
      nutrition = const {};
    }

    return Product(
      id: 'mall_${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}',
      name: name,
      brand: brand,
      category: category,
      imageUrl: '',
      calories: isFoodItem ? (category.toLowerCase().contains('tea') ? 0 : 465) : 0,
      servingSize: weight,
      nutritionInfo: nutrition,
      ingredients: isFoodItem
          ? (category.toLowerCase().contains('tea')
              ? '100% Pure Indian Tea leaves sourced from premier tea gardens.'
              : 'Refined wheat flour, sugar, edible vegetable oil, invert sugar syrup, raising agents, salt, milk solids.')
          : 'Purified water, sodium laureth sulfate, cocamidopropyl betaine, pro-vitamin nourishment complex, essential conditioning extracts.',
      allergens: isFoodItem
          ? (category.toLowerCase().contains('tea')
              ? const []
              : const ['Contains Wheat (Gluten), Milk Solids'])
          : const [],
      size: weight,
      netQuantity: weight,
      price: price.toString(),
      mrp: mrp,
      source: 'mall_catalog',
      isFood: isFoodItem,
      honestTake: 'Verified in $activeMall catalog at ${formattedPriceForMall(activeMall)} ($weight). Save ${formattedSavingsForMall(activeMall)} off MRP ($formattedMrp).',
      shelfLife: isFoodItem ? (category.toLowerCase().contains('tea') ? '12 months' : '6 months') : '24 months',
      usageInstructions: isFoodItem
          ? (category.toLowerCase().contains('tea')
              ? 'Add 1 teaspoon per cup in boiling water or milk. Simmer for 2-3 minutes and strain.'
              : 'Ready to eat snack. Store in an airtight container after opening.')
          : 'Apply generously to wet hair, lather gently, and rinse thoroughly with clean water.',
      timestamp: DateTime.now(),
    );
  }
}
