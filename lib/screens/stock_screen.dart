import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/product_provider.dart';
import '../utils/snackbar.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/product_tile.dart';
import 'restock_screen.dart';

class StockScreen extends StatelessWidget {
  const StockScreen({super.key});

  Future<void> _showStockDialog(BuildContext context, Product product) async {
    final controller = TextEditingController(text: product.stok.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Stok ${product.namaBarang}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Jumlah stok terbaru',
            prefixIcon: Icon(Icons.inventory_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, int.tryParse(controller.text)),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result == null || result < 0 || !context.mounted) return;
    try {
      await context.read<ProductProvider>().updateStock(product.id, result);
      if (context.mounted) showAppSnackBar(context, 'Stok berhasil diperbarui');
    } catch (_) {
      if (context.mounted) {
        showAppSnackBar(context, 'Gagal memperbarui stok', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Product>>(
        stream: context.read<ProductProvider>().watchProducts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const AppLoadingIndicator();
          final products = snapshot.data!;

          if (products.isEmpty) {
            return const EmptyState(
              icon: Icons.warehouse_rounded,
              title: 'Data stok kosong',
              subtitle: 'Tambahkan barang lebih dulu pada menu Barang.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductTile(
                product: product,
                onTap: () => _showStockDialog(context, product),
                trailing: IconButton.filledTonal(
                  tooltip: 'Update stok',
                  onPressed: () => _showStockDialog(context, product),
                  icon: const Icon(Icons.edit_rounded),
                ),
              );
            },
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemCount: products.length,
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RestockScreen()),
        ),
        icon: const Icon(Icons.add_box_rounded),
        label: const Text('Barang Masuk'),
      ),
    );
  }
}
