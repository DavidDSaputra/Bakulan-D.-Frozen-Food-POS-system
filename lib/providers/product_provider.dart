import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/product.dart';
import '../services/firestore_service.dart';

class ProductProvider extends ChangeNotifier {
  final FirestoreService service = FirestoreService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Stream<List<Product>> watchProducts() => service.watchProducts();

  Stream<List<ProductCategory>> watchCategories() => service.watchCategories();

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
