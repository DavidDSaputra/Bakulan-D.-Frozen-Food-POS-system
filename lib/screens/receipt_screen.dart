import 'package:flutter/material.dart';

import '../models/sale_item.dart';
import '../utils/formatters.dart';
import '../utils/snackbar.dart';

class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({
    super.key,
    required this.items,
    required this.method,
    required this.paid,
  });

  final List<SaleItem> items;
  final String method;
  final int paid;

  int get total => items.fold(0, (sum, item) => sum + item.subtotal);

  @override
  Widget build(BuildContext context) {
    final change = method == 'cash' ? paid - total : 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Struk Transaksi')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 54,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Bakulan D. Frozen',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(AppFormatters.date(DateTime.now())),
                    const Divider(height: 30),
                    for (final item in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.product.namaBarang} x${item.qty}',
                              ),
                            ),
                            Text(AppFormatters.rupiah(item.subtotal)),
                          ],
                        ),
                      ),
                    const Divider(height: 30),
                    _receiptRow('Metode', method.toUpperCase()),
                    _receiptRow('Total', AppFormatters.rupiah(total)),
                    if (method == 'cash') ...[
                      _receiptRow('Dibayar', AppFormatters.rupiah(paid)),
                      _receiptRow('Kembali', AppFormatters.rupiah(change)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => showAppSnackBar(
                context,
                'Struk sederhana siap dicetak atau ditunjukkan ke pelanggan',
              ),
              icon: const Icon(Icons.print_rounded),
              label: const Text('Cetak Struk'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Kembali ke Kasir'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
