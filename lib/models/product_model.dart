class Product {
  final String id;
  final String name;
  final String brand;
  final String category;
  final String imageUrl;
  final int calories;
  final String servingSize;
  final Map<String, String> nutritionInfo;
  final String ingredients;
  final List<String> allergens;
  final String? size;
  final String? price;
  final bool isFood;
  final String? honestTake;

  // Additional fields for Barcode & Local DB Pipeline
  final String? barcode;
  final double? mrp;
  final String source; // 'barcode' | 'gemini' | 'manual'
  final DateTime timestamp;
  final String? shelfLife;
  final String? usageInstructions;
  final String? netQuantity;

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    this.category = 'General',
    this.imageUrl = '',
    required this.calories,
    required this.servingSize,
    required this.nutritionInfo,
    required this.ingredients,
    required this.allergens,
    this.size,
    this.price,
    this.isFood = true,
    this.honestTake,
    this.barcode,
    this.mrp,
    this.source = 'gemini',
    DateTime? timestamp,
    this.shelfLife,
    this.usageInstructions,
    this.netQuantity,
  }) : timestamp = timestamp ?? const _DefaultDateTime();

  /// Formatted price preferring MRP with Indian Rupee symbol
  String get displayPrice {
    if (mrp != null && mrp! > 0) {
      return '₹${mrp!.toStringAsFixed(mrp!.truncateToDouble() == mrp! ? 0 : 2)}';
    }
    if (price != null && price!.trim().isNotEmpty) {
      final trimmed = price!.trim();
      return trimmed.startsWith('₹') ? trimmed : '₹$trimmed';
    }
    return 'Price on request';
  }

  /// Factory for products parsed from Gemini JSON
  factory Product.fromGeminiJson(Map<String, dynamic> json) {
    final rawNutrition = json['nutritionInfo'] as Map<String, dynamic>? ?? {};
    final nutritionInfo = rawNutrition.map(
      (key, value) => MapEntry(key, value.toString()),
    );

    final rawAllergens = json['allergens'] as List<dynamic>? ?? [];
    final allergens = rawAllergens.map((e) => e.toString()).toList();

    // Parse potential MRP from price field if present
    double? parsedMrp;
    final priceStr = json['price']?.toString() ?? '';
    final digitsMatch = RegExp(r'(\d+(\.\d+)?)').firstMatch(priceStr);
    if (digitsMatch != null) {
      parsedMrp = double.tryParse(digitsMatch.group(1)!);
    }

    return Product(
      id: 'gemini_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Unknown Product',
      brand: json['brand'] as String? ?? 'Unknown Brand',
      category: json['category'] as String? ?? 'General',
      imageUrl: '',
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      servingSize: json['servingSize'] as String? ?? 'N/A',
      nutritionInfo: nutritionInfo,
      ingredients: json['ingredients'] as String? ?? 'Not available',
      allergens: allergens,
      size: json['size'] as String?,
      price: json['price'] as String?,
      mrp: parsedMrp,
      source: 'gemini',
      isFood: json['isFood'] as bool? ?? true,
      honestTake: json['honestTake'] as String?,
      timestamp: DateTime.now(),
    );
  }

  /// Factory for products loaded from Barcode Database JSON
  factory Product.fromBarcodeJson(Map<String, dynamic> json) {
    final rawIngredients = json['ingredients'];
    String ingredientsStr = 'Not available';
    if (rawIngredients is List) {
      ingredientsStr = rawIngredients.map((e) => e.toString()).join(', ');
    } else if (rawIngredients is String) {
      ingredientsStr = rawIngredients;
    }

    List<String> allergensList = [];
    final rawAllergens = json['allergens'];
    if (rawAllergens is List) {
      allergensList = rawAllergens.map((e) => e.toString()).toList();
    } else if (rawAllergens is String && rawAllergens.isNotEmpty) {
      allergensList = [rawAllergens];
    }

    final double mrpValue = (json['mrp'] as num?)?.toDouble() ??
        (json['price'] as num?)?.toDouble() ??
        0.0;

    return Product(
      id: 'barcode_${json['barcode'] ?? DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Unknown Product',
      brand: json['brand'] as String? ?? 'Unknown Brand',
      category: json['category'] as String? ?? 'Grocery',
      imageUrl: json['imageUrl'] as String? ?? '',
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      servingSize: json['net_quantity'] as String? ?? json['servingSize'] as String? ?? '1 pack',
      nutritionInfo: const {},
      ingredients: ingredientsStr,
      allergens: allergensList,
      size: json['net_quantity'] as String?,
      netQuantity: json['net_quantity'] as String?,
      price: mrpValue > 0 ? mrpValue.toString() : null,
      mrp: mrpValue > 0 ? mrpValue : null,
      barcode: json['barcode'] as String?,
      source: 'barcode',
      isFood: json['isFood'] as bool? ?? true,
      honestTake: json['description'] as String?,
      shelfLife: json['shelf_life'] as String?,
      usageInstructions: json['usage_instructions'] as String?,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'category': category,
      'imageUrl': imageUrl,
      'calories': calories,
      'servingSize': servingSize,
      'nutritionInfo': nutritionInfo,
      'ingredients': ingredients,
      'allergens': allergens,
      'size': size,
      'price': price,
      'mrp': mrp,
      'barcode': barcode,
      'source': source,
      'isFood': isFood,
      'honestTake': honestTake,
      'shelfLife': shelfLife,
      'usageInstructions': usageInstructions,
      'netQuantity': netQuantity,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Product.fromFirestore(Map<String, dynamic> json) {
    final rawNutrition = json['nutritionInfo'] as Map<String, dynamic>? ?? {};
    final nutritionInfo = rawNutrition.map(
      (key, value) => MapEntry(key, value.toString()),
    );
    final rawAllergens = json['allergens'] as List<dynamic>? ?? [];
    final allergens = rawAllergens.map((e) => e.toString()).toList();

    DateTime parsedTimestamp = DateTime.now();
    if (json['timestamp'] is String) {
      parsedTimestamp = DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now();
    }

    return Product(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      brand: json['brand'] as String? ?? 'Unknown',
      category: json['category'] as String? ?? 'General',
      imageUrl: json['imageUrl'] as String? ?? '',
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      servingSize: json['servingSize'] as String? ?? 'N/A',
      nutritionInfo: nutritionInfo,
      ingredients: json['ingredients'] as String? ?? 'Not available',
      allergens: allergens,
      size: json['size'] as String?,
      price: json['price'] as String?,
      mrp: (json['mrp'] as num?)?.toDouble(),
      barcode: json['barcode'] as String?,
      source: json['source'] as String? ?? 'gemini',
      isFood: json['isFood'] as bool? ?? true,
      honestTake: json['honestTake'] as String?,
      shelfLife: json['shelfLife'] as String?,
      usageInstructions: json['usageInstructions'] as String?,
      netQuantity: json['netQuantity'] as String?,
      timestamp: parsedTimestamp,
    );
  }

  Map<String, dynamic> toMap() => toFirestore();

  factory Product.fromMap(Map<String, dynamic> map) => Product.fromFirestore(map);
}

class _DefaultDateTime implements DateTime {
  const _DefaultDateTime();

  DateTime get _now => DateTime.now();

  @override
  bool isAfter(DateTime other) => _now.isAfter(other);
  @override
  bool isBefore(DateTime other) => _now.isBefore(other);
  @override
  bool isAtSameMomentAs(DateTime other) => _now.isAtSameMomentAs(other);
  @override
  int compareTo(DateTime other) => _now.compareTo(other);

  @override
  DateTime add(Duration duration) => _now.add(duration);
  @override
  DateTime subtract(Duration duration) => _now.subtract(duration);
  @override
  Duration difference(DateTime other) => _now.difference(other);

  @override
  int get millisecondsSinceEpoch => _now.millisecondsSinceEpoch;
  @override
  int get microsecondsSinceEpoch => _now.microsecondsSinceEpoch;
  @override
  String get timeZoneName => _now.timeZoneName;
  @override
  Duration get timeZoneOffset => _now.timeZoneOffset;
  @override
  int get year => _now.year;
  @override
  int get month => _now.month;
  @override
  int get day => _now.day;
  @override
  int get hour => _now.hour;
  @override
  int get minute => _now.minute;
  @override
  int get second => _now.second;
  @override
  int get millisecond => _now.millisecond;
  @override
  int get microsecond => _now.microsecond;
  @override
  int get weekday => _now.weekday;

  @override
  String toIso8601String() => _now.toIso8601String();
  @override
  DateTime toLocal() => _now.toLocal();
  @override
  DateTime toUtc() => _now.toUtc();
  @override
  String toString() => _now.toString();
  @override
  bool get isUtc => false;
}

const mockWholeMilk = Product(
  id: 'mock_milk_01',
  name: 'Whole Milk',
  brand: 'Great Value',
  imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCoAFCS31gdFSEFHvQlULfmxQ9cTD25J5P8V3cetSTteZEVvqSRYn1yPaTG4BNaREfBGTQwr-9FsuO-wTQGN7a_LzNS_U7eJbYmfqvP51yfasOciy63pCKj5aTlu_FbQYjJsAkK3hjUPdm6RAnMygU0pw2jDNP6XrVK8rl4grEFn9A47E4T_NUygxGlbRk1z107-Zx7PNppGIyn4avkaN9PRT83OJYRi5rH54g4wsF5VeXe7pVuNNnEfZisG_G044fQZ1AF7Fe9eftj',
  calories: 150,
  servingSize: '1 cup (240ml)',
  nutritionInfo: {
    'Total Fat': '8g',
    'Saturated Fat': '5g',
    'Trans Fat': '0g',
    'Cholesterol': '35mg',
    'Sodium': '125mg',
    'Total Carb': '12g',
    'Sugars': '12g',
    'Protein': '8g',
  },
  ingredients: 'Grade A Pasteurized Homogenized Milk, Vitamin D3.',
  allergens: ['Milk'],
  size: '1 Liter',
);
