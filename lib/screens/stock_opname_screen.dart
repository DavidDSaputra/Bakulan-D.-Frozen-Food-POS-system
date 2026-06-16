import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../models/sales_transaction.dart';
import '../models/stock_movement.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/sales_provider.dart';
import '../services/cloudinary_service.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/snackbar.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';

class StockOpnameScreen extends StatefulWidget {
  const StockOpnameScreen({super.key});

  @override
  State<StockOpnameScreen> createState() => _StockOpnameScreenState();
}

class _StockOpnameScreenState extends State<StockOpnameScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: context.read<ProductProvider>().watchProducts(),
      builder: (context, productSnapshot) {
        return StreamBuilder<List<SalesTransaction>>(
          stream: context.read<SalesProvider>().watchTransactions(limit: 1000),
          builder: (context, trxSnapshot) {
            return StreamBuilder<List<StockMovement>>(
              stream: context.read<ProductProvider>().watchOpnameMovements(),
              builder: (context, opnameSnapshot) {
                if (!productSnapshot.hasData ||
                    !trxSnapshot.hasData ||
                    !opnameSnapshot.hasData) {
                  return const AppLoadingIndicator();
                }

                final products = productSnapshot.data!;
                final range = _MonthRange.from(_month);
                final monthlyTransactions = trxSnapshot.data!
                    .where((trx) => range.contains(trx.tanggal))
                    .toList();
                final monthlyOpnameMovements =
                    opnameSnapshot.data!
                        .where((movement) => range.contains(movement.tanggal))
                        .toList()
                      ..sort((a, b) => b.tanggal.compareTo(a.tanggal));
                final rows = _buildRows(products, monthlyTransactions);
                final soldRows = rows.where((row) => row.qtySold > 0).toList();
                final unsoldRows = rows
                    .where((row) => row.qtySold == 0)
                    .toList();
                final totalProfit = rows.fold<int>(
                  0,
                  (sum, row) => sum + row.profit,
                );
                final unsold = unsoldRows.length;

                if (products.isEmpty) {
                  return const EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Belum ada barang',
                    subtitle: 'Tambahkan barang dulu untuk mulai opname.',
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _MonthPicker(
                      month: _month,
                      onPrevious: () => setState(
                        () => _month = DateTime(_month.year, _month.month - 1),
                      ),
                      onNext: () => setState(
                        () => _month = DateTime(_month.year, _month.month + 1),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            title: 'Laba Bulan Ini',
                            value: AppFormatters.rupiah(totalProfit),
                            icon: Icons.trending_up_rounded,
                            color: const Color(0xFF27AE60),
                            onTap: soldRows.isEmpty
                                ? null
                                : () => _openDetailSheet(
                                    context,
                                    title: 'Barang Laku',
                                    subtitle:
                                        '${soldRows.length} barang terjual bulan ini',
                                    rows: soldRows,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SummaryCard(
                            title: 'Belum Terjual',
                            value: '$unsold barang',
                            icon: Icons.visibility_off_rounded,
                            color: const Color(0xFFE97670),
                            onTap: unsoldRows.isEmpty
                                ? null
                                : () => _openDetailSheet(
                                    context,
                                    title: 'Barang Belum Terjual',
                                    subtitle:
                                        '${unsoldRows.length} barang belum terjual bulan ini',
                                    rows: unsoldRows,
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _OpnameResultPanel(movements: monthlyOpnameMovements),
                    const SizedBox(height: 18),
                    Text(
                      'Opname Barang',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final row in rows)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _OpnameTile(row: row),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  List<_OpnameRow> _buildRows(
    List<Product> products,
    List<SalesTransaction> transactions,
  ) {
    return products.map((product) {
      final productTransactions = transactions.where((trx) {
        if (trx.barangId.isNotEmpty) return trx.barangId == product.id;
        return trx.namaBarang == product.namaBarang;
      });
      final qtySold = productTransactions.fold<int>(
        0,
        (sum, trx) => sum + trx.qty,
      );
      final revenue = productTransactions.fold<int>(
        0,
        (sum, trx) => sum + trx.totalHarga,
      );
      final storedProfit = productTransactions.fold<int>(
        0,
        (sum, trx) => sum + trx.effectiveLaba,
      );
      final profit = storedProfit != 0
          ? storedProfit
          : product.margin * qtySold;

      return _OpnameRow(
        product: product,
        qtySold: qtySold,
        revenue: revenue,
        profit: profit,
      );
    }).toList()..sort((a, b) {
      if (a.qtySold == 0 && b.qtySold != 0) return -1;
      if (a.qtySold != 0 && b.qtySold == 0) return 1;
      return b.profit.compareTo(a.profit);
    });
  }

  Future<void> _openDetailSheet(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<_OpnameRow> rows,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;
        return SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * .78,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final row = rows[index];
                      final product = row.product;
                      final isUnsold = row.qtySold == 0;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(alpha: .36),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isUnsold
                                  ? scheme.errorContainer
                                  : scheme.primaryContainer,
                              child: Icon(
                                isUnsold
                                    ? Icons.remove_shopping_cart_rounded
                                    : Icons.check_circle_rounded,
                                color: isUnsold ? scheme.error : scheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.namaBarang,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isUnsold
                                        ? 'Belum terjual'
                                        : '${row.qtySold} terjual | Laba ${AppFormatters.rupiah(row.profit)}',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Beli ${AppFormatters.rupiah(product.hargaBeli)} | Jual ${AppFormatters.rupiah(product.hargaJual)}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MonthPicker extends StatelessWidget {
  const _MonthPicker({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = AppFormatters.monthYear(month);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .4)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Bulan sebelumnya',
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          IconButton(
            tooltip: 'Bulan berikutnya',
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: .36),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpnameResultPanel extends StatelessWidget {
  const _OpnameResultPanel({required this.movements});

  final List<StockMovement> movements;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final totalReduced = movements.fold<int>(
      0,
      (sum, movement) => sum + movement.qty,
    );
    final affectedItems = movements
        .map((movement) => movement.namaBarang)
        .toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Hasil Stock Opname',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            Text(
              '${movements.length} catatan',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _OpnameResultStat(
                label: 'Stok Dikurangi',
                value: '$totalReduced item',
                icon: Icons.remove_shopping_cart_rounded,
                color: const Color(0xFFD95B5B),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OpnameResultStat(
                label: 'Barang Terdampak',
                value: '${affectedItems.length} barang',
                icon: Icons.inventory_2_outlined,
                color: AppTheme.brandPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (movements.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: .36),
              ),
            ),
            child: Text(
              'Belum ada stok rusak atau stok yang dikurangi pada bulan ini.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        else
          for (final movement in movements)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OpnameMovementTile(movement: movement),
            ),
      ],
    );
  }
}

class _OpnameResultStat extends StatelessWidget {
  const _OpnameResultStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
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

class _OpnameMovementTile extends StatelessWidget {
  const _OpnameMovementTile({required this.movement});

  final StockMovement movement;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final note = movement.note.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: scheme.errorContainer,
              child: Icon(
                Icons.report_gmailerrorred_rounded,
                color: scheme.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movement.namaBarang,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    note.isEmpty ? 'Tanpa keterangan' : note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppFormatters.date(movement.tanggal),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (movement.proofUrl.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _openProofPreview(context, movement),
                      icon: const Icon(Icons.image_rounded, size: 18),
                      label: const Text('Lihat bukti foto'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '-${movement.qty}',
              style: TextStyle(
                color: scheme.error,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openProofPreview(
    BuildContext context,
    StockMovement movement,
  ) async {
    final url = movement.proofUrl.trim();
    if (url.isEmpty) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(18),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        movement.namaBarang,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tutup',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              AspectRatio(
                aspectRatio: 1,
                child: InteractiveViewer(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Text('Bukti foto tidak bisa dimuat'),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Text(
                  movement.note.trim().isEmpty
                      ? AppFormatters.date(movement.tanggal)
                      : '${movement.note.trim()}\n${AppFormatters.date(movement.tanggal)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OpnameTile extends StatelessWidget {
  const _OpnameTile({required this.row});

  final _OpnameRow row;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final product = row.product;
    final isUnsold = row.qtySold == 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isUnsold
                  ? scheme.errorContainer
                  : scheme.primaryContainer,
              child: Icon(
                isUnsold
                    ? Icons.remove_shopping_cart_rounded
                    : Icons.attach_money_rounded,
                color: isUnsold ? scheme.error : scheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.namaBarang,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${row.qtySold} terjual | Laba ${AppFormatters.rupiah(row.profit)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Beli ${AppFormatters.rupiah(product.hargaBeli)} | Jual ${AppFormatters.rupiah(product.hargaJual)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: product.isActive,
              onChanged: (value) => _toggleActive(context, product, value),
            ),
            IconButton(
              tooltip: 'Catat stok rusak',
              onPressed: product.stok <= 0
                  ? null
                  : () => _openReduceStockSheet(context, product),
              icon: const Icon(Icons.report_gmailerrorred_rounded),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleActive(
    BuildContext context,
    Product product,
    bool value,
  ) async {
    try {
      await context.read<ProductProvider>().updateProductActive(
        product.id,
        value,
      );
      if (context.mounted) {
        showAppSnackBar(
          context,
          value ? 'Barang diaktifkan' : 'Barang di-off-kan',
        );
      }
    } catch (_) {
      if (context.mounted) {
        showAppSnackBar(context, 'Gagal mengubah status barang', isError: true);
      }
    }
  }

  Future<void> _openReduceStockSheet(
    BuildContext context,
    Product product,
  ) async {
    final productProvider = context.read<ProductProvider>();
    final userId = context.read<AuthProvider>().user?.id ?? '-';
    final overlayContext = Overlay.maybeOf(context)?.context;

    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => _ReduceStockSheet(
        product: product,
        onSubmit: (qty, note, proofUrl) {
          return productProvider.service.reduceStockForOpname(
            product: product,
            qty: qty,
            note: note,
            userId: userId,
            proofUrl: proofUrl,
          );
        },
      ),
    );

    if (success != true) return;

    final toastContext = overlayContext?.mounted == true
        ? overlayContext!
        : context;
    if (toastContext.mounted) {
      showAppSnackBar(toastContext, 'Stok berhasil dikurangi');
    }
  }
}

class _ReduceStockSheet extends StatefulWidget {
  const _ReduceStockSheet({required this.product, required this.onSubmit});

  final Product product;
  final Future<void> Function(int qty, String note, String proofUrl) onSubmit;

  @override
  State<_ReduceStockSheet> createState() => _ReduceStockSheetState();
}

class _ReduceStockSheetState extends State<_ReduceStockSheet> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();
  final _noteController = TextEditingController();
  final _picker = ImagePicker();
  final _cloudinaryService = CloudinaryService();
  Uint8List? _proofBytes;
  String? _proofFileName;
  bool _isSaving = false;

  @override
  void dispose() {
    _qtyController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickProof(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1400,
    );
    if (image == null) return;

    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() {
      _proofBytes = bytes;
      _proofFileName = image.name;
    });
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    final proofBytes = _proofBytes;
    final proofFileName = _proofFileName;
    if (proofBytes == null || proofFileName == null) {
      showAppSnackBar(context, 'Lampirkan foto bukti dulu', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final proofUrl = await _cloudinaryService.uploadOpnameProof(
        bytes: proofBytes,
        fileName: proofFileName,
      );
      if (proofUrl.isEmpty) {
        throw Exception('Upload bukti opname tidak menghasilkan URL.');
      }
      await widget.onSubmit(
        int.parse(_qtyController.text.trim()),
        _noteController.text.trim(),
        proofUrl,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showAppSnackBar(
        context,
        error.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final product = widget.product;

    return Padding(
      padding: EdgeInsets.fromLTRB(18, 6, 18, bottom + 18),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Catat Stok Tidak Layak',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                '${product.namaBarang} - stok saat ini ${product.stok}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _qtyController,
                enabled: !_isSaving,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah stok dikurangi',
                  prefixIcon: Icon(Icons.remove_circle_outline_rounded),
                ),
                validator: (value) {
                  final qty = int.tryParse(value?.trim() ?? '');
                  if (qty == null) return 'Jumlah harus berupa angka';
                  if (qty <= 0) return 'Jumlah harus lebih dari 0';
                  if (qty > product.stok) {
                    return 'Jumlah melebihi stok tersedia';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                enabled: !_isSaving,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Keterangan',
                  hintText: 'Contoh: stok ini rusak',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Keterangan wajib diisi'
                    : null,
              ),
              const SizedBox(height: 18),
              _OpnameProofPicker(
                bytes: _proofBytes,
                isDisabled: _isSaving,
                onCamera: () => _pickProof(ImageSource.camera),
                onGallery: () => _pickProof(ImageSource.gallery),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(
                  _isSaving ? 'Menyimpan...' : 'Simpan Pengurangan Stok',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpnameProofPicker extends StatelessWidget {
  const _OpnameProofPicker({
    required this.bytes,
    required this.isDisabled,
    required this.onCamera,
    required this.onGallery,
  });

  final Uint8List? bytes;
  final bool isDisabled;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .6)),
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: bytes == null
                ? ColoredBox(
                    color: scheme.surfaceContainerHighest.withValues(
                      alpha: .45,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_rounded,
                            size: 42,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Lampiran foto bukti',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  )
                : Image.memory(bytes!, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isDisabled ? null : onGallery,
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Galeri'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isDisabled ? null : onCamera,
                    icon: const Icon(Icons.photo_camera_rounded),
                    label: const Text('Foto'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OpnameRow {
  const _OpnameRow({
    required this.product,
    required this.qtySold,
    required this.revenue,
    required this.profit,
  });

  final Product product;
  final int qtySold;
  final int revenue;
  final int profit;
}

class _MonthRange {
  const _MonthRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  bool contains(DateTime date) {
    return !date.isBefore(start) && date.isBefore(end);
  }

  factory _MonthRange.from(DateTime month) {
    final start = DateTime(month.year, month.month);
    return _MonthRange(
      start: start,
      end: DateTime(month.year, month.month + 1),
    );
  }
}
