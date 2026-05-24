import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sales_transaction.dart';
import '../providers/sales_provider.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/stat_card.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SalesTransaction>>(
      stream: context.read<SalesProvider>().watchTransactions(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const AppLoadingIndicator();
        final transactions = snapshot.data!;
        final revenue = transactions.fold<int>(
          0,
          (sum, trx) => sum + trx.totalHarga,
        );
        final totalQty = transactions.fold<int>(0, (sum, trx) => sum + trx.qty);

        if (transactions.isEmpty) {
          return const EmptyState(
            icon: Icons.receipt_long_rounded,
            title: 'Laporan masih kosong',
            subtitle: 'Data laporan akan terisi setelah transaksi berhasil.',
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.12,
              ),
              children: [
                StatCard(
                  title: 'Total Omzet',
                  value: AppFormatters.rupiah(revenue),
                  icon: Icons.payments_rounded,
                  color: const Color(0xFF2F7D68),
                ),
                StatCard(
                  title: 'Item Terjual',
                  value: '$totalQty',
                  icon: Icons.shopping_cart_checkout_rounded,
                  color: const Color(0xFF3B82C4),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Riwayat Penjualan',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            ...transactions.map(
              (trx) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.receipt_rounded),
                    ),
                    title: Text(
                      trx.namaBarang,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${AppFormatters.date(trx.tanggal)} - ${trx.metodePembayaran}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          AppFormatters.rupiah(trx.totalHarga),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text('${trx.qty} item'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
