import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/product_provider.dart';
import '../utils/snackbar.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/product_tile.dart';
import 'product_form_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Barang'),
        content: Text('Hapus ${product.namaBarang} dari daftar barang?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await context.read<ProductProvider>().deleteProduct(product.id);
      if (mounted) showAppSnackBar(context, 'Barang berhasil dihapus');
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, 'Gagal menghapus barang', isError: true);
      }
    }
  }

  void _openForm([Product? product]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Product>>(
        stream: context.read<ProductProvider>().watchProducts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const AppLoadingIndicator();

          final query = _searchController.text.trim().toLowerCase();
          final products = snapshot.data!
              .where(
                (product) => product.namaBarang.toLowerCase().contains(query),
              )
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Cari barang frozen food',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              Expanded(
                child: products.isEmpty
                    ? const EmptyState(
                        icon: Icons.inventory_2_rounded,
                        title: 'Barang belum tersedia',
                        subtitle:
                            'Tambahkan barang untuk mulai mengelola stok.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return ProductTile(
                            product: product,
                            onTap: () => _openForm(product),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') _openForm(product);
                                if (value == 'delete') _deleteProduct(product);
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Hapus'),
                                ),
                              ],
                            ),
                          );
                        },
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemCount: products.length,
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
      ),
    );
  }
}
