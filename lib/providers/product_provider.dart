import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';
import '../services/firestore_service.dart';

class ProductProvider extends ChangeNotifier {
  final FirestoreService service = FirestoreService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  late final Stream<List<Product>> _productsStream = service.watchProducts();
  late final Stream<List<Product>> _activeProductsStream = _productsStream.map(
    (products) => products.where((product) => product.isActive).toList(),
  );
  late final Stream<List<ProductCategory>> _categoriesStream = service
      .watchCategories();
  late final Stream<List<StockMovement>> _restockMovementsStream = service
      .watchRestockMovements();
  late final Stream<List<StockMovement>> _salesMovementsStream = service
      .watchSalesMovements();
  late final Stream<List<StockMovement>> _opnameMovementsStream = service
      .watchOpnameMovements();

  Stream<List<Product>> watchProducts() => _productsStream;

  Stream<List<Product>> watchActiveProducts() => _activeProductsStream;

  Stream<List<ProductCategory>> watchCategories() => _categoriesStream;

  Stream<List<StockMovement>> watchRestockMovements() =>
      _restockMovementsStream;

  Stream<List<StockMovement>> watchSalesMovements() => _salesMovementsStream;

  Stream<List<StockMovement>> watchOpnameMovements() => _opnameMovementsStream;

  Future<void> saveProduct(Product product, {required bool isEdit}) async {
    _setLoading(true);
    try {
      if (isEdit) {
        await service.updateProduct(product);
      } else {
        await service.addProduct(product);
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteProduct(String id) async {
    _setLoading(true);
    try {
      await service.deleteProduct(id);
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

  Future<void> addStock(Product product, int qty, String userId) async {
    _setLoading(true);
    try {
      await service.addStock(product: product, qty: qty, userId: userId);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> reduceStockForOpname(
    Product product,
    int qty,
    String note,
    String userId,
  ) async {
    _setLoading(true);
    try {
      await service.reduceStockForOpname(
        product: product,
        qty: qty,
        note: note,
        userId: userId,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProductActive(String productId, bool isActive) async {
    _setLoading(true);
    try {
      await service.updateProductActive(
        productId: productId,
        isActive: isActive,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> restock(Product product, int qty, String userId) async {
    _setLoading(true);
    try {
      await service.restockProduct(product: product, qty: qty, userId: userId);
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
