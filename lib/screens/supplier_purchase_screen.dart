import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../models/product.dart';
import '../models/purchase_record.dart';
import '../models/supplier.dart';
import '../providers/auth_provider.dart';
import '../providers/operations_provider.dart';
import '../providers/product_provider.dart';
import '../utils/formatters.dart';
import '../utils/number_input_formatter.dart';
import '../utils/snackbar.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';

class SupplierPurchaseScreen extends StatelessWidget {
  const SupplierPurchaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final actor = context.watch<AuthProvider>().user;
    if (actor == null) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.storefront_rounded,
          title: 'Sesi tidak ditemukan',
          subtitle: 'Silakan login kembali untuk mengelola supplier.',
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Supplier & Pembelian'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.store_rounded), text: 'Supplier'),
              Tab(icon: Icon(Icons.inventory_rounded), text: 'Pembelian'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _SuppliersTab(actor: actor),
            _PurchasesTab(actor: actor),
          ],
        ),
      ),
    );
  }
}

class _SuppliersTab extends StatelessWidget {
  const _SuppliersTab({required this.actor});

  final AppUser actor;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Supplier>>(
      stream: context.read<OperationsProvider>().watchSuppliers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const AppLoadingIndicator();
        final suppliers = snapshot.data!;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            FilledButton.icon(
              onPressed: () => _showAddSupplierSheet(context, actor),
              icon: const Icon(Icons.add_business_rounded),
              label: const Text('Tambah Supplier'),
            ),
            const SizedBox(height: 16),
            if (suppliers.isEmpty)
              const SizedBox(
                height: 280,
                child: EmptyState(
                  icon: Icons.storefront_outlined,
                  title: 'Belum ada supplier',
                  subtitle:
                      'Tambahkan supplier agar pembelian stok lebih rapi.',
                ),
              )
            else
              for (final supplier in suppliers) ...[
                _SupplierTile(supplier: supplier),
                const SizedBox(height: 10),
              ],
          ],
        );
      },
    );
  }
}

class _PurchasesTab extends StatelessWidget {
  const _PurchasesTab({required this.actor});

  final AppUser actor;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Supplier>>(
      stream: context.read<OperationsProvider>().watchSuppliers(),
      builder: (context, supplierSnapshot) {
        return StreamBuilder<List<Product>>(
          stream: context.read<ProductProvider>().watchProducts(),
          builder: (context, productSnapshot) {
            return StreamBuilder<List<PurchaseRecord>>(
              stream: context.read<OperationsProvider>().watchPurchaseRecords(
                limit: 80,
              ),
              builder: (context, purchaseSnapshot) {
                if (!purchaseSnapshot.hasData || !productSnapshot.hasData) {
                  return const AppLoadingIndicator();
                }

                final suppliers = supplierSnapshot.data ?? const <Supplier>[];
                final products = productSnapshot.data!;
                final purchases = purchaseSnapshot.data!;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    FilledButton.icon(
                      onPressed: suppliers.isEmpty || products.isEmpty
                          ? null
                          : () => _showRecordPurchaseSheet(
                              context,
                              actor: actor,
                              suppliers: suppliers,
                              products: products,
                            ),
                      icon: const Icon(Icons.add_shopping_cart_rounded),
                      label: const Text('Catat Pembelian'),
                    ),
                    if (suppliers.isEmpty || products.isEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        suppliers.isEmpty
                            ? 'Tambahkan supplier dulu sebelum mencatat pembelian.'
                            : 'Tambahkan barang dulu sebelum mencatat pembelian.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (purchases.isEmpty)
                      const SizedBox(
                        height: 280,
                        child: EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'Belum ada pembelian',
                          subtitle:
                              'Catatan pembelian supplier akan muncul di sini.',
                        ),
                      )
                    else
                      for (final purchase in purchases) ...[
                        _PurchaseTile(purchase: purchase),
                        const SizedBox(height: 10),
                      ],
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _SupplierTile extends StatelessWidget {
  const _SupplierTile({required this.supplier});

  final Supplier supplier;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              supplier.name,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            _InfoLine(
              icon: Icons.call_rounded,
              label: supplier.phone.trim().isEmpty ? '-' : supplier.phone,
            ),
            const SizedBox(height: 6),
            _InfoLine(
              icon: Icons.location_on_outlined,
              label: supplier.address.trim().isEmpty ? '-' : supplier.address,
            ),
            if (supplier.note.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                supplier.note,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PurchaseTile extends StatelessWidget {
  const _PurchaseTile({required this.purchase});

  final PurchaseRecord purchase;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    purchase.productName,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  AppFormatters.rupiah(purchase.totalCost),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${purchase.supplierName} - ${AppFormatters.date(purchase.timestamp)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _PurchaseChip(
                  label: 'Qty',
                  value: AppFormatters.number(purchase.qty),
                ),
                _PurchaseChip(
                  label: 'Harga modal',
                  value: AppFormatters.rupiah(purchase.unitCost),
                ),
                _PurchaseChip(label: 'Petugas', value: purchase.userName),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseChip extends StatelessWidget {
  const _PurchaseChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _showAddSupplierSheet(BuildContext context, AppUser actor) async {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final noteController = TextEditingController();

  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final bottom = MediaQuery.viewInsetsOf(sheetContext).bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, bottom + 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tambah Supplier',
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama supplier',
                  prefixIcon: Icon(Icons.store_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telepon',
                  prefixIcon: Icon(Icons.call_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Alamat',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Catatan',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(sheetContext, true),
                child: const Text('Simpan Supplier'),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (confirmed != true) {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    noteController.dispose();
    return;
  }

  final name = nameController.text.trim();
  final phone = phoneController.text.trim();
  final address = addressController.text.trim();
  final note = noteController.text.trim();
  nameController.dispose();
  phoneController.dispose();
  addressController.dispose();
  noteController.dispose();
  if (!context.mounted) return;

  if (name.isEmpty) {
    showAppSnackBar(context, 'Nama supplier wajib diisi', isError: true);
    return;
  }

  try {
    await context.read<OperationsProvider>().addSupplier(
      supplier: Supplier(
        id: '',
        name: name,
        phone: phone,
        address: address,
        note: note,
      ),
      actor: actor,
    );
    if (context.mounted) {
      showAppSnackBar(context, 'Supplier berhasil ditambahkan');
    }
  } catch (error) {
    if (context.mounted) {
      showAppSnackBar(
        context,
        error.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    }
  }
}

Future<void> _showRecordPurchaseSheet(
  BuildContext context, {
  required AppUser actor,
  required List<Supplier> suppliers,
  required List<Product> products,
}) async {
  Supplier selectedSupplier = suppliers.first;
  Product selectedProduct = products.first;
  final qtyController = TextEditingController();
  final priceController = TextEditingController();

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final bottom = MediaQuery.viewInsetsOf(sheetContext).bottom;
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, bottom + 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Catat Pembelian',
                    style: Theme.of(sheetContext).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Supplier>(
                    initialValue: selectedSupplier,
                    decoration: const InputDecoration(
                      labelText: 'Supplier',
                      prefixIcon: Icon(Icons.store_rounded),
                    ),
                    items: suppliers
                        .map(
                          (supplier) => DropdownMenuItem(
                            value: supplier,
                            child: Text(supplier.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setSheetState(() => selectedSupplier = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Product>(
                    initialValue: selectedProduct,
                    decoration: const InputDecoration(
                      labelText: 'Barang',
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
                    onChanged: (value) {
                      if (value == null) return;
                      setSheetState(() => selectedProduct = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandSeparatorInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Qty pembelian',
                      prefixIcon: Icon(Icons.numbers_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandSeparatorInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Harga modal per item',
                      prefixIcon: Icon(Icons.payments_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.pop(sheetContext, true),
                    child: const Text('Simpan Pembelian'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  final qty = AppFormatters.parseNumberInput(qtyController.text) ?? 0;
  final unitCost = AppFormatters.parseNumberInput(priceController.text) ?? 0;
  qtyController.dispose();
  priceController.dispose();
  if (result != true) return;
  if (!context.mounted) return;

  try {
    await context.read<OperationsProvider>().recordPurchase(
      supplier: selectedSupplier,
      product: selectedProduct,
      qty: qty,
      unitCost: unitCost,
      actor: actor,
    );
    if (context.mounted) showAppSnackBar(context, 'Pembelian berhasil dicatat');
  } catch (error) {
    if (context.mounted) {
      showAppSnackBar(
        context,
        error.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    }
  }
}
