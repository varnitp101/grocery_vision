import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/product_model.dart';
import '../../../services/firestore_service.dart';
import '../../../services/local_history_service.dart';

class HistoryEntry {
  final Product product;
  final DateTime? scannedAt;

  HistoryEntry({required this.product, this.scannedAt});
}

final historyProvider = FutureProvider<List<HistoryEntry>>((ref) async {
  // First load from local SQLite storage
  final localHistory = ref.read(localHistoryServiceProvider);
  final localScans = await localHistory.getScans();

  if (localScans.isNotEmpty) {
    return localScans
        .map((p) => HistoryEntry(product: p, scannedAt: p.timestamp))
        .toList();
  }

  // Fallback to Firestore remote history
  final rawScans = await FirestoreService().getRecentScans();
  return rawScans.map((scan) {
    return HistoryEntry(
      product: scan['product'] as Product,
      scannedAt: scan['scannedAt'] as DateTime?,
    );
  }).toList();
});
