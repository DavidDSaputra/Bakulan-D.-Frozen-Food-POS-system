import 'package:flutter/material.dart';

import '../models/sales_transaction.dart';
import '../services/receipt_pdf_service.dart';
import '../utils/formatters.dart';
import '../utils/snackbar.dart';

class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key, required this.transaction});

  final SalesTransaction transaction;

  Future<void> _reprintReceipt(BuildContext context) async {
    try {
      await ReceiptPdfService().shareTransactionReceipt(
        transaction: transaction,
      );
    } catch (_) {
      if (context.mounted) {
        showAppSnackBar(context, 'Gagal mencetak ulang struk', isError: true);
      }
    }
  }

  bool get _hasProof => (transaction.paymentProofUrl ?? '').trim().isNotEmpty;
  bool get _hasAccount =>
      (transaction.paymentAccountName ?? '').trim().isNotEmpty ||
      (transaction.paymentAccountNumber ?? '').trim().isNotEmpty;
  String? get _statusLabel {
    final status = (transaction.paymentStatus ?? '').trim();
    if (status.isEmpty) return null;
    if (status == 'menunggu_verifikasi' || status == 'lunas') return 'Lunas';
    return status
        .split('_')
        .map((word) {
          if (word.isEmpty) return word;
          return '${word[0].toUpperCase()}${word.substring(1)}';
        })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusLabel = _statusLabel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        actions: [
          IconButton(
            tooltip: 'Cetak ulang struk',
            onPressed: () => _reprintReceipt(context),
            icon: const Icon(Icons.print_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: scheme.primaryContainer,
                        child: Icon(
                          Icons.receipt_long_rounded,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              transaction.namaBarang,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              AppFormatters.date(transaction.tanggal),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28),
                  _detailRow('Qty', '${transaction.qty} item'),
                  if (transaction.hargaJual > 0)
                    _detailRow(
                      'Harga Jual',
                      AppFormatters.rupiah(transaction.hargaJual),
                    ),
                  if (transaction.hargaBeli > 0)
                    _detailRow(
                      'Harga Modal',
                      AppFormatters.rupiah(transaction.hargaBeli),
                    ),
                  _detailRow(
                    'Total',
                    AppFormatters.rupiah(transaction.totalHarga),
                  ),
                  if (transaction.effectiveLaba != 0)
                    _detailRow(
                      'Laba',
                      AppFormatters.rupiah(transaction.effectiveLaba),
                    ),
                  _detailRow('Metode', transaction.metodePembayaran),
                  if (statusLabel != null) _detailRow('Status', statusLabel),
                  _detailRow('Nama Kasir', transaction.namaUser),
                ],
              ),
            ),
          ),
          if (_hasAccount) ...[
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Tujuan Pembayaran',
              icon: Icons.account_balance_wallet_rounded,
              children: [
                if ((transaction.paymentAccountName ?? '').trim().isNotEmpty)
                  _detailRow(
                    'Atas Nama',
                    transaction.paymentAccountName!.trim(),
                  ),
                if ((transaction.paymentAccountNumber ?? '').trim().isNotEmpty)
                  _detailRow('Nomor', transaction.paymentAccountNumber!.trim()),
              ],
            ),
          ],
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Bukti Pembayaran',
            icon: Icons.image_rounded,
            children: [
              if (_hasProof)
                _ProofImage(url: transaction.paymentProofUrl!.trim())
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(
                      alpha: .48,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Belum ada bukti pembayaran untuk transaksi ini.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => _reprintReceipt(context),
            icon: const Icon(Icons.print_rounded),
            label: const Text('Cetak Struk Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 14),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ProofImage extends StatelessWidget {
  const _ProofImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Material(
        color: scheme.surfaceContainerHighest,
        child: InkWell(
          onTap: () => _showFullImage(context),
          child: AspectRatio(
            aspectRatio: 4 / 5,
            child: Image.network(
              url,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text(
                      'Bukti pembayaran belum bisa ditampilkan.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(title: const Text('Bukti Pembayaran')),
            body: InteractiveViewer(
              child: Center(child: Image.network(url, fit: BoxFit.contain)),
            ),
          ),
        );
      },
    );
  }
}
