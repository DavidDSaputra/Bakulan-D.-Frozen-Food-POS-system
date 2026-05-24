import 'package:flutter/material.dart';

import '../models/product.dart';
import '../models/sale_item.dart';

class CartProvider extends ChangeNotifier {
  final List<SaleItem> _items = [];

  List<SaleItem> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  int get totalQty => _items.fold(0, (sum, item) => sum + item.qty);
  int get totalPrice => _items.fold(0, (sum, item) => sum + item.subtotal);

  void addProduct(Product product) {
    if (product.stok <= 0) throw Exception('Stok ${product.namaBarang} habis');

    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index == -1) {
      _items.add(SaleItem(product: product, qty: 1));
    } else {
      final current = _items[index];
      if (current.qty + 1 > product.stok) {
        throw Exception('Stok ${product.namaBarang} tidak mencukupi');
      }
      _items[index] = current.copyWith(qty: current.qty + 1);
    }
    notifyListeners();
  }

  void updateQty(String productId, int qty) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index == -1) return;

    if (qty <= 0) {
      _items.removeAt(index);
    } else {
      final item = _items[index];
      if (qty > item.product.stok) {
        throw Exception('Qty melebihi stok tersedia');
      }
      _items[index] = item.copyWith(qty: qty);
    }
    notifyListeners();
  }

  void remove(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
