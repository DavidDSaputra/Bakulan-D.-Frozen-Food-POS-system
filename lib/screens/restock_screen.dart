import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../utils/snackbar.dart';
import '../utils/validators.dart';
import '../widgets/app_button.dart';
import '../widgets/loading_indicator.dart';

class RestockScreen extends StatefulWidget {
  const RestockScreen({super.key});

  @override
  State<RestockScreen> createState() => _RestockScreenState();
}

class _RestockScreenState extends State<RestockScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();
  Product? _selectedProduct;

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedProduct == null) {
      showAppSnackBar(context, 'Pilih barang terlebih dahulu', isError: true);
      return;
    }

    final userId = context.read<AuthProvider>().user?.id ?? '-';
    try {
      await context.read<ProductProvider>().restock(
        _selectedProduct!,
        int.parse(_qtyController.text.trim()),
        userId,
      );
      if (!mounted) return;
      showAppSnackBar(context, 'Barang masuk berhasil disimpan');
      Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, 'Gagal menyimpan barang masuk', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Input Barang Masuk')),
      body: StreamBuilder<List<Product>>(
        stream: context.read<ProductProvider>().watchProducts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const AppLoadingIndicator();
          final products = snapshot.data!;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<Product>(
                  initialValue: _selectedProduct,
                  decoration: const InputDecoration(
                    labelText: 'Pilih Barang',
                    prefixIcon: Icon(Icons.inventory_2_rounded),
                  ),
                  items: products
                      .map(
                        (product) => DropdownMenuItem(
                          value: product,
                          child: Text(product.namaBarang),
                        ),
                      )
                      .toList(),
                  onChanged: (product) =>
                      setState(() => _selectedProduct = product),
                  validator: (value) =>
                      value == null ? 'Barang wajib dipilih' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _qtyController,
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      Validators.positiveNumber(value, field: 'Qty restock'),
                  decoration: const InputDecoration(
                    labelText: 'Qty Barang Masuk',
                    prefixIcon: Icon(Icons.add_rounded),
                  ),
                ),
                const SizedBox(height: 24),
                Consumer<ProductProvider>(
                  builder: (context, provider, _) {
                    return AppButton(
                      label: 'Simpan Restock',
                      icon: Icons.save_alt_rounded,
                      isLoading: provider.isLoading,
                      onPressed: _save,
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
