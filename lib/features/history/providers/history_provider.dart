import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/product_model.dart';
import '../../../services/firestore_service.dart';


class HistoryEntry {
  final Product product;
  final DateTime? scannedAt;

  HistoryEntry({required this.product, this.scannedAt});
}



final historyProvider = FutureProvider<List<HistoryEntry>>((ref) async {
  final rawScans = await FirestoreService().getRecentScans();
  return rawScans.map((scan) {
    return HistoryEntry(
      product: scan['product'] as Product,
      scannedAt: scan['scannedAt'] as DateTime?,
    );
  }).toList();
});
