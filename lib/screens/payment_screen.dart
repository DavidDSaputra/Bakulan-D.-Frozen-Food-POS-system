import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sale_item.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/sales_provider.dart';
import '../utils/formatters.dart';
import '../utils/snackbar.dart';
import '../widgets/app_button.dart';
import 'receipt_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.items});

  final List<SaleItem> items;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _cashController = TextEditingController();
  String _method = 'cash';

  int get _total => widget.items.fold(0, (sum, item) => sum + item.subtotal);

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    final paid = int.tryParse(_cashController.text.trim()) ?? 0;
    if (_method == 'cash' && paid < _total) {
      showAppSnackBar(context, 'Nominal cash kurang dari total', isError: true);
      return;
    }

    final userId = context.read<AuthProvider>().user?.id ?? '-';
    try {
      await context.read<SalesProvider>().processSale(
        items: widget.items,
        metodePembayaran: _method,
        userId: userId,
      );
      if (!mounted) return;
      context.read<CartProvider>().clear();
      showAppSnackBar(context, 'Transaksi berhasil');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptScreen(
            items: widget.items,
            method: _method,
            paid: _method == 'cash' ? paid : _total,
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        showAppSnackBar(
          context,
          error.toString().replaceAll('Exception: ', ''),
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ringkasan Belanja',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final item in widget.items)
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
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Total',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Text(
                        AppFormatters.rupiah(_total),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Metode Pembayaran',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'cash',
                label: Text('Cash'),
                icon: Icon(Icons.payments_rounded),
              ),
              ButtonSegment(
                value: 'qris',
                label: Text('QRIS'),
                icon: Icon(Icons.qr_code_rounded),
              ),
              ButtonSegment(
                value: 'transfer',
                label: Text('Transfer'),
                icon: Icon(Icons.account_balance_rounded),
              ),
            ],
            selected: {_method},
            onSelectionChanged: (value) =>
                setState(() => _method = value.first),
          ),
          const SizedBox(height: 14),
          if (_method == 'cash')
            TextField(
              controller: _cashController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Uang diterima',
                prefixIcon: Icon(Icons.attach_money_rounded),
              ),
            ),
          if (_method == 'qris') ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.qr_code_2_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Scan QRIS Bakulan D. Frozen',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/qris.jpeg',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Consumer<SalesProvider>(
            builder: (context, sales, _) {
              return AppButton(
                label: 'Proses Pembayaran',
                icon: Icons.check_circle_rounded,
                isLoading: sales.isLoading,
                onPressed: _processPayment,
              );
            },
          ),
        ],
      ),
    );
  }
}
