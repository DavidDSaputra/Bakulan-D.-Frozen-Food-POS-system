import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../utils/category_helpers.dart';
import '../utils/formatters.dart';
import '../utils/snackbar.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/product_tile.dart';
import 'payment_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  static const _cartBarHeight = 138.0;
  final _searchController = TextEditingController();
  String? _selectedCategoryId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addToCart(Product product) {
    try {
      context.read<CartProvider>().addProduct(product);
      showAppSnackBar(
        context,
        '${product.namaBarang} ditambahkan',
        bottomMargin: _cartBarHeight + 18,
      );
    } catch (error) {
      showAppSnackBar(
        context,
        error.toString().replaceAll('Exception: ', ''),
        isError: true,
        bottomMargin: _cartBarHeight + 18,
      );
    }
  }

  void _goToPayment() {
    final cart = context.read<CartProvider>();
    if (cart.isEmpty) {
      showAppSnackBar(context, 'Keranjang masih kosong', isError: true);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PaymentScreen(items: cart.items)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Cari barang untuk dijual',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ),
        StreamBuilder(
          stream: context.read<ProductProvider>().watchCategories(),
          builder: (context, snapshot) {
            return CategoryFilterBar(
              categories: CategoryHelpers.merge(snapshot.data ?? const []),
              selectedCategoryId: _selectedCategoryId,
              onChanged: (value) => setState(() => _selectedCategoryId = value),
            );
          },
        ),
        const SizedBox(height: 10),
        Expanded(
          child: StreamBuilder<List<Product>>(
            stream: context.read<ProductProvider>().watchProducts(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const AppLoadingIndicator();

              final query = _searchController.text.trim().toLowerCase();
              final products = snapshot.data!
                  .where(
                    (product) =>
                        product.namaBarang.toLowerCase().contains(query),
                  )
                  .where(
                    (product) =>
                        _selectedCategoryId == null ||
                        product.kategoriId == _selectedCategoryId,
                  )
                  .toList();

              if (products.isEmpty) {
                return const EmptyState(
                  icon: Icons.point_of_sale_rounded,
                  title: 'Barang tidak ditemukan',
                  subtitle:
                      'Pastikan barang sudah ditambahkan pada menu Barang.',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ProductTile(
                    product: product,
                    trailing: IconButton.filled(
                      tooltip: 'Tambah ke keranjang',
                      onPressed: product.isOutOfStock
                          ? null
                          : () => _addToCart(product),
                      icon: const Icon(Icons.add_shopping_cart_rounded),
                    ),
                  );
                },
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemCount: products.length,
              );
            },
          ),
        ),
        Consumer<CartProvider>(
          builder: (context, cart, _) {
            final scheme = Theme.of(context).colorScheme;
            return SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest,
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withValues(alpha: .08),
                      offset: const Offset(0, -12),
                      blurRadius: 24,
                    ),
                  ],
                  border: Border(
                    top: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: .48),
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${cart.totalQty} item',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          AppFormatters.rupiah(cart.totalPrice),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 54,
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: cart.isEmpty ? null : _goToPayment,
                        icon: const Icon(Icons.payments_rounded),
                        label: const Text('Lanjut Pembayaran'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
