import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sale_item.dart';
import '../models/transfer_payment_option.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/sales_provider.dart';
import '../utils/formatters.dart';
import '../utils/snackbar.dart';
import '../widgets/app_button.dart';
import 'receipt_screen.dart';
import 'transfer_proof_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.items});

  final List<SaleItem> items;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _cashController = TextEditingController();
  String _method = 'cash';
  TransferPaymentOption _transferOption = virtualAccountOptions.first;

  int get _total => widget.items.fold(0, (sum, item) => sum + item.subtotal);

  String get _paymentMethodLabel {
    if (_method != 'transfer') return _method;
    return 'Transfer ${_transferOption.shortName}';
  }

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

    if (_method == 'transfer') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TransferProofScreen(
            items: widget.items,
            method: _paymentMethodLabel,
            option: _transferOption,
          ),
        ),
      );
      return;
    }

    final userId = context.read<AuthProvider>().user?.id ?? '-';
    try {
      await context.read<SalesProvider>().processSale(
        items: widget.items,
        metodePembayaran: _paymentMethodLabel,
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
            method: _paymentMethodLabel,
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
          if (_method == 'transfer') ...[
            _TransferPaymentPicker(
              selected: _transferOption,
              onChanged: (option) => setState(() => _transferOption = option),
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

class _TransferPaymentPicker extends StatelessWidget {
  const _TransferPaymentPicker({
    required this.selected,
    required this.onChanged,
  });

  final TransferPaymentOption selected;
  final ValueChanged<TransferPaymentOption> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TransferSection(
          title: 'Virtual Account',
          options: virtualAccountOptions,
          selected: selected,
          onChanged: onChanged,
        ),
        const SizedBox(height: 14),
        _TransferSection(
          title: 'E-Wallet',
          options: eWalletOptions,
          selected: selected,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _TransferSection extends StatelessWidget {
  const _TransferSection({
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String title;
  final List<TransferPaymentOption> options;
  final TransferPaymentOption selected;
  final ValueChanged<TransferPaymentOption> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final useTwoColumns = constraints.maxWidth >= 520;
            if (!useTwoColumns) {
              return Column(
                children: [
                  for (var i = 0; i < options.length; i++) ...[
                    _TransferOptionTile(
                      option: options[i],
                      isSelected: options[i].id == selected.id,
                      onTap: () => onChanged(options[i]),
                    ),
                    if (i != options.length - 1) const SizedBox(height: 10),
                  ],
                ],
              );
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: options.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                mainAxisExtent: 74,
              ),
              itemBuilder: (context, index) {
                final option = options[index];
                return _TransferOptionTile(
                  option: option,
                  isSelected: option.id == selected.id,
                  onTap: () => onChanged(option),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _TransferOptionTile extends StatelessWidget {
  const _TransferOptionTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final TransferPaymentOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final borderColor = isSelected ? scheme.primary : scheme.outlineVariant;
    final background = isSelected
        ? scheme.primaryContainer.withValues(alpha: .52)
        : scheme.surfaceContainerLowest;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: isSelected ? 1.4 : 1),
          ),
          child: Row(
            children: [
              _BrandMark(option: option),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.typeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.accountNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.check_circle_rounded,
                  color: scheme.primary,
                  size: 18,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.option});

  final TransferPaymentOption option;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: option.color,
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(
            color: option.color.withValues(alpha: .22),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Text(
            option.logoText,
            style: TextStyle(
              color: option.foreground,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}
