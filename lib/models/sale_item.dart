import 'product.dart';

class SaleItem {
  const SaleItem({required this.product, required this.qty});

  final Product product;
  final int qty;

  int get subtotal => product.harga * qty;

  SaleItem copyWith({Product? product, int? qty}) {
    return SaleItem(product: product ?? this.product, qty: qty ?? this.qty);
  }
}
