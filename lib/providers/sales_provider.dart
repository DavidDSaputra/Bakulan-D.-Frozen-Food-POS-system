import 'package:flutter/material.dart';

import '../models/sale_item.dart';
import '../models/sales_transaction.dart';
import '../services/firestore_service.dart';

class SalesProvider extends ChangeNotifier {
  final FirestoreService service = FirestoreService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Stream<List<SalesTransaction>> watchTransactions() {
    return service.watchTransactions();
  }

  Future<void> processSale({
    required List<SaleItem> items,
    required String metodePembayaran,
    required String userId,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await service.processSale(
        items: items,
        metodePembayaran: metodePembayaran,
        userId: userId,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
