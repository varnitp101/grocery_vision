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
  });


  factory Product.fromGeminiJson(Map<String, dynamic> json) {

    final rawNutrition = json['nutritionInfo'] as Map<String, dynamic>? ?? {};
    final nutritionInfo = rawNutrition.map(
      (key, value) => MapEntry(key, value.toString()),
    );


    final rawAllergens = json['allergens'] as List<dynamic>? ?? [];
    final allergens = rawAllergens.map((e) => e.toString()).toList();

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
      isFood: json['isFood'] as bool? ?? true,
      honestTake: json['honestTake'] as String?,
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
      'isFood': isFood,
      'honestTake': honestTake,
    };
  }


  factory Product.fromFirestore(Map<String, dynamic> json) {
    final rawNutrition = json['nutritionInfo'] as Map<String, dynamic>? ?? {};
    final nutritionInfo = rawNutrition.map(
      (key, value) => MapEntry(key, value.toString()),
    );
    final rawAllergens = json['allergens'] as List<dynamic>? ?? [];
    final allergens = rawAllergens.map((e) => e.toString()).toList();

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
      isFood: json['isFood'] as bool? ?? true,
      honestTake: json['honestTake'] as String?,
    );
  }
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
