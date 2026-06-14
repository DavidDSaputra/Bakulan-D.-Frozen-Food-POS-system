import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sale_item.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../utils/formatters.dart';
import '../utils/snackbar.dart';
import '../widgets/app_button.dart';
import '../widgets/empty_state.dart';
import 'payment_screen.dart';

class BasketScreen extends StatelessWidget {
  const BasketScreen({super.key});

  void _addItem(BuildContext context, Product product) {
    try {
      context.read<CartProvider>().addProduct(product);
    } catch (error) {
      showAppSnackBar(
        context,
        error.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    }
  }

  void _removeItem(BuildContext context, Product product, int currentQty) {
    try {
      context.read<CartProvider>().updateQty(product.id, currentQty - 1);
    } catch (error) {
      showAppSnackBar(
        context,
        error.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    }
  }

  void _goToPayment(BuildContext context, List<SaleItem> items) {
    if (items.isEmpty) {
      showAppSnackBar(context, 'Keranjang masih kosong', isError: true);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PaymentScreen(items: items)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Basket'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Consumer<CartProvider>(
                builder: (context, cart, _) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBDD),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shopping_basket_rounded,
                          size: 18,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${cart.totalQty}',
                          style: TextStyle(
                            color: scheme.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          final items = cart.items;

          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.shopping_basket_rounded,
              title: 'Keranjang masih kosong',
              subtitle: 'Tambahkan barang dulu dari halaman penjualan.',
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Total Products (${cart.totalQty})',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    Text(
                      '${items.length} item',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: items.length,
                  separatorBuilder: (context, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _BasketItemTile(
                      product: item.product,
                      quantity: item.qty,
                      onAdd: () => _addItem(context, item.product),
                      onRemove: () =>
                          _removeItem(context, item.product, item.qty),
                    );
                  },
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SummaryRow(
                          label: 'Subtotal',
                          value: AppFormatters.rupiah(cart.totalPrice),
                        ),
                        const SizedBox(height: 8),
                        _SummaryRow(label: 'Item', value: '${cart.totalQty}'),
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
                              AppFormatters.rupiah(cart.totalPrice),
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: scheme.primary,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          label: 'Checkout',
                          icon: Icons.shopping_cart_checkout_rounded,
                          onPressed: () => _goToPayment(context, items),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BasketItemTile extends StatelessWidget {
  const _BasketItemTile({
    required this.product,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  final Product product;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasImage = product.imageUrl.trim().isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 42,
                height: 42,
                color: const Color(0xFFFFF2EC),
                child: hasImage
                    ? Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.low,
                        gaplessPlayback: true,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.inventory_2_rounded,
                          color: scheme.primary,
                        ),
                      )
                    : Icon(Icons.inventory_2_rounded, color: scheme.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.namaBarang,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE2D6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      AppFormatters.rupiah(product.hargaJual),
                      style: TextStyle(
                        color: scheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _QtyStepper(quantity: quantity, onAdd: onAdd, onRemove: onRemove),
          ],
        ),
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QtyButton(
          icon: Icons.remove_rounded,
          onTap: onRemove,
          background: Colors.white,
          iconColor: const Color(0xFFFF5A1F),
          borderColor: const Color(0xFFFFE2D6),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 24,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 10),
        _QtyButton(
          icon: Icons.add_rounded,
          onTap: onAdd,
          background: const Color(0xFFFF5A1F),
          iconColor: Colors.white,
          borderColor: const Color(0xFFFF5A1F),
        ),
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.icon,
    required this.onTap,
    required this.background,
    required this.iconColor,
    required this.borderColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color background;
  final Color iconColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
