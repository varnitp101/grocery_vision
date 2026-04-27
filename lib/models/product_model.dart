class Product {
  final String id;
  final String name;
  final String brand;
  final double price;
  final String imageUrl;
  final int calories;
  final String servingSize;
  final Map<String, String> nutritionInfo;
  final String ingredients;
  final List<String> allergens;
  final String? size;

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.imageUrl,
    required this.calories,
    required this.servingSize,
    required this.nutritionInfo,
    required this.ingredients,
    required this.allergens,
    this.size,
  });
}

// Dummy mock product for testing
const mockWholeMilk = Product(
  id: 'mock_milk_01',
  name: 'Whole Milk',
  brand: 'Great Value',
  price: 3.50,
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
