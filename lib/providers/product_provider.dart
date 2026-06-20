import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';
import '../models/app_user.dart';
import '../services/firestore_service.dart';

class ProductProvider extends ChangeNotifier {
  final FirestoreService service = FirestoreService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Stream<List<Product>> watchProducts() => service.watchProducts();

  Stream<List<Product>> watchActiveProducts() => service.watchActiveProducts();

  Stream<List<ProductCategory>> watchCategories() => service.watchCategories();

  Stream<List<StockMovement>> watchRestockMovements() =>
      service.watchRestockMovements();

  Stream<List<StockMovement>> watchSalesMovements() =>
      service.watchSalesMovements();

  Stream<List<StockMovement>> watchOpnameMovements() =>
      service.watchOpnameMovements();

  Future<void> saveProduct(
    Product product, {
    required bool isEdit,
    required AppUser actor,
  }) async {
    _setLoading(true);
    try {
      if (isEdit) {
        await service.updateProduct(product: product, actor: actor);
      } else {
        await service.addProduct(product: product, actor: actor);
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteProduct(Product product, AppUser actor) async {
    _setLoading(true);
    try {
      await service.deleteProduct(product: product, actor: actor);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateStock(String productId, int stock) async {
    _setLoading(true);
    try {
      await service.updateStock(productId: productId, stock: stock);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addStock(Product product, int qty, AppUser actor) async {
    _setLoading(true);
    try {
      await service.addStock(product: product, qty: qty, actor: actor);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> reduceStockForOpname(
    Product product,
    int qty,
    String note,
    AppUser actor,
    String proofUrl,
  ) async {
    _setLoading(true);
    try {
      await service.reduceStockForOpname(
        product: product,
        qty: qty,
        note: note,
        actor: actor,
        proofUrl: proofUrl,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProductActive(
    Product product,
    bool isActive,
    AppUser actor,
  ) async {
    _setLoading(true);
    try {
      await service.updateProductActive(
        product: product,
        isActive: isActive,
        actor: actor,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> restock(Product product, int qty, AppUser actor) async {
    _setLoading(true);
    try {
      await service.restockProduct(product: product, qty: qty, actor: actor);
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
