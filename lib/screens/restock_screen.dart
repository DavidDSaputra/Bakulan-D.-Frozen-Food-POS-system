import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../utils/formatters.dart';
import '../utils/number_input_formatter.dart';
import '../utils/snackbar.dart';
import '../utils/validators.dart';
import '../widgets/app_button.dart';
import '../widgets/loading_indicator.dart';

class RestockScreen extends StatelessWidget {
  const RestockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Stok')),
      body: StreamBuilder<List<Product>>(
        stream: context.read<ProductProvider>().watchProducts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const AppLoadingIndicator();
          return _RestockForm(products: snapshot.data!);
        },
      ),
    );
  }
}

class _RestockForm extends StatefulWidget {
  const _RestockForm({required this.products});

  final List<Product> products;

  @override
  State<_RestockForm> createState() => _RestockFormState();
}

class _RestockFormState extends State<_RestockForm> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();
  String? _selectedProductId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedProductId == null) {
      showAppSnackBar(context, 'Pilih barang terlebih dahulu', isError: true);
      return;
    }

    final selectedIndex = widget.products.indexWhere(
      (product) => product.id == _selectedProductId,
    );
    if (selectedIndex == -1) {
      showAppSnackBar(context, 'Barang tidak ditemukan', isError: true);
      return;
    }

    final qty = AppFormatters.parseNumberInput(_qtyController.text) ?? 0;
    if (qty <= 0) {
      showAppSnackBar(context, 'Qty harus lebih dari 0', isError: true);
      return;
    }
    final actor = context.read<AuthProvider>().user;
    if (actor == null) {
      showAppSnackBar(context, 'Sesi pengguna tidak ditemukan', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await context.read<ProductProvider>().restock(
        widget.products[selectedIndex],
        qty,
        actor,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      showAppSnackBar(context, 'Gagal menambah stok', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedProductId,
            decoration: const InputDecoration(
              labelText: 'Pilih Barang',
              prefixIcon: Icon(Icons.inventory_2_rounded),
            ),
            items: widget.products
                .map(
                  (product) => DropdownMenuItem(
                    value: product.id,
                    child: Text(product.namaBarang),
                  ),
                )
                .toList(),
            onChanged: (productId) =>
                setState(() => _selectedProductId = productId),
            validator: (value) => value == null ? 'Barang wajib dipilih' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _qtyController,
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandSeparatorInputFormatter()],
            validator: (value) =>
                Validators.positiveNumber(value, field: 'Qty restock'),
            decoration: const InputDecoration(
              labelText: 'Qty ditambahkan',
              prefixIcon: Icon(Icons.add_rounded),
            ),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Simpan Tambahan',
            icon: Icons.save_alt_rounded,
            isLoading: _isSubmitting,
            onPressed: _save,
          ),
          const SizedBox(height: 8),
          Text(
            'Stok akan ditambah dari jumlah yang ada sekarang, bukan diganti.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
