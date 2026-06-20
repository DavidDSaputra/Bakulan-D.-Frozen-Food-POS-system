import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/cashier_shift.dart';
import '../models/product.dart';
import '../models/purchase_record.dart';
import '../models/supplier.dart';
import '../services/firestore_service.dart';

class OperationsProvider extends ChangeNotifier {
  final FirestoreService service = FirestoreService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Stream<List<CashierShift>> watchShiftHistory({int? limit}) {
    return service.watchShiftHistory(limit: limit);
  }

  Stream<CashierShift?> watchActiveShift(String userId) {
    return service.watchActiveShift(userId);
  }

  Stream<List<Supplier>> watchSuppliers() {
    return service.watchSuppliers();
  }

  Stream<List<PurchaseRecord>> watchPurchaseRecords({int? limit}) {
    return service.watchPurchaseRecords(limit: limit);
  }

  Future<void> openShift({
    required AppUser actor,
    required int openingCash,
  }) async {
    _setLoading(true);
    try {
      await service.openShift(actor: actor, openingCash: openingCash);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> closeShift({
    required CashierShift shift,
    required int closingCash,
    required AppUser actor,
  }) async {
    _setLoading(true);
    try {
      await service.closeShift(
        shift: shift,
        closingCash: closingCash,
        actor: actor,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addSupplier({
    required Supplier supplier,
    required AppUser actor,
  }) async {
    _setLoading(true);
    try {
      await service.addSupplier(supplier: supplier, actor: actor);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> recordPurchase({
    required Supplier supplier,
    required Product product,
    required int qty,
    required int unitCost,
    required AppUser actor,
  }) async {
    _setLoading(true);
    try {
      await service.recordPurchase(
        supplier: supplier,
        product: product,
        qty: qty,
        unitCost: unitCost,
        actor: actor,
      );
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
