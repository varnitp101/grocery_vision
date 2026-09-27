import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class BarcodeService {
  BarcodeScanner? _scanner;

  BarcodeScanner get _barcodeScanner {
    return _scanner ??= BarcodeScanner(formats: [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upca,
      BarcodeFormat.upce,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.itf,
      BarcodeFormat.qrCode,
    ]);
  }

  /// Scans an image file on disk and returns the raw barcode value if found
  Future<String?> scanImage(String imagePath) async {
    final file = File(imagePath);
    if (!file.existsSync()) return null;

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final List<Barcode> barcodes = await _barcodeScanner.processImage(inputImage);

      for (final barcode in barcodes) {
        final rawValue = barcode.rawValue;
        if (rawValue != null && rawValue.trim().isNotEmpty) {
          return rawValue.trim();
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _scanner?.close();
    _scanner = null;
  }
}

final barcodeServiceProvider = Provider<BarcodeService>((ref) {
  final service = BarcodeService();
  ref.onDispose(() => service.dispose());
  return service;
});
