import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../models/sales_transaction.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/sales_provider.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/stat_card.dart';

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
            final revenue = transactions.fold<int>(
              0,
              (sum, trx) => sum + trx.totalHarga,
            );
            final lowStock = products
                .where((product) => product.stok <= 5)
                .length;
            final scheme = Theme.of(context).colorScheme;

            return TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0, end: 1),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 18 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: .18),
                          offset: const Offset(0, 12),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: scheme.onPrimary.withValues(alpha: .16),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: scheme.onPrimary.withValues(
                                    alpha: .22,
                                  ),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  (user?.nama.isNotEmpty ?? false)
                                      ? user!.nama[0].toUpperCase()
                                      : 'U',
                                  style: TextStyle(
                                    color: scheme.onPrimary,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
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
                                    'Halo, ${user?.nama ?? 'Pengguna'}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: scheme.onPrimary,
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user?.isOwner == true
                                        ? 'Owner - pantau performa toko'
                                        : 'Petugas/Kasir - siap bertransaksi',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: scheme.onPrimary.withValues(
                                            alpha: .78,
                                          ),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: scheme.onPrimary.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: scheme.onPrimary.withValues(alpha: .13),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Omzet tercatat',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: scheme.onPrimary.withValues(
                                              alpha: .74,
                                            ),
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      AppFormatters.rupiah(revenue),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            color: scheme.onPrimary,
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: scheme.onPrimary.withValues(
                                    alpha: .14,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.trending_up_rounded,
                                  color: scheme.onPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: .94,
                        ),
                    children: [
                      StatCard(
                        title: 'Transaksi',
                        value: '${transactions.length}',
                        icon: Icons.shopping_bag_rounded,
                        color: const Color(0xFF3B82C4),
                      ),
                      StatCard(
                        title: 'Total Barang',
                        value: '${products.length}',
                        icon: Icons.inventory_rounded,
                        color: const Color(0xFFE69A26),
                      ),
                      StatCard(
                        title: 'Stok Menipis',
                        value: '$lowStock',
                        icon: Icons.warning_rounded,
                        color: const Color(0xFFD95B5B),
                      ),
                      StatCard(
                        title: 'Item Stok',
                        value:
                            '${products.fold<int>(0, (sum, product) => sum + product.stok)}',
                        icon: Icons.ac_unit_rounded,
                        color: const Color(0xFF6B7FDC),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Transaksi Terbaru',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Text(
                        '${transactions.length} data',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (transactions.isEmpty)
                    const SizedBox(
                      height: 260,
                      child: EmptyState(
                        icon: Icons.receipt_long_rounded,
                        title: 'Belum ada transaksi',
                        subtitle:
                            'Transaksi berhasil akan muncul pada dashboard.',
                      ),
                    )
                  else
                    ...transactions
                        .take(5)
                        .map(
                          (trx) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: scheme.secondaryContainer,
                                  child: Icon(
                                    Icons.receipt_rounded,
                                    color: scheme.onSecondaryContainer,
                                  ),
                                ),
                                title: Text(
                                  trx.namaBarang,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '${trx.qty} item - ${trx.metodePembayaran}',
                                ),
                                trailing: Text(
                                  AppFormatters.rupiah(trx.totalHarga),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
