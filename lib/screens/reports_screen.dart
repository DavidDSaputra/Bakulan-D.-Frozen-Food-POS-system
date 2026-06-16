import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sales_transaction.dart';
import '../providers/sales_provider.dart';
import '../services/report_excel_service.dart';
import '../services/report_pdf_service.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/snackbar.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/stat_card.dart';
import 'transaction_detail_screen.dart';

enum ReportPeriod { daily, weekly, monthly, yearly, customDate }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _reportExcelService = ReportExcelService();
  final _reportPdfService = ReportPdfService();

  ReportPeriod _period = ReportPeriod.daily;
  DateTime _anchorDate = DateTime.now();
  bool _isExportingExcel = false;
  bool _isExportingPdf = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SalesTransaction>>(
      stream: context.read<SalesProvider>().watchTransactions(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Laporan belum bisa dimuat',
            subtitle: 'Periksa koneksi atau izin data transaksi.',
          );
        }

        if (!snapshot.hasData) return const AppLoadingIndicator();
        final transactions = snapshot.data ?? const <SalesTransaction>[];

        if (transactions.isEmpty) {
          return const EmptyState(
            icon: Icons.receipt_long_rounded,
            title: 'Laporan masih kosong',
            subtitle: 'Data laporan akan terisi setelah transaksi berhasil.',
          );
        }

        final range = _periodRange(_anchorDate);
        final filteredTransactions = _filterTransactions(transactions, range);
        final revenue = filteredTransactions.fold<int>(
          0,
          (sum, trx) => sum + trx.totalHarga,
        );
        final profit = filteredTransactions.fold<int>(
          0,
          (sum, trx) => sum + trx.effectiveLaba,
        );
        final totalQty = filteredTransactions.fold<int>(
          0,
          (sum, trx) => sum + trx.qty,
        );
        final statCards = [
          StatCard(
            title: 'Total Omzet',
            value: AppFormatters.rupiah(revenue),
            icon: Icons.payments_rounded,
            color: const Color(0xFF27AE60),
          ),
          StatCard(
            title: 'Item Terjual',
            value: '$totalQty',
            icon: Icons.shopping_cart_checkout_rounded,
            color: const Color(0xFF3B82C4),
          ),
          StatCard(
            title: 'Laba Kotor',
            value: AppFormatters.rupiah(profit),
            icon: Icons.trending_up_rounded,
            color: AppTheme.brandPrimary,
          ),
        ];

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          children: [
            _PeriodSelector(
              selected: _period,
              onChanged: (value) => setState(() => _period = value),
            ),
            const SizedBox(height: 12),
            _ReportToolbar(
              rangeLabel: _rangeLabel(range),
              isExportingExcel: _isExportingExcel,
              isExportingPdf: _isExportingPdf,
              onPickDate: _pickDate,
              onExportExcel: () => _exportExcel(filteredTransactions, range),
              onExportPdf: () => _exportPdf(filteredTransactions, range),
            ),
            const SizedBox(height: 14),
            _StatCardGrid(children: statCards),
            const SizedBox(height: 16),
            _RevenueChart(
              points: _buildChartPoints(filteredTransactions),
              title: 'Grafik Omzet ${_periodLabel(_period)}',
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Riwayat Penjualan',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '${filteredTransactions.length} data',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (filteredTransactions.isEmpty)
              const SizedBox(
                height: 220,
                child: EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Tidak ada transaksi',
                  subtitle: 'Belum ada transaksi pada periode ini.',
                ),
              )
            else
              ...filteredTransactions.map(
                (trx) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TransactionDetailScreen(transaction: trx),
                          ),
                        );
                      },
                      leading: CircleAvatar(
                        child: Icon(
                          (trx.paymentProofUrl ?? '').trim().isNotEmpty
                              ? Icons.verified_rounded
                              : Icons.receipt_rounded,
                        ),
                      ),
                      title: Text(
                        trx.namaBarang,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${AppFormatters.date(trx.tanggal)} - ${trx.metodePembayaran}',
                      ),
                      isThreeLine: false,
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

  Future<void> _exportExcel(
    List<SalesTransaction> transactions,
    _ReportRange range,
  ) async {
    if (transactions.isEmpty) {
      showAppSnackBar(
        context,
        'Belum ada transaksi pada periode ini',
        isError: true,
      );
      return;
    }

    setState(() => _isExportingExcel = true);
    try {
      await _reportExcelService.shareReport(
        transactions: transactions,
        periodLabel: _periodLabel(_period),
        startDate: range.start,
        endDate: range.end,
      );
      if (!mounted) return;
      showAppSnackBar(context, 'Excel laporan berhasil dibuat');
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(context, 'Gagal membuat Excel laporan', isError: true);
    } finally {
      if (mounted) setState(() => _isExportingExcel = false);
    }
  }

  Future<void> _exportPdf(
    List<SalesTransaction> transactions,
    _ReportRange range,
  ) async {
    if (transactions.isEmpty) {
      showAppSnackBar(
        context,
        'Belum ada transaksi pada periode ini',
        isError: true,
      );
      return;
    }

    setState(() => _isExportingPdf = true);
    try {
      await _reportPdfService.shareReport(
        transactions: transactions,
        periodLabel: _periodLabel(_period),
        startDate: range.start,
        endDate: range.end,
      );
      if (!mounted) return;
      showAppSnackBar(context, 'PDF laporan berhasil dibuat');
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(context, 'Gagal membuat PDF laporan', isError: true);
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  List<SalesTransaction> _filterTransactions(
    List<SalesTransaction> transactions,
    _ReportRange range,
  ) {
    return transactions
        .where(
          (trx) =>
              !trx.tanggal.isBefore(range.start) &&
              trx.tanggal.isBefore(range.end),
        )
        .toList()
      ..sort((a, b) => b.tanggal.compareTo(a.tanggal));
  }

  _ReportRange _periodRange(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final start = switch (_period) {
      ReportPeriod.daily => today,
      ReportPeriod.customDate => today,
      ReportPeriod.weekly => today.subtract(Duration(days: now.weekday - 1)),
      ReportPeriod.monthly => DateTime(now.year, now.month),
      ReportPeriod.yearly => DateTime(now.year),
    };
    final end = switch (_period) {
      ReportPeriod.daily => start.add(const Duration(days: 1)),
      ReportPeriod.customDate => start.add(const Duration(days: 1)),
      ReportPeriod.weekly => start.add(const Duration(days: 7)),
      ReportPeriod.monthly => DateTime(start.year, start.month + 1),
      ReportPeriod.yearly => DateTime(start.year + 1),
    };

    return _ReportRange(start: start, end: end);
  }

  String _rangeLabel(_ReportRange range) {
    final lastDate = range.end.subtract(const Duration(days: 1));
    return '${AppFormatters.date(range.start).split(',').first} - '
        '${AppFormatters.date(lastDate).split(',').first}';
  }

  List<_ChartPoint> _buildChartPoints(List<SalesTransaction> transactions) {
    final totals = <String, int>{};

    for (final trx in transactions) {
      final key = switch (_period) {
        ReportPeriod.customDate => trx.tanggal.hour.toString().padLeft(2, '0'),
        ReportPeriod.daily => trx.tanggal.hour.toString().padLeft(2, '0'),
        ReportPeriod.weekly => _weekdayLabel(trx.tanggal.weekday),
        ReportPeriod.monthly => trx.tanggal.day.toString(),
        ReportPeriod.yearly => trx.tanggal.month.toString(),
      };
      totals[key] = (totals[key] ?? 0) + trx.totalHarga;
    }

    if (_period == ReportPeriod.daily || _period == ReportPeriod.customDate) {
      return [
        for (var hour = 0; hour < 24; hour += 4)
          _ChartPoint(
            label: hour.toString().padLeft(2, '0'),
            value: totals[hour.toString().padLeft(2, '0')] ?? 0,
          ),
      ];
    }

    if (_period == ReportPeriod.weekly) {
      const labels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
      return [
        for (final label in labels)
          _ChartPoint(label: label, value: totals[label] ?? 0),
      ];
    }

    if (_period == ReportPeriod.yearly) {
      const labels = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      return [
        for (var month = 1; month <= 12; month++)
          _ChartPoint(label: labels[month - 1], value: totals['$month'] ?? 0),
      ];
    }

    final daysInMonth = DateUtils.getDaysInMonth(
      _anchorDate.year,
      _anchorDate.month,
    );
    return [
      for (var day = 1; day <= daysInMonth; day += 5)
        _ChartPoint(label: '$day', value: totals['$day'] ?? 0),
    ];
  }

  String _weekdayLabel(int weekday) {
    const labels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return labels[weekday - 1];
  }

  String _periodLabel(ReportPeriod period) {
    return switch (period) {
      ReportPeriod.daily => 'Harian',
      ReportPeriod.customDate => 'Tanggal',
      ReportPeriod.weekly => 'Mingguan',
      ReportPeriod.monthly => 'Bulanan',
      ReportPeriod.yearly => 'Tahunan',
    };
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _anchorDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 2, 12, 31),
    );
    if (picked == null) return;
    setState(() {
      _anchorDate = picked;
      _period = ReportPeriod.customDate;
    });
  }
}

class _ReportRange {
  const _ReportRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

double _responsiveItemWidth({
  required int index,
  required int itemCount,
  required int columns,
  required double maxWidth,
  required double spacing,
}) {
  final safeColumns = columns <= 0 ? 1 : columns;
  final baseWidth = (maxWidth - (spacing * (safeColumns - 1))) / safeColumns;
  final itemsInLastRow = itemCount % safeColumns;
  if (itemsInLastRow == 0) return baseWidth;

  final lastRowStart = itemCount - itemsInLastRow;
  if (index < lastRowStart) return baseWidth;

  return (maxWidth - (spacing * (itemsInLastRow - 1))) / itemsInLastRow;
}

class _PeriodOption {
  const _PeriodOption({
    required this.value,
    required this.label,
    required this.icon,
  });

  final ReportPeriod value;
  final String label;
  final IconData icon;
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onChanged});

  final ReportPeriod selected;
  final ValueChanged<ReportPeriod> onChanged;

  static const _options = [
    _PeriodOption(
      value: ReportPeriod.daily,
      label: 'Hari',
      icon: Icons.today_rounded,
    ),
    _PeriodOption(
      value: ReportPeriod.weekly,
      label: 'Minggu',
      icon: Icons.view_week_rounded,
    ),
    _PeriodOption(
      value: ReportPeriod.monthly,
      label: 'Bulan',
      icon: Icons.calendar_month_rounded,
    ),
    _PeriodOption(
      value: ReportPeriod.yearly,
      label: 'Tahun',
      icon: Icons.event_available_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final columns = maxWidth >= 420 ? 3 : 2;
        const spacing = 8.0;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var index = 0; index < _options.length; index++)
              SizedBox(
                width: _responsiveItemWidth(
                  index: index,
                  itemCount: _options.length,
                  columns: columns,
                  maxWidth: maxWidth,
                  spacing: spacing,
                ),
                child: _PeriodButton(
                  option: _options[index],
                  isSelected: _options[index].value == selected,
                  onPressed: () => onChanged(_options[index].value),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PeriodButton extends StatelessWidget {
  const _PeriodButton({
    required this.option,
    required this.isSelected,
    required this.onPressed,
  });

  final _PeriodOption option;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = isSelected
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;

    return Material(
      color: isSelected ? scheme.primaryContainer : scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? scheme.primary.withValues(alpha: .24)
                  : scheme.outlineVariant.withValues(alpha: .55),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(option.icon, size: 18, color: foreground),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w800,
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

class _ReportToolbar extends StatelessWidget {
  const _ReportToolbar({
    required this.rangeLabel,
    required this.isExportingExcel,
    required this.isExportingPdf,
    required this.onPickDate,
    required this.onExportExcel,
    required this.onExportPdf,
  });

  final String rangeLabel;
  final bool isExportingExcel;
  final bool isExportingPdf;
  final VoidCallback onPickDate;
  final VoidCallback onExportExcel;
  final VoidCallback onExportPdf;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );
    final actions = [
      _ExportButton(
        label: 'Tanggal',
        icon: Icons.calendar_month_rounded,
        isLoading: false,
        isDisabled: isExportingExcel || isExportingPdf,
        onPressed: onPickDate,
        isPrimary: false,
      ),
      _ExportButton(
        label: 'Excel',
        icon: Icons.table_chart_rounded,
        isLoading: isExportingExcel,
        isDisabled: isExportingExcel || isExportingPdf,
        onPressed: onExportExcel,
        isPrimary: false,
      ),
      _ExportButton(
        label: 'PDF',
        icon: Icons.picture_as_pdf_rounded,
        isLoading: isExportingPdf,
        isDisabled: isExportingExcel || isExportingPdf,
        onPressed: onExportPdf,
        isPrimary: true,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: .42),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.date_range_rounded,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rangeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: labelStyle,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final columns = maxWidth >= 430 ? 3 : 2;
            const spacing = 8.0;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (var index = 0; index < actions.length; index++)
                  SizedBox(
                    width: _responsiveItemWidth(
                      index: index,
                      itemCount: actions.length,
                      columns: columns,
                      maxWidth: maxWidth,
                      spacing: spacing,
                    ),
                    child: actions[index],
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.isDisabled,
    required this.onPressed,
    required this.isPrimary,
  });

  final String label;
  final IconData icon;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final buttonStyle = isPrimary
        ? FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(42),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          )
        : OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(42),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          );

    final child = SizedBox(
      width: double.infinity,
      child: isPrimary
          ? FilledButton.icon(
              style: buttonStyle,
              onPressed: isDisabled ? null : onPressed,
              icon: _buttonIcon(),
              label: Text(label, softWrap: false),
            )
          : OutlinedButton.icon(
              style: buttonStyle,
              onPressed: isDisabled ? null : onPressed,
              icon: _buttonIcon(),
              label: Text(label, softWrap: false),
            ),
    );

    return Tooltip(message: 'Export $label', child: child);
  }

  Widget _buttonIcon() {
    if (!isLoading) return Icon(icon);
    return const SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}

class _StatCardGrid extends StatelessWidget {
  const _StatCardGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final columns = maxWidth >= 560 ? 3 : 2;
        const spacing = 12.0;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var index = 0; index < children.length; index++)
              SizedBox(
                width: _responsiveItemWidth(
                  index: index,
                  itemCount: children.length,
                  columns: columns,
                  maxWidth: maxWidth,
                  spacing: spacing,
                ),
                height: 136,
                child: children[index],
              ),
          ],
        );
      },
    );
  }
}

class _ChartPoint {
  const _ChartPoint({required this.label, required this.value});

  final String label;
  final int value;
}

class _RevenueChart extends StatelessWidget {
  const _RevenueChart({required this.points, required this.title});

  final List<_ChartPoint> points;
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxValue = points.fold<int>(
      0,
      (max, point) => point.value > max ? point.value : max,
    );
    final chartMax = maxValue <= 0 ? 1 : maxValue;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 170,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final point in points)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _BarPoint(
                        point: point,
                        maxValue: chartMax,
                        color: scheme.primary,
                        emptyColor: scheme.outlineVariant.withValues(
                          alpha: .36,
                        ),
                      ),
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

class _BarPoint extends StatelessWidget {
  const _BarPoint({
    required this.point,
    required this.maxValue,
    required this.color,
    required this.emptyColor,
  });

  final _ChartPoint point;
  final int maxValue;
  final Color color;
  final Color emptyColor;

  @override
  Widget build(BuildContext context) {
    final heightFactor = point.value <= 0 ? 0.0 : point.value / maxValue;

    return Column(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: heightFactor.clamp(.0, 1.0),
              widthFactor: .82,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: point.value <= 0 ? emptyColor : color,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 18,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              point.label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      ],
    );
  }
}
