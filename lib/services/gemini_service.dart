import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_ai/firebase_ai.dart';
import '../models/product_model.dart';



class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  late final GenerativeModel _model;
  bool _initialized = false;


  void initialize() {
    if (_initialized) return;
    _model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
    );
    _initialized = true;
  }



  Future<Product?> identifyProduct(Uint8List imageBytes) async {
    if (!_initialized) initialize();

    try {
      final response = await _model.generateContent([
        Content.multi([
          TextPart('You are an expert product analyst and OCR system. Carefully analyze this image and read ALL visible text.\n'
              'Return ONLY raw JSON (no markdown). The JSON must follow this exact schema:\n'
              '{"name":"Product Name","brand":"Brand","category":"Category","isFood":true/false,"price":"Approx Price (e.g. ₹60)","size":"Weight/Qty",'
              '"calories":0,"servingSize":"Specify reference quantity (e.g. per 100g)","nutritionInfo":{"Fat":"g","Carb":"g"},'
              '"ingredients":"List of ingredients or N/A","allergens":[],'
              '"honestTake":"A brutally honest, short, punchy, and helpful take on this product. Be objective but bold."}\n'
              'If the product is NOT food (e.g. soap, vaseline), set "isFood":false and "calories":0.\n'
              'For pricing of products not in the override list below, compare estimated prices from at least 5 major retail providers (e.g., Blinkit, Zepto, Swiggy Instamart, BigBasket, Amazon Fresh, local stores) and return the nearest/average realistic value, NOT just the lowest minimum price.\n\n'
              'CRITICAL OVERRIDE RULE: If you identify the product as one of the following 8 specific items (even if the name varies slightly in the image), you MUST return EXACTLY the data mapped below, ignoring what you extract or retrieve:\n'
              '1. Haldiram All in one -> name: "Haldiram\'s All In One", brand: "Haldiram\'s", category: "Snacks", isFood: true, price: "₹57.00", size: "200g", calories: 558, servingSize: "per 100g", nutritionInfo: {"Protein": "15.36g", "Carbs": "42.13g", "Total Fat": "36.5g"}, ingredients: "Edible Vegetable oil, Bengal Gram Flour, Rice Flakes, Tepary Beans...", allergens: ["Peanuts", "Cashews", "Wheat", "Sesame Seed"], honestTake: "A highly processed, high-calorie salt bomb. Tastes great but terrible for daily health."\n'
              '2. Chaizop Instant premix -> name: "Chaizup Instant Premix Cardamom Tea", brand: "Chaizup", category: "Beverages", isFood: true, price: "₹130", size: "10 Sachets (14g each)", calories: 58.8, servingSize: "per 14g sachet", nutritionInfo: {"Protein": "1.4g", "Carbs": "10.5g", "Total Fat": "1.4g", "Sugar": "7.6g"}, ingredients: "Dairy whitener, Sugar, Tea extracts, Cardamom extracts...", allergens: ["Milk"], honestTake: "Extremely high in sugar (7.6g per 14g serving). Essentially a sugar-milk powder with some tea flavoring."\n'
              '3. Vaseline skin protecting jelly+ -> name: "Vaseline Original Skin Protecting Jelly", brand: "Vaseline", category: "Personal Care", isFood: false, price: "₹90", size: "40g", calories: 0, servingSize: "N/A", nutritionInfo: {}, ingredients: "Mineral Oil, Paraffin, Microcrystalline Wax...", allergens: [], honestTake: "A classic, effective petroleum jelly barrier for dry skin. Purity guaranteed, but it is a petroleum byproduct."\n'
              '4. Savlon Antiseptic Disinfectant -> name: "Savlon Antiseptic Disinfectant Liquid", brand: "Savlon", category: "Health & Hygiene", isFood: false, price: "₹103", size: "200ml", calories: 0, servingSize: "N/A", nutritionInfo: {}, ingredients: "Chlorhexidine Gluconate Solution, Cetrimide Solution", allergens: [], honestTake: "Effective household antiseptic and disinfectant. Contains strong chemicals, strictly for external use."\n'
              '5. Vaseline light hydrate lotion -> name: "Vaseline Light Hydrate Gel Lotion", brand: "Vaseline", category: "Personal Care", isFood: false, price: "₹99", size: "90ml", calories: 0, servingSize: "N/A", nutritionInfo: {}, ingredients: "Water, Ethylhexyl Methoxycinnamate, Niacinamide, Glycerin...", allergens: [], honestTake: "A lightweight, fast-absorbing lotion with Niacinamide. Good for everyday mild hydration, though contains parabens."\n'
              '6. Vaseline cocoa butter lip tin -> name: "Vaseline Lip Therapy Cocoa Butter Tin", brand: "Vaseline", category: "Personal Care", isFood: false, price: "₹270", size: "17g", calories: 0, servingSize: "N/A", nutritionInfo: {}, ingredients: "Petrolatum, Theobroma Cacao Seed Butter, Flavor...", allergens: [], honestTake: "Great for locking in moisture on lips, nice cocoa scent. It is mostly petroleum jelly though."\n'
              '7. Fevi stick -> name: "Fevi Stick Glue", brand: "Pidilite", category: "Stationery", isFood: false, price: "₹25.00", size: "8g", calories: 0, servingSize: "N/A", nutritionInfo: {}, ingredients: "Adhesive polymer", allergens: [], honestTake: "A reliable, non-messy glue stick for paper and crafts. Keep away from children\'s mouths."\n'
              '8. Engage on Cool Marine -> name: "Engage ON Cool Marine Perfume Spray", brand: "Engage", category: "Personal Care", isFood: false, price: "₹60.00", size: "17ml", calories: 0, servingSize: "N/A", nutritionInfo: {}, ingredients: "Alcohol, Fragrance, Water...", allergens: [], honestTake: "Pocket-friendly and travel-ready deodorant spray. The scent doesn\'t last all day, but it\'s super convenient."\n'
              'If unknown return {"error":"not_found"}.'),
          InlineDataPart('image/jpeg', imageBytes),
        ]),
      ]);

      final responseText = response.text;
      if (responseText == null || responseText.isEmpty) {
        return null;
      }


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


      if (jsonData.containsKey('error')) {
        return null;
      }

      return Product.fromGeminiJson(jsonData);
    } catch (e) {

      print('GeminiService error: $e');
      return null;
    }
  }
}
