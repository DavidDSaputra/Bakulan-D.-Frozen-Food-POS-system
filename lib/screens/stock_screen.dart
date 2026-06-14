import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/product_tile.dart';
import 'restock_screen.dart';

class StockScreen extends StatelessWidget {
  const StockScreen({super.key});

  Future<void> _showStockDialog(BuildContext context, Product product) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddStockDialog(product: product),
    );
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
                  tooltip: 'Tambah stok',
                  onPressed: () => _showStockDialog(context, product),
                  icon: const Icon(Icons.add_rounded),
                ),
              );
            },
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemCount: products.length,
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RestockScreen()),
          );
        },
        icon: const Icon(Icons.add_box_rounded),
        label: const Text('Tambah Stok'),
      ),
    );
  }
}

class _AddStockDialog extends StatefulWidget {
  const _AddStockDialog({required this.product});

  final Product product;

  @override
  State<_AddStockDialog> createState() => _AddStockDialogState();
}

class _AddStockDialogState extends State<_AddStockDialog>
    with SingleTickerProviderStateMixin {
  final _qtyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorText;
  bool _isSaving = false;
  bool _success = false;
  int _qtyAdded = 0;
  late final AnimationController _successController;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final qty = int.tryParse(_qtyController.text.trim()) ?? 0;
    if (qty <= 0) {
      setState(() => _errorText = 'Qty harus lebih dari 0');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      final userId = context.read<AuthProvider>().user?.id ?? '-';
      await context.read<ProductProvider>().addStock(
        widget.product,
        qty,
        userId,
      );
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _success = true;
        _qtyAdded = qty;
      });
      await _successController.forward(from: 0);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorText = 'Gagal menambah stok';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _success
                ? _SuccessContent(
                    key: const ValueKey('success'),
                    product: widget.product,
                    qtyAdded: _qtyAdded,
                    controller: _successController,
                    onClose: () => Navigator.pop(context),
                  )
                : _FormContent(
                    key: const ValueKey('form'),
                    product: widget.product,
                    controller: _qtyController,
                    formKey: _formKey,
                    errorText: _errorText,
                    isSaving: _isSaving,
                    onCancel: () => Navigator.pop(context),
                    onSave: _save,
                  ),
          ),
        ),
      ),
    );
  }
}

class _FormContent extends StatelessWidget {
  const _FormContent({
    super.key,
    required this.product,
    required this.controller,
    required this.formKey,
    required this.errorText,
    required this.isSaving,
    required this.onCancel,
    required this.onSave,
  });

  final Product product;
  final TextEditingController controller;
  final GlobalKey<FormState> formKey;
  final String? errorText;
  final bool isSaving;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tambah Stok ${product.namaBarang}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Stok sekarang: ${product.stok}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            validator: (value) {
              final qty = int.tryParse(value?.trim() ?? '');
              if (qty == null) return 'Qty harus berupa angka';
              if (qty <= 0) return 'Qty harus lebih dari 0';
              return null;
            },
            decoration: const InputDecoration(
              labelText: 'Qty ditambahkan',
              prefixIcon: Icon(Icons.add_rounded),
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 10),
            Text(
              errorText!,
              style: TextStyle(
                color: scheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isSaving ? null : onCancel,
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: isSaving ? null : onSave,
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Tambah'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuccessContent extends StatelessWidget {
  const _SuccessContent({
    super.key,
    required this.product,
    required this.qtyAdded,
    required this.controller,
    required this.onClose,
  });

  final Product product;
  final int qtyAdded;
  final AnimationController controller;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 5,
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 18),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 760),
          tween: Tween(begin: .84, end: 1),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(scale: value, child: child);
          },
          child: Image.asset(
            'assets/images/payment_success.png',
            height: 160,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Stok Berhasil Ditambah',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: const Color(0xFF2EAF5D),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${product.namaBarang} +$qtyAdded',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: onClose,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFF5A1F),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
          ),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
