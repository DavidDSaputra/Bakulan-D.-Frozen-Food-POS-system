import 'package:flutter/material.dart';

import '../models/sale_item.dart';
import '../models/sales_transaction.dart';
import '../services/firestore_service.dart';

class SalesProvider extends ChangeNotifier {
  final FirestoreService service = FirestoreService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  final Map<int, Stream<List<SalesTransaction>>> _limitedTransactionStreams =
      {};
  late final Stream<List<SalesTransaction>> _transactionsStream = service
      .watchTransactions();

  Stream<List<SalesTransaction>> watchTransactions({int? limit}) {
    if (limit == null) return _transactionsStream;

    return _limitedTransactionStreams.putIfAbsent(
      limit,
      () => service.watchTransactions(limit: limit),
    );
  }

  Future<void> processSale({
    required List<SaleItem> items,
    required String metodePembayaran,
    required String userId,
    String? paymentProofUrl,
    String? paymentAccountName,
    String? paymentAccountNumber,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await service.processSale(
        items: items,
        metodePembayaran: metodePembayaran,
        userId: userId,
        paymentProofUrl: paymentProofUrl,
        paymentAccountName: paymentAccountName,
        paymentAccountNumber: paymentAccountNumber,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
