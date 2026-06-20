import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sales_invoice.dart';
import '../providers/sales_provider.dart';
import '../services/receipt_pdf_service.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/snackbar.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';
import 'invoice_detail_screen.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Histori Transaksi')),
      body: StreamBuilder<List<SalesInvoice>>(
        stream: context.read<SalesProvider>().watchInvoices(limit: 120),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const AppLoadingIndicator();

          final invoices = snapshot.data!
            ..sort((a, b) => b.tanggal.compareTo(a.tanggal));

          if (invoices.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_rounded,
              title: 'Belum ada transaksi',
              subtitle: 'Invoice yang selesai akan tampil di sini.',
            );
          }

          final latest = invoices.first;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _LatestInvoiceCard(invoice: latest),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Semua Invoice',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '${invoices.length} data',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              for (final invoice in invoices)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _InvoiceHistoryTile(invoice: invoice),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LatestInvoiceCard extends StatelessWidget {
  const _LatestInvoiceCard({required this.invoice});

  final SalesInvoice invoice;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.brandPrimary,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _openDetail(context, invoice),
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
                      'Invoice Terbaru',
                      style: TextStyle(
                        color: Color(0xFFFFE9DE),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      invoice.invoiceCode,
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
                      '${AppFormatters.number(invoice.totalQty)} item - ${AppFormatters.rupiah(invoice.totalHarga)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Cetak ulang struk',
                onPressed: () => _reprintInvoice(context, invoice),
                icon: const Icon(Icons.print_rounded, color: Colors.white),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvoiceHistoryTile extends StatelessWidget {
  const _InvoiceHistoryTile({required this.invoice});

  final SalesInvoice invoice;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        onTap: () => _openDetail(context, invoice),
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Icon(Icons.receipt_rounded, color: scheme.primary),
        ),
        title: Text(
          invoice.invoiceCode,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${AppFormatters.date(invoice.tanggal)} - ${invoice.metodePembayaran}',
            ),
            const SizedBox(height: 2),
            Text(
              '${invoice.namaUser} - ${_statusLabel(invoice.status)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        trailing: SizedBox(
          width: 120,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  AppFormatters.rupiah(invoice.totalHarga),
                  maxLines: 2,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                tooltip: 'Cetak ulang struk',
                onPressed: () => _reprintInvoice(context, invoice),
                icon: const Icon(Icons.print_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _reprintInvoice(BuildContext context, SalesInvoice invoice) async {
  try {
    final items = await context
        .read<SalesProvider>()
        .watchInvoiceItems(invoice.id)
        .first;
    if (items.isEmpty) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          'Item transaksi tidak ditemukan',
          isError: true,
        );
      }
      return;
    }
    await ReceiptPdfService().shareInvoiceReceipt(
      invoice: invoice,
      items: items,
    );
  } catch (_) {
    if (context.mounted) {
      showAppSnackBar(context, 'Gagal mencetak ulang struk', isError: true);
    }
  }
}

void _openDetail(BuildContext context, SalesInvoice invoice) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoice: invoice)),
  );
}

String _statusLabel(String status) {
  return switch (status) {
    'cancelled' => 'Dibatalkan',
    'returned' => 'Diretur penuh',
    'partial_return' => 'Retur sebagian',
    _ => 'Selesai',
  };
}
