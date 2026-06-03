import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sales_transaction.dart';
import '../providers/sales_provider.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/stat_card.dart';

enum ReportPeriod { daily, weekly, monthly }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportPeriod _period = ReportPeriod.daily;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SalesTransaction>>(
      stream: context.read<SalesProvider>().watchTransactions(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const AppLoadingIndicator();
        final transactions = snapshot.data!;

        if (transactions.isEmpty) {
          return const EmptyState(
            icon: Icons.receipt_long_rounded,
            title: 'Laporan masih kosong',
            subtitle: 'Data laporan akan terisi setelah transaksi berhasil.',
          );
        }

        final filteredTransactions = _filterTransactions(transactions);
        final revenue = filteredTransactions.fold<int>(
          0,
          (sum, trx) => sum + trx.totalHarga,
        );
        final totalQty = filteredTransactions.fold<int>(
          0,
          (sum, trx) => sum + trx.qty,
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            SegmentedButton<ReportPeriod>(
              segments: const [
                ButtonSegment(
                  value: ReportPeriod.daily,
                  label: Text('Harian'),
                  icon: Icon(Icons.today_rounded),
                ),
                ButtonSegment(
                  value: ReportPeriod.weekly,
                  label: Text('Mingguan'),
                  icon: Icon(Icons.view_week_rounded),
                ),
                ButtonSegment(
                  value: ReportPeriod.monthly,
                  label: Text('Bulanan'),
                  icon: Icon(Icons.calendar_month_rounded),
                ),
              ],
              selected: {_period},
              onSelectionChanged: (value) =>
                  setState(() => _period = value.first),
            ),
            const SizedBox(height: 14),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: .94,
              ),
              children: [
                StatCard(
                  title: 'Total Omzet',
                  value: AppFormatters.rupiah(revenue),
                  icon: Icons.payments_rounded,
                  color: const Color(0xFF1565C0),
                ),
                StatCard(
                  title: 'Item Terjual',
                  value: '$totalQty',
                  icon: Icons.shopping_cart_checkout_rounded,
                  color: const Color(0xFF3B82C4),
                ),
              ],
            ),
            const SizedBox(height: 18),
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

  List<SalesTransaction> _filterTransactions(
    List<SalesTransaction> transactions,
  ) {
    final now = DateTime.now();
    final start = switch (_period) {
      ReportPeriod.daily => DateTime(now.year, now.month, now.day),
      ReportPeriod.weekly => DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1)),
      ReportPeriod.monthly => DateTime(now.year, now.month),
    };

    return transactions.where((trx) => !trx.tanggal.isBefore(start)).toList()
      ..sort((a, b) => b.tanggal.compareTo(a.tanggal));
  }

  List<_ChartPoint> _buildChartPoints(List<SalesTransaction> transactions) {
    final totals = <String, int>{};

    for (final trx in transactions) {
      final key = switch (_period) {
        ReportPeriod.daily => trx.tanggal.hour.toString().padLeft(2, '0'),
        ReportPeriod.weekly => _weekdayLabel(trx.tanggal.weekday),
        ReportPeriod.monthly => trx.tanggal.day.toString(),
      };
      totals[key] = (totals[key] ?? 0) + trx.totalHarga;
    }

    if (_period == ReportPeriod.daily) {
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

    final daysInMonth = DateUtils.getDaysInMonth(
      DateTime.now().year,
      DateTime.now().month,
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
      ReportPeriod.weekly => 'Mingguan',
      ReportPeriod.monthly => 'Bulanan',
    };
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

    return Container(
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 16),
          SizedBox(
            height: 190,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue == 0 ? 100000 : maxValue * 1.2,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= points.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            points[index].label,
                            style: const TextStyle(fontSize: 11),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < points.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: points[i].value.toDouble(),
                          width: 16,
                          borderRadius: BorderRadius.circular(6),
                          color: scheme.primary,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
