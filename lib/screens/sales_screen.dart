import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/product.dart';
import '../models/sales_transaction.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../providers/sales_provider.dart';
import '../utils/app_theme.dart';
import '../utils/category_helpers.dart';
import '../utils/formatters.dart';
import '../utils/snackbar.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';
import 'barcode_scanner_screen.dart';
import 'basket_screen.dart';
import 'payment_screen.dart';
import 'transaction_history_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

enum _SalesSortMode { nameAsc, mostSold, leastSold, lowStock, highStock }

class _SalesScreenState extends State<SalesScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategoryId;
  _SalesSortMode _sortMode = _SalesSortMode.nameAsc;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addToCart(Product product) {
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

  void _decrementCart(Product product, int currentQty) {
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

  void _goToPayment() {
    final cart = context.read<CartProvider>();
    if (cart.isEmpty) {
      showAppSnackBar(context, 'Keranjang masih kosong', isError: true);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PaymentScreen(items: cart.items)),
    );
  }

  void _openTransactionHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()),
    );
  }

  Future<void> _openSortSheet() async {
    final selected = await showModalBottomSheet<_SalesSortMode>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Urutkan Barang',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                for (final mode in _SalesSortMode.values)
                  ListTile(
                    onTap: () => Navigator.pop(context, mode),
                    title: Text(_sortLabel(mode)),
                    leading: Icon(_sortIcon(mode)),
                    trailing: mode == _sortMode
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppTheme.brandPrimary,
                          )
                        : null,
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) setState(() => _sortMode = selected);
  }

  Future<void> _openBarcodeScanner(List<Product> products) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (result == null || !mounted) return;

    final code = result.trim().toLowerCase();
    final matched = products.where(
      (product) => product.barcode.trim().toLowerCase() == code,
    );

    if (matched.isNotEmpty) {
      _addToCart(matched.first);
      showAppSnackBar(context, '${matched.first.namaBarang} ditambahkan');
      return;
    }

    _searchController.text = result.trim();
    setState(() {});
    showAppSnackBar(
      context,
      'Barcode tidak ditemukan, hasil scan dimasukkan ke pencarian',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final scheme = Theme.of(context).colorScheme;
    final cartQtyByProductId = {
      for (final item in cart.items) item.product.id: item.qty,
    };

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Penjualan'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _CartBadge(
              count: cart.totalQty,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BasketScreen()),
                );
              },
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<ProductCategory>>(
        stream: context.read<ProductProvider>().watchCategories(),
        builder: (context, categorySnapshot) {
          final categories = CategoryHelpers.merge(
            categorySnapshot.data ?? const [],
          );

          return StreamBuilder<List<SalesTransaction>>(
            stream: context.read<SalesProvider>().watchTransactions(limit: 500),
            builder: (context, trxSnapshot) {
              return StreamBuilder<List<Product>>(
                stream: context.read<ProductProvider>().watchActiveProducts(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const AppLoadingIndicator();
                  }

                  final soldCounts = _soldCounts(trxSnapshot.data ?? const []);
                  final query = _searchController.text.trim().toLowerCase();
                  final products = snapshot.data!
                      .where(
                        (product) =>
                            product.namaBarang.toLowerCase().contains(query) ||
                            product.barcode.toLowerCase().contains(query),
                      )
                      .where(
                        (product) =>
                            _selectedCategoryId == null ||
                            product.kategoriId == _selectedCategoryId,
                      )
                      .toList();
                  _sortProducts(products, soldCounts);

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: _SearchRow(
                          controller: _searchController,
                          scheme: scheme,
                          onChanged: (_) => setState(() {}),
                          onFilter: _openSortSheet,
                          onScan: () => _openBarcodeScanner(snapshot.data!),
                          onHistory: _openTransactionHistory,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _CategoryStrip(
                        categories: categories,
                        selectedCategoryId: _selectedCategoryId,
                        onChanged: (value) =>
                            setState(() => _selectedCategoryId = value),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'All Items',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0,
                                    ),
                              ),
                            ),
                            Text(
                              '${products.length} item',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: products.isEmpty
                            ? const EmptyState(
                                icon: Icons.point_of_sale_rounded,
                                title: 'Barang tidak ditemukan',
                                subtitle:
                                    'Pastikan barang sudah ditambahkan pada menu Barang.',
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  12,
                                ),
                                itemCount: (products.length / 2).ceil(),
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, rowIndex) {
                                  final leftIndex = rowIndex * 2;
                                  final rightIndex = leftIndex + 1;

                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _ProductSlot(
                                          product: products[leftIndex],
                                          cartQtyByProductId:
                                              cartQtyByProductId,
                                          onAdd: _addToCart,
                                          onRemove: _decrementCart,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: rightIndex < products.length
                                            ? _ProductSlot(
                                                product: products[rightIndex],
                                                cartQtyByProductId:
                                                    cartQtyByProductId,
                                                onAdd: _addToCart,
                                                onRemove: _decrementCart,
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                    ],
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToPayment,
        backgroundColor: AppTheme.brandPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.shopping_cart_checkout_rounded),
        label: const Text('Checkout'),
      ),
    );
  }

  Map<String, int> _soldCounts(List<SalesTransaction> transactions) {
    final counts = <String, int>{};
    for (final trx in transactions) {
      if (trx.barangId.isNotEmpty) {
        counts[trx.barangId] = (counts[trx.barangId] ?? 0) + trx.qty;
      }
      counts[trx.namaBarang.toLowerCase()] =
          (counts[trx.namaBarang.toLowerCase()] ?? 0) + trx.qty;
    }
    return counts;
  }

  int _soldCount(Product product, Map<String, int> counts) {
    return counts[product.id] ?? counts[product.namaBarang.toLowerCase()] ?? 0;
  }

  void _sortProducts(List<Product> products, Map<String, int> soldCounts) {
    products.sort((a, b) {
      final nameCompare = a.namaBarang.compareTo(b.namaBarang);
      return switch (_sortMode) {
        _SalesSortMode.nameAsc => nameCompare,
        _SalesSortMode.mostSold => _soldCount(
          b,
          soldCounts,
        ).compareTo(_soldCount(a, soldCounts)),
        _SalesSortMode.leastSold => _soldCount(
          a,
          soldCounts,
        ).compareTo(_soldCount(b, soldCounts)),
        _SalesSortMode.lowStock => a.stok.compareTo(b.stok),
        _SalesSortMode.highStock => b.stok.compareTo(a.stok),
      };
    });
  }

  String _sortLabel(_SalesSortMode mode) {
    return switch (mode) {
      _SalesSortMode.nameAsc => 'Nama A - Z',
      _SalesSortMode.mostSold => 'Terbanyak dibeli',
      _SalesSortMode.leastSold => 'Terdikit dibeli',
      _SalesSortMode.lowStock => 'Stok paling sedikit',
      _SalesSortMode.highStock => 'Stok paling banyak',
    };
  }

  IconData _sortIcon(_SalesSortMode mode) {
    return switch (mode) {
      _SalesSortMode.nameAsc => Icons.sort_by_alpha_rounded,
      _SalesSortMode.mostSold => Icons.trending_up_rounded,
      _SalesSortMode.leastSold => Icons.trending_down_rounded,
      _SalesSortMode.lowStock => Icons.inventory_2_outlined,
      _SalesSortMode.highStock => Icons.inventory_rounded,
    };
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({
    required this.controller,
    required this.scheme,
    required this.onChanged,
    required this.onFilter,
    required this.onScan,
    required this.onHistory,
  });

  final TextEditingController controller;
  final ColorScheme scheme;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilter;
  final VoidCallback onScan;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 46,
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'Search Product Here',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withValues(
                  alpha: .42,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: .28),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: .28),
                  ),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  borderSide: BorderSide(
                    color: AppTheme.brandPrimary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _SquareActionButton(icon: Icons.tune_rounded, onTap: onFilter),
        const SizedBox(width: 8),
        _SquareActionButton(icon: Icons.qr_code_scanner_rounded, onTap: onScan),
        const SizedBox(width: 8),
        _SquareActionButton(icon: Icons.history_rounded, onTap: onHistory),
      ],
    );
  }
}

class _SquareActionButton extends StatelessWidget {
  const _SquareActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Center(child: Icon(icon, size: 22, color: scheme.onSurface)),
        ),
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({
    required this.categories,
    required this.selectedCategoryId,
    required this.onChanged,
  });

  final List<ProductCategory> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _PillChip(
            label: 'All',
            selected: selectedCategoryId == null,
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: 8),
          for (final category in categories) ...[
            _PillChip(
              label: category.namaKategori,
              selected: selectedCategoryId == category.id,
              onTap: () => onChanged(category.id),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _PillChip extends StatelessWidget {
  const _PillChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? AppTheme.brandPrimary : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          constraints: const BoxConstraints(minWidth: 52),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppTheme.brandPrimary : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? Colors.white : scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductSlot extends StatelessWidget {
  const _ProductSlot({
    required this.product,
    required this.cartQtyByProductId,
    required this.onAdd,
    required this.onRemove,
  });

  final Product product;
  final Map<String, int> cartQtyByProductId;
  final void Function(Product product) onAdd;
  final void Function(Product product, int currentQty) onRemove;

  @override
  Widget build(BuildContext context) {
    final qty = cartQtyByProductId[product.id] ?? 0;
    return _ProductCard(
      product: product,
      currentQty: qty,
      onTap: () => onAdd(product),
      onAdd: () => onAdd(product),
      onRemove: () => onRemove(product, qty),
    );
  }
}

class _ProductCard extends StatefulWidget {
  const _ProductCard({
    required this.product,
    required this.currentQty,
    required this.onTap,
    required this.onAdd,
    required this.onRemove,
  });

  final Product product;
  final int currentQty;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _expanded = false;

  @override
  void didUpdateWidget(covariant _ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentQty == 0 && _expanded) {
      _expanded = false;
    }
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = widget.currentQty > 0;
    final hasImage = widget.product.imageUrl.trim().isNotEmpty;

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: selected ? AppTheme.brandSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppTheme.brandPrimary
                : scheme.outlineVariant.withValues(alpha: .35),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .04),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AppTheme.brandSurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: hasImage
                          ? Image.network(
                              widget.product.imageUrl,
                              fit: BoxFit.cover,
                              cacheWidth: 96,
                              cacheHeight: 96,
                              filterQuality: FilterQuality.low,
                              gaplessPlayback: true,
                              errorBuilder: (context, error, stackTrace) =>
                                  _ProductFallbackIcon(color: scheme.primary),
                            )
                          : _ProductFallbackIcon(color: scheme.primary),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.brandBorder,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        AppFormatters.rupiah(widget.product.hargaJual),
                        style: const TextStyle(
                          color: AppTheme.brandPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.product.namaBarang,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                if (_expanded && selected) ...[
                  Row(
                    children: [
                      _CircleQtyButton(
                        icon: Icons.remove_rounded,
                        onTap: widget.onRemove,
                        background: Colors.white,
                        iconColor: AppTheme.brandPrimary,
                        borderColor: AppTheme.brandBorder,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${widget.currentQty}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _CircleQtyButton(
                        icon: Icons.add_rounded,
                        onTap: widget.onAdd,
                        background: AppTheme.brandPrimary,
                        iconColor: Colors.white,
                        borderColor: AppTheme.brandPrimary,
                      ),
                      const SizedBox(width: 8),
                      InkResponse(
                        onTap: _toggleExpanded,
                        radius: 18,
                        child: const Icon(
                          Icons.keyboard_arrow_up_rounded,
                          size: 20,
                          color: AppTheme.brandMuted,
                        ),
                      ),
                    ],
                  ),
                ] else if (_expanded) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Belum ada item',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _CircleQtyButton(
                        icon: Icons.add_rounded,
                        onTap: widget.onAdd,
                        background: AppTheme.brandPrimary,
                        iconColor: Colors.white,
                        borderColor: AppTheme.brandPrimary,
                      ),
                      const SizedBox(width: 8),
                      InkResponse(
                        onTap: _toggleExpanded,
                        radius: 18,
                        child: const Icon(
                          Icons.keyboard_arrow_up_rounded,
                          size: 20,
                          color: AppTheme.brandMuted,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          selected
                              ? '${widget.currentQty} pcs di keranjang'
                              : 'Tap to add',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkResponse(
                        onTap: _toggleExpanded,
                        radius: 18,
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: AppTheme.brandMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductFallbackIcon extends StatelessWidget {
  const _ProductFallbackIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.brandSurface,
      child: Icon(Icons.ac_unit_rounded, color: color, size: 18),
    );
  }
}

class _CircleQtyButton extends StatelessWidget {
  const _CircleQtyButton({
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
          width: 30,
          height: 30,
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

class _CartBadge extends StatelessWidget {
  const _CartBadge({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shopping_basket_rounded,
                size: 18,
                color: scheme.primary,
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
