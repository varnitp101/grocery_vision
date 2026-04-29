import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_ai/firebase_ai.dart';
import '../models/product_model.dart';

/// Service that sends product photos to Gemini 2.0 Flash and gets back
/// structured product information. Uses Firebase AI Logic (Google AI backend).
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
          TextPart('Identify this grocery product. Return ONLY raw JSON (no markdown): {"name":"Product name","brand":"Brand","category":"Category","calories":0,"servingSize":"Size","nutritionInfo":{"Fat":"g","Carb":"g","Protein":"g","Sodium":"mg"},"ingredients":"List","allergens":[],"size":"Weight"}. If unknown return {"error":"not_found"}. Be concise.'),
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
      // ignore: avoid_print
      print('GeminiService error: $e');
      return null;
    }
  }
}
