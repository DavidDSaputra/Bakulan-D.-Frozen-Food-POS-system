import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sales_transaction.dart';
import '../providers/sales_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';
import 'transaction_detail_screen.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Histori Transaksi')),
      body: StreamBuilder<List<SalesTransaction>>(
        stream: context.read<SalesProvider>().watchTransactions(limit: 120),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const AppLoadingIndicator();

          final transactions = snapshot.data!
            ..sort((a, b) => b.tanggal.compareTo(a.tanggal));

          if (transactions.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_rounded,
              title: 'Belum ada transaksi',
              subtitle: 'Transaksi yang selesai akan tampil di sini.',
            );
          }

          final latest = transactions.first;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _LatestTransactionCard(transaction: latest),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Semua Transaksi',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
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
              const SizedBox(height: 10),
              for (final trx in transactions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TransactionHistoryTile(transaction: trx),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LatestTransactionCard extends StatelessWidget {
  const _LatestTransactionCard({required this.transaction});

  final SalesTransaction transaction;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.brandPrimary,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _openDetail(context, transaction),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .22),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Transaksi Terbaru',
                      style: TextStyle(
                        color: Color(0xFFFFE9DE),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaction.namaBarang,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${transaction.qty} item - ${AppFormatters.rupiah(transaction.totalHarga)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionHistoryTile extends StatelessWidget {
  const _TransactionHistoryTile({required this.transaction});

  final SalesTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        onTap: () => _openDetail(context, transaction),
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Icon(Icons.receipt_rounded, color: scheme.primary),
        ),
        title: Text(
          transaction.namaBarang,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${AppFormatters.date(transaction.tanggal)} - ${transaction.metodePembayaran}',
        ),
        trailing: Text(
          AppFormatters.rupiah(transaction.totalHarga),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

void _openDetail(BuildContext context, SalesTransaction transaction) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => TransactionDetailScreen(transaction: transaction),
    ),
  );
}
