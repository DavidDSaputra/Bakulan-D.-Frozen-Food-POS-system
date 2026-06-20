import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/sale_item.dart';
import '../models/sales_invoice.dart';
import '../models/sales_transaction.dart';
import '../services/firestore_service.dart';

class SalesProvider extends ChangeNotifier {
  final FirestoreService service = FirestoreService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Stream<List<SalesTransaction>> watchTransactions({int? limit}) {
    return service.watchTransactions(limit: limit);
  }

  Stream<List<SalesInvoice>> watchInvoices({int? limit}) {
    return service.watchInvoices(limit: limit);
  }

  Stream<List<SalesTransaction>> watchInvoiceItems(String invoiceId) {
    return service.watchInvoiceItems(invoiceId);
  }

  Future<void> processSale({
    required List<SaleItem> items,
    required String metodePembayaran,
    required AppUser actor,
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
        actor: actor,
        paymentProofUrl: paymentProofUrl,
        paymentAccountName: paymentAccountName,
        paymentAccountNumber: paymentAccountNumber,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> returnInvoiceItem({
    required SalesInvoice invoice,
    required SalesTransaction item,
    required int qty,
    required String note,
    required AppUser actor,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await service.returnInvoiceItem(
        invoice: invoice,
        item: item,
        qty: qty,
        note: note,
        actor: actor,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelInvoice({
    required SalesInvoice invoice,
    required List<SalesTransaction> items,
    required String note,
    required AppUser actor,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await service.cancelInvoice(
        invoice: invoice,
        items: items,
        note: note,
        actor: actor,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
