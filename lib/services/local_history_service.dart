import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/product_model.dart';

class LocalHistoryService {
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'grocery_vision.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE scans (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            brand TEXT,
            category TEXT,
            imageUrl TEXT,
            price TEXT,
            mrp REAL,
            barcode TEXT,
            source TEXT,
            calories INTEGER,
            servingSize TEXT,
            ingredients TEXT,
            allergens TEXT,
            nutritionInfo TEXT,
            size TEXT,
            isFood INTEGER,
            honestTake TEXT,
            shelfLife TEXT,
            usageInstructions TEXT,
            netQuantity TEXT,
            timestamp TEXT
          )
        ''');
      },
    );
  }

  /// Inserts or replaces a scanned product in local SQLite
  Future<void> saveScan(Product product) async {
    try {
      final db = await database;
      await db.insert(
        'scans',
        {
          'id': product.id,
          'name': product.name,
          'brand': product.brand,
          'category': product.category,
          'imageUrl': product.imageUrl,
          'price': product.price,
          'mrp': product.mrp,
          'barcode': product.barcode,
          'source': product.source,
          'calories': product.calories,
          'servingSize': product.servingSize,
          'ingredients': product.ingredients,
          'allergens': jsonEncode(product.allergens),
          'nutritionInfo': jsonEncode(product.nutritionInfo),
          'size': product.size,
          'isFood': product.isFood ? 1 : 0,
          'honestTake': product.honestTake,
          'shelfLife': product.shelfLife,
          'usageInstructions': product.usageInstructions,
          'netQuantity': product.netQuantity,
          'timestamp': product.timestamp.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  /// Fetches recent scans ordered by timestamp descending
  Future<List<Product>> getScans({int limit = 50}) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'scans',
        orderBy: 'timestamp DESC',
        limit: limit,
      );

      return maps.map((row) {
        List<String> allergens = [];
        try {
          if (row['allergens'] != null) {
            allergens = (jsonDecode(row['allergens'] as String) as List<dynamic>)
                .map((e) => e.toString())
                .toList();
          }
        } catch (_) {}

        Map<String, String> nutritionInfo = {};
        try {
          if (row['nutritionInfo'] != null) {
            final decoded = jsonDecode(row['nutritionInfo'] as String) as Map<String, dynamic>;
            nutritionInfo = decoded.map((k, v) => MapEntry(k, v.toString()));
          }
        } catch (_) {}

        DateTime timestamp = DateTime.now();
        if (row['timestamp'] != null) {
          timestamp = DateTime.tryParse(row['timestamp'] as String) ?? DateTime.now();
        }

        return Product(
          id: row['id'] as String,
          name: row['name'] as String? ?? 'Unknown',
          brand: row['brand'] as String? ?? 'Unknown',
          category: row['category'] as String? ?? 'General',
          imageUrl: row['imageUrl'] as String? ?? '',
          price: row['price'] as String?,
          mrp: (row['mrp'] as num?)?.toDouble(),
          barcode: row['barcode'] as String?,
          source: row['source'] as String? ?? 'gemini',
          calories: (row['calories'] as num?)?.toInt() ?? 0,
          servingSize: row['servingSize'] as String? ?? 'N/A',
          ingredients: row['ingredients'] as String? ?? 'Not available',
          allergens: allergens,
          nutritionInfo: nutritionInfo,
          size: row['size'] as String?,
          isFood: (row['isFood'] as int? ?? 1) == 1,
          honestTake: row['honestTake'] as String?,
          shelfLife: row['shelfLife'] as String?,
          usageInstructions: row['usageInstructions'] as String?,
          netQuantity: row['netQuantity'] as String?,
          timestamp: timestamp,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Deletes a specific scan from local history
  Future<void> deleteScan(String id) async {
    try {
      final db = await database;
      await db.delete('scans', where: 'id = ?', whereArgs: [id]);
    } catch (_) {}
  }

  /// Clears all local scans
  Future<void> clearHistory() async {
    try {
      final db = await database;
      await db.delete('scans');
    } catch (_) {}
  }
}

final localHistoryServiceProvider = Provider<LocalHistoryService>((ref) {
  return LocalHistoryService();
});
