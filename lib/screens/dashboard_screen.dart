import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../models/sales_transaction.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/sales_provider.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';
import 'basket_screen.dart';
import 'products_screen.dart';
import 'sales_screen.dart';
import 'stock_history_screen.dart';
import 'stock_screen.dart';
import 'transaction_detail_screen.dart';
import 'transaction_history_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return StreamBuilder<List<Product>>(
      stream: context.read<ProductProvider>().watchProducts(),
      builder: (context, productSnapshot) {
        return StreamBuilder<List<SalesTransaction>>(
          stream: context.read<SalesProvider>().watchTransactions(),
          builder: (context, trxSnapshot) {
            if (!productSnapshot.hasData || !trxSnapshot.hasData) {
              return const AppLoadingIndicator();
            }

            final products = productSnapshot.data!;
            final transactions = trxSnapshot.data!;
            final isOwner = user?.isOwner == true;
            final userName = user?.nama ?? 'Pengguna';
            final revenue = transactions.fold<int>(
              0,
              (sum, trx) => sum + trx.totalHarga,
            );
            final lowStock = products
                .where((product) => product.stok <= 5)
                .length;
            final totalStock = products.fold<int>(
              0,
              (sum, product) => sum + product.stok,
            );

            if (!isOwner) {
              return _CashierDashboard(
                name: userName,
                products: products.length,
                lowStock: lowStock,
                totalStock: totalStock,
                transactions: transactions,
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              children: [
                _StaggeredEntry(
                  delay: const Duration(milliseconds: 40),
                  child: _DashboardHero(
                    name: userName,
                    isOwner: isOwner,
                    revenue: revenue,
                  ),
                ),
                const SizedBox(height: 14),
                _StaggeredEntry(
                  delay: const Duration(milliseconds: 120),
                  child: _StatsGrid(
                    isOwner: isOwner,
                    transactions: transactions.length,
                    products: products.length,
                    lowStock: lowStock,
                    totalStock: totalStock,
                  ),
                ),
                const SizedBox(height: 22),
                if (isOwner)
                  _StaggeredEntry(
                    delay: const Duration(milliseconds: 220),
                    child: _RecentTransactions(transactions: transactions),
                  )
                else
                  const _StaggeredEntry(
                    delay: Duration(milliseconds: 220),
                    child: _CashierShortcuts(),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _CashierDashboard extends StatelessWidget {
  const _CashierDashboard({
    required this.name,
    required this.products,
    required this.lowStock,
    required this.totalStock,
    required this.transactions,
  });

  final String name;
  final int products;
  final int lowStock;
  final int totalStock;
  final List<SalesTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _CashierHeader(name: name),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: _StatsGrid(
              isOwner: false,
              transactions: transactions.length,
              products: products,
              lowStock: lowStock,
              totalStock: totalStock,
            ),
          ),
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _CashierMenuGrid(),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
            child: _CashierRecentTransactions(transactions: transactions),
          ),
        ],
      ),
    );
  }
}

class _CashierHeader extends StatelessWidget {
  const _CashierHeader({required this.name});

  static const _orange = Color(0xFFFF4A01);
  static const _text = Color(0xFF243757);

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'P';
    final dateLabel = AppFormatters.date(DateTime.now()).split(',').first;

    return SizedBox(
      height: 322,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 282,
            decoration: const BoxDecoration(
              color: _orange,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: _text,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hello,',
                              style: TextStyle(
                                color: _text,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Notifikasi',
                        onPressed: () {},
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          color: _orange,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          dateLabel,
                          style: const TextStyle(
                            color: _text,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 126,
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD5C7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/splash_calculator.png',
                          width: 92,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Kasir Praktis',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: Color(0xFF1F2937),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Kelola penjualan dan cek riwayat transaksi dengan cepat.',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: Color(0xFF4B5563),
                                  fontSize: 12,
                                  height: 1.25,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.name,
    required this.isOwner,
    required this.revenue,
  });

  final String name;
  final bool isOwner;
  final int revenue;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFF4A01),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4A01).withValues(alpha: .18),
            offset: const Offset(0, 10),
            blurRadius: 24,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, $name',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isOwner ? 'Owner toko' : 'Petugas kasir',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isOwner) ...[
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Omzet',
                  style: TextStyle(
                    color: Color(0xFFFFE9DE),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 132),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      AppFormatters.rupiah(revenue),
                      maxLines: 1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.transactions,
    required this.isOwner,
    required this.products,
    required this.lowStock,
    required this.totalStock,
  });

  final int transactions;
  final bool isOwner;
  final int products;
  final int lowStock;
  final int totalStock;

  @override
  Widget build(BuildContext context) {
    final items = [
      if (isOwner)
        _StatData(
          title: 'Transaksi',
          value: '$transactions',
          icon: FontAwesomeIcons.bagShopping,
          color: const Color(0xFFFF4A01),
        ),
      _StatData(
        title: 'Barang',
        value: '$products',
        icon: FontAwesomeIcons.boxOpen,
        color: const Color(0xFFFF4A01),
      ),
      _StatData(
        title: 'Stok tipis',
        value: '$lowStock',
        icon: FontAwesomeIcons.triangleExclamation,
        color: const Color(0xFFFF4A01),
      ),
      _StatData(
        title: isOwner ? 'Total stok' : 'Siap dijual',
        value: '$totalStock',
        icon: FontAwesomeIcons.snowflake,
        color: const Color(0xFFFF4A01),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 620 ? 4 : 2;
        return GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 126,
          ),
          itemBuilder: (context, index) {
            return _StaggeredEntry(
              delay: Duration(milliseconds: 160 + index * 55),
              child: _CompactStatCard(data: items[index]),
            );
          },
        );
      },
    );
  }
}

class _CompactStatCard extends StatelessWidget {
  const _CompactStatCard({required this.data});

  final _StatData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .28)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: .04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: FaIcon(data.icon, color: data.color, size: 18),
            ),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              data.value,
              maxLines: 1,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CashierShortcuts extends StatelessWidget {
  const _CashierShortcuts();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shortcut',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        Material(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TransactionHistoryScreen(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: .34),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBDD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: FaIcon(
                        FontAwesomeIcons.receipt,
                        color: Color(0xFFFF4A01),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Histori Transaksi',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Lihat transaksi terbaru dan detailnya',
                          style: TextStyle(
                            color: Color(0xFF5D6B82),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CashierMenuGrid extends StatelessWidget {
  const _CashierMenuGrid();

  @override
  Widget build(BuildContext context) {
    final items = [
      _CashierMenuItem(
        title: 'Penjualan',
        icon: FontAwesomeIcons.cashRegister,
        onTap: () => _push(context, const SalesScreen()),
      ),
      _CashierMenuItem(
        title: 'Barang',
        icon: FontAwesomeIcons.boxOpen,
        onTap: () => _push(context, const ProductsScreen()),
      ),
      _CashierMenuItem(
        title: 'Stok',
        icon: FontAwesomeIcons.warehouse,
        onTap: () => _push(context, const StockScreen()),
      ),
      _CashierMenuItem(
        title: 'Riwayat Stok',
        icon: FontAwesomeIcons.clockRotateLeft,
        onTap: () => _push(context, const StockHistoryScreen()),
      ),
      _CashierMenuItem(
        title: 'Keranjang',
        icon: FontAwesomeIcons.basketShopping,
        onTap: () => _push(context, const BasketScreen()),
      ),
      _CashierMenuItem(
        title: 'Transaksi',
        icon: FontAwesomeIcons.receipt,
        onTap: () => _push(context, const TransactionHistoryScreen()),
      ),
    ];

    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 92,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _CashierMenuCard(item: item);
      },
    );
  }

  static void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class _CashierMenuItem {
  const _CashierMenuItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
}

class _CashierMenuCard extends StatelessWidget {
  const _CashierMenuCard({required this.item});

  static const _orange = Color(0xFFFF4A01);

  final _CashierMenuItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE4E8EF)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .035),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(item.icon, color: _orange, size: 24),
              const SizedBox(height: 10),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF243757),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CashierRecentTransactions extends StatelessWidget {
  const _CashierRecentTransactions({required this.transactions});

  final List<SalesTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    final latest = transactions.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Recent Transactions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF243757),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TransactionHistoryScreen(),
                  ),
                );
              },
              label: const Text('See All'),
              icon: const Icon(Icons.chevron_right_rounded),
              iconAlignment: IconAlignment.end,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (latest.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE4E8EF)),
            ),
            child: const Text(
              'Belum ada transaksi terbaru.',
              style: TextStyle(
                color: Color(0xFF5D6B82),
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        else
          for (final transaction in latest)
            _TransactionTile(transaction: transaction),
      ],
    );
  }
}

class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions({required this.transactions});

  final List<SalesTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Transaksi Terbaru',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBDD),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${transactions.length} data',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFFC63D0F),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (transactions.isEmpty)
          Container(
            height: 230,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: .42),
              ),
            ),
            child: EmptyState(
              iconWidget: FaIcon(
                FontAwesomeIcons.receipt,
                color: scheme.onPrimaryContainer,
                size: 34,
              ),
              title: 'Belum ada transaksi',
              subtitle: 'Transaksi berhasil akan muncul di sini.',
            ),
          )
        else
          ...transactions.take(5).toList().asMap().entries.map((entry) {
            final trx = entry.value;
            return _StaggeredEntry(
              delay: Duration(milliseconds: 270 + entry.key * 60),
              child: _TransactionTile(transaction: trx),
            );
          }),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final SalesTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TransactionDetailScreen(transaction: transaction),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBDD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: FaIcon(
                    FontAwesomeIcons.receipt,
                    color: Color(0xFFFF4A01),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.namaBarang,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${transaction.qty} item - ${transaction.metodePembayaran}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    AppFormatters.rupiah(transaction.totalHarga),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaggeredEntry extends StatefulWidget {
  const _StaggeredEntry({required this.child, required this.delay});

  final Widget child;
  final Duration delay;

  @override
  State<_StaggeredEntry> createState() => _StaggeredEntryState();
}

class _StaggeredEntryState extends State<_StaggeredEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .08),
          end: Offset.zero,
        ).animate(_animation),
        child: widget.child,
      ),
    );
  }
}

class _StatData {
  const _StatData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
}
