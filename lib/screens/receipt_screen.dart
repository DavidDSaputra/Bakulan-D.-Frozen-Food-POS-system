import 'package:flutter/material.dart';

import '../models/sale_item.dart';
import '../services/receipt_pdf_service.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/snackbar.dart';

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({
    super.key,
    required this.items,
    required this.method,
    required this.paid,
    required this.cashierName,
  });

  final List<SaleItem> items;
  final String method;
  final int paid;
  final String cashierName;

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen>
    with SingleTickerProviderStateMixin {
  final _pdfService = ReceiptPdfService();
  late final String _receiptCode;
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  bool _isSharing = false;

  int get total => widget.items.fold(0, (sum, item) => sum + item.subtotal);
  int get change => widget.method == 'cash' ? widget.paid - total : 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().millisecondsSinceEpoch.toString();
    _receiptCode = '#${now.substring(now.length - 4)}';
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, .08),
      end: Offset.zero,
    ).animate(_fadeAnimation);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _shareReceipt() async {
    setState(() => _isSharing = true);
    try {
      await _pdfService.shareReceipt(
        items: widget.items,
        method: widget.method,
        paid: widget.paid,
        cashierName: widget.cashierName,
      );
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(context, 'Gagal membuat PDF struk', isError: true);
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _openReceiptPreview() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReceiptPreviewSheet(
        code: _receiptCode,
        items: widget.items,
        method: widget.method,
        total: total,
        paid: widget.paid,
        change: change,
        cashierName: widget.cashierName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.shadow.withValues(alpha: .08),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 34,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppTheme.brandBorder,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(height: 18),
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 820),
                          tween: Tween(begin: .84, end: 1),
                          curve: Curves.easeOutBack,
                          builder: (context, value, child) {
                            return Transform.scale(scale: value, child: child);
                          },
                          child: Image.asset(
                            'assets/images/payment_success.png',
                            height: 174,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Transaksi Berhasil',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: const Color(0xFF2EAF5D),
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 10),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: scheme.onSurface,
                                ),
                            children: [
                              const TextSpan(text: 'TOTAL '),
                              TextSpan(
                                text: AppFormatters.rupiah(total),
                                style: const TextStyle(
                                  color: AppTheme.brandPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Metode Pembayaran: ${widget.method.toUpperCase()}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 22),
                        _ReceiptPreviewTile(
                          code: _receiptCode,
                          onTap: _openReceiptPreview,
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: () => Navigator.pop(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.brandPrimary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Transaksi Baru'),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: _isSharing ? null : _shareReceipt,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.brandPrimary,
                            side: const BorderSide(color: AppTheme.brandBorder),
                          ),
                          child: _isSharing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Send Receipt'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptPreviewTile extends StatelessWidget {
  const _ReceiptPreviewTile({required this.code, required this.onTap});

  final String code;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.brandSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: .45),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.brandTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppTheme.brandPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Receipt $code',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptPreviewSheet extends StatelessWidget {
  const _ReceiptPreviewSheet({
    required this.code,
    required this.items,
    required this.method,
    required this.total,
    required this.paid,
    required this.change,
    required this.cashierName,
  });

  final String code;
  final List<SaleItem> items;
  final String method;
  final int total;
  final int paid;
  final int change;
  final String cashierName;

  bool get _isCash => method == 'cash';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 24, 12, bottomPadding + 12),
        child: Material(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(28),
          clipBehavior: Clip.antiAlias,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: .82,
            minChildSize: .58,
            maxChildSize: .94,
            builder: (context, controller) {
              return ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppTheme.brandBorder,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Preview Struk',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                    decoration: BoxDecoration(
                      color: AppTheme.brandSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: .38),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bakulan POS',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppTheme.brandPrimary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Receipt $code',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppFormatters.date(DateTime.now()),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 14),
                        for (final item in items) ...[
                          _ReceiptLineItem(item: item),
                          const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 4),
                        const Divider(height: 1),
                        const SizedBox(height: 14),
                        _ReceiptInfoRow(
                          label: 'Metode bayar',
                          value: method.toUpperCase(),
                        ),
                        _ReceiptInfoRow(
                          label: 'Nama Kasir',
                          value: cashierName,
                        ),
                        const SizedBox(height: 10),
                        _ReceiptInfoRow(
                          label: 'Total',
                          value: AppFormatters.rupiah(total),
                          isBold: true,
                        ),
                        if (_isCash) ...[
                          const SizedBox(height: 10),
                          _ReceiptInfoRow(
                            label: 'Dibayar',
                            value: AppFormatters.rupiah(paid),
                          ),
                          const SizedBox(height: 10),
                          _ReceiptInfoRow(
                            label: 'Kembalian',
                            value: AppFormatters.rupiah(change),
                            valueColor: AppTheme.brandPrimary,
                            isBold: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ReceiptLineItem extends StatelessWidget {
  const _ReceiptLineItem({required this.item});

  final SaleItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.product.namaBarang,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                '${item.qty} x ${AppFormatters.rupiah(item.product.harga)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          AppFormatters.rupiah(item.subtotal),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _ReceiptInfoRow extends StatelessWidget {
  const _ReceiptInfoRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: valueColor ?? scheme.onSurface,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
