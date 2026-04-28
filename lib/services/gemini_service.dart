import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_ai/firebase_ai.dart';
import '../models/product_model.dart';

/// Service that sends product photos to Gemini 2.5 Flash and gets back
/// structured product information. This is the "backend" — Gemini runs
/// on Google's servers via Firebase AI Logic.
class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  late final GenerativeModel _model;
  bool _initialized = false;

  /// Initialize the Gemini model. Call once at app startup.
  void initialize() {
    if (_initialized) return;
    _model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
    );
    _initialized = true;
  }

  /// Send a product photo to Gemini and get back a Product object.
  /// Returns null if the product cannot be identified.
  Future<Product?> identifyProduct(Uint8List imageBytes) async {
    if (!_initialized) initialize();

    try {
      final response = await _model.generateContent([
        Content.multi([
          TextPart('''You are a grocery product identification expert.
Analyze this image and identify the grocery/food product shown.

Return ONLY a valid JSON object with this exact structure (no markdown, no code fences, just raw JSON):
{
  "name": "Full product name",
  "brand": "Brand or manufacturer name",
  "category": "Product category (e.g., Dairy, Snacks, Beverages, Produce, Meat, Bakery, Canned Goods, Frozen, Condiments, Cereal, etc.)",
  "calories": 0,
  "servingSize": "Standard serving size with unit",
  "nutritionInfo": {
    "Total Fat": "value with unit",
    "Saturated Fat": "value with unit",
    "Trans Fat": "value with unit",
    "Cholesterol": "value with unit",
    "Sodium": "value with unit",
    "Total Carb": "value with unit",
    "Sugars": "value with unit",
    "Protein": "value with unit"
  },
  "ingredients": "Full ingredients list as a single string",
  "allergens": ["allergen1", "allergen2"],
  "size": "Package size/weight"
}

Rules:
- If you can see nutrition info on the label, use those exact values.
- If nutrition info is not visible, provide your best estimate based on the product type.
- If you cannot identify the product at all, return: {"error": "not_found"}
- For allergens, include common allergens like Milk, Eggs, Wheat, Soy, Peanuts, Tree Nuts, Fish, Shellfish, Sesame if applicable.
- Return ONLY the JSON, no explanations or markdown formatting.'''),
          InlineDataPart('image/jpeg', imageBytes),
        ]),
      ]);

      final responseText = response.text;
      if (responseText == null || responseText.isEmpty) {
        return null;
      }

      // Clean up the response — Gemini sometimes wraps JSON in markdown code fences
      String cleanJson = responseText.trim();
      if (cleanJson.startsWith('```json')) {
        cleanJson = cleanJson.substring(7);
      } else if (cleanJson.startsWith('```')) {
        cleanJson = cleanJson.substring(3);
      }
      if (cleanJson.endsWith('```')) {
        cleanJson = cleanJson.substring(0, cleanJson.length - 3);
      }
      cleanJson = cleanJson.trim();

      final Map<String, dynamic> jsonData = jsonDecode(cleanJson);

      // Check if Gemini couldn't identify the product
      if (jsonData.containsKey('error')) {
        return null;
      }

      return Product.fromGeminiJson(jsonData);
    } catch (e) {
      // Log error for debugging but return null to the UI
      // ignore: avoid_print
      print('GeminiService error: $e');
      return null;
    }
  }
}
