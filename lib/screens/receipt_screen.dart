import 'package:flutter/material.dart';

import '../models/sale_item.dart';
import '../services/receipt_pdf_service.dart';
import '../utils/formatters.dart';
import '../utils/snackbar.dart';

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({
    super.key,
    required this.items,
    required this.method,
    required this.paid,
  });

  final List<SaleItem> items;
  final String method;
  final int paid;

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen>
    with SingleTickerProviderStateMixin {
  final _pdfService = ReceiptPdfService();
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  bool _isSharing = false;

  int get total => widget.items.fold(0, (sum, item) => sum + item.subtotal);

  String get _receiptCode {
    final now = DateTime.now().millisecondsSinceEpoch.toString();
    return '#${now.substring(now.length - 4)}';
  }

  @override
  void initState() {
    super.initState();
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
      );
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(context, 'Gagal membuat PDF struk', isError: true);
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
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
                            color: const Color(0xFFE5E7EB),
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
                          'Sale Completed Successfully',
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
                              const TextSpan(text: 'TOTAL AMOUNT '),
                              TextSpan(
                                text: AppFormatters.rupiah(total),
                                style: const TextStyle(
                                  color: Color(0xFFFF5A1F),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Payment Type : ${widget.method.toUpperCase()}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 22),
                        _ReceiptPreviewTile(code: _receiptCode),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: () => Navigator.pop(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5A1F),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('New Sale'),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: _isSharing ? null : _shareReceipt,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF5A1F),
                            side: const BorderSide(color: Color(0xFFFFA07B)),
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
  const _ReceiptPreviewTile({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .45)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBDD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Color(0xFFFF5A1F),
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
    );
  }
}
