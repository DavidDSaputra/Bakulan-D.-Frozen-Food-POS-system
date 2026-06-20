import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sales_invoice.dart';
import '../models/sales_transaction.dart';
import '../providers/auth_provider.dart';
import '../providers/sales_provider.dart';
import '../services/receipt_pdf_service.dart';
import '../utils/formatters.dart';
import '../utils/number_input_formatter.dart';
import '../utils/snackbar.dart';
import '../widgets/loading_indicator.dart';

class InvoiceDetailScreen extends StatelessWidget {
  const InvoiceDetailScreen({super.key, required this.invoice});

  final SalesInvoice invoice;

  Future<void> _reprint(
    BuildContext context,
    List<SalesTransaction> items,
  ) async {
    try {
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return StreamBuilder<List<SalesTransaction>>(
      stream: context.read<SalesProvider>().watchInvoiceItems(invoice.id),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <SalesTransaction>[];

        return Scaffold(
          appBar: AppBar(
            title: Text(invoice.invoiceCode),
            actions: [
              IconButton(
                tooltip: 'Cetak struk',
                onPressed: items.isEmpty
                    ? null
                    : () => _reprint(context, items),
                icon: const Icon(Icons.print_rounded),
              ),
            ],
          ),
          body: _InvoiceDetailBody(
            invoice: invoice,
            items: items,
            isLoading: snapshot.connectionState == ConnectionState.waiting,
            error: snapshot.error,
            onReprint: () => _reprint(context, items),
            onCancel: () => _openCancelSheet(context, items),
            scheme: scheme,
            statusLabel: _statusLabel(invoice.status),
          ),
        );
      },
    );
  }

  Future<void> _openCancelSheet(
    BuildContext context,
    List<SalesTransaction> items,
  ) async {
    final actor = context.read<AuthProvider>().user;
    if (actor == null) {
      showAppSnackBar(context, 'Sesi pengguna tidak ditemukan', isError: true);
      return;
    }

    final noteController = TextEditingController();
    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final bottom = MediaQuery.viewInsetsOf(sheetContext).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Batalkan Invoice',
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Alasan pembatalan',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(sheetContext, true),
                child: const Text('Lanjut Batalkan'),
              ),
            ],
          ),
        );
      },
    );

    final note = noteController.text.trim();
    noteController.dispose();
    if (success != true) return;
    if (!context.mounted) return;

    try {
      await context.read<SalesProvider>().cancelInvoice(
        invoice: invoice,
        items: items,
        note: note,
        actor: actor,
      );
      if (context.mounted) {
        showAppSnackBar(context, 'Invoice berhasil dibatalkan');
      }
    } catch (error) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          error.toString().replaceAll('Exception: ', ''),
          isError: true,
        );
      }
    }
  }

  String _statusLabel(String status) {
    return switch (status) {
      'cancelled' => 'Dibatalkan',
      'returned' => 'Diretur',
      'partial_return' => 'Retur Sebagian',
      _ => 'Selesai',
    };
  }
}

class _InvoiceDetailBody extends StatelessWidget {
  const _InvoiceDetailBody({
    required this.invoice,
    required this.items,
    required this.isLoading,
    required this.error,
    required this.onReprint,
    required this.onCancel,
    required this.scheme,
    required this.statusLabel,
  });

  final SalesInvoice invoice;
  final List<SalesTransaction> items;
  final bool isLoading;
  final Object? error;
  final VoidCallback onReprint;
  final VoidCallback onCancel;
  final ColorScheme scheme;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const AppLoadingIndicator();
    if (error != null) return _InvoiceItemsError(error: error!);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.invoiceCode,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  AppFormatters.date(invoice.tanggal),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Divider(height: 28),
                _InfoRow(label: 'Kasir', value: invoice.namaUser),
                _InfoRow(label: 'Metode', value: invoice.metodePembayaran),
                _InfoRow(label: 'Status', value: statusLabel),
                _InfoRow(
                  label: 'Total',
                  value: AppFormatters.rupiah(invoice.totalHarga),
                  isBold: true,
                ),
                if (invoice.returnedAmount > 0)
                  _InfoRow(
                    label: 'Retur',
                    value: AppFormatters.rupiah(invoice.returnedAmount),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Item Transaksi',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'Item invoice belum ditemukan. Coba kembali dari riwayat transaksi.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          )
        else
          for (final item in items) ...[
            _InvoiceItemTile(invoice: invoice, item: item),
            const SizedBox(height: 10),
          ],
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: items.isEmpty ? null : onReprint,
          icon: const Icon(Icons.print_rounded),
          label: const Text('Cetak Struk Lagi'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: invoice.isCancelled || invoice.isReturned || items.isEmpty
              ? null
              : onCancel,
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Batalkan Invoice'),
        ),
      ],
    );
  }
}

class _InvoiceItemsError extends StatelessWidget {
  const _InvoiceItemsError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final message = error.toString().contains('permission-denied')
        ? 'Firestore menolak membaca item invoice. Publish rules terbaru dan pastikan collection transaksi bisa dibaca akun kasir.'
        : 'Item invoice terlalu lama dimuat. Cek koneksi lalu coba buka lagi.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, color: scheme.error, size: 42),
            const SizedBox(height: 12),
            Text(
              'Invoice belum bisa dimuat',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceItemTile extends StatelessWidget {
  const _InvoiceItemTile({required this.invoice, required this.item});

  final SalesInvoice invoice;
  final SalesTransaction item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canReturn = !invoice.isCancelled && item.remainingQty > 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.namaBarang,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (item.returnedQty > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Retur ${AppFormatters.number(item.returnedQty)}',
                      style: TextStyle(
                        color: scheme.onSecondaryContainer,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${AppFormatters.number(item.qty)} x ${AppFormatters.rupiah(item.hargaJual)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Subtotal ${AppFormatters.rupiah(item.totalHarga)}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (canReturn) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () => _openReturnSheet(context),
                  icon: const Icon(Icons.undo_rounded),
                  label: const Text('Retur Item'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openReturnSheet(BuildContext context) async {
    final actor = context.read<AuthProvider>().user;
    if (actor == null) {
      showAppSnackBar(context, 'Sesi pengguna tidak ditemukan', isError: true);
      return;
    }

    final qtyController = TextEditingController();
    final noteController = TextEditingController();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final bottom = MediaQuery.viewInsetsOf(sheetContext).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Retur ${item.namaBarang}',
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandSeparatorInputFormatter()],
                decoration: InputDecoration(
                  labelText: 'Qty retur (maks ${item.remainingQty})',
                  prefixIcon: const Icon(Icons.exposure_minus_1_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Alasan retur',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(sheetContext, true),
                child: const Text('Proses Retur'),
              ),
            ],
          ),
        );
      },
    );

    final qty = AppFormatters.parseNumberInput(qtyController.text) ?? 0;
    final note = noteController.text.trim();
    qtyController.dispose();
    noteController.dispose();
    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      await context.read<SalesProvider>().returnInvoiceItem(
        invoice: invoice,
        item: item,
        qty: qty,
        note: note,
        actor: actor,
      );
      if (context.mounted) {
        showAppSnackBar(context, 'Retur item berhasil diproses');
      }
    } catch (error) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          error.toString().replaceAll('Exception: ', ''),
          isError: true,
        );
      }
    }
  }
}
