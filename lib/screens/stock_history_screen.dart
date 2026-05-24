import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/stock_movement.dart';
import '../providers/product_provider.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';

class StockHistoryScreen extends StatelessWidget {
  const StockHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StockMovement>>(
      stream: context.read<ProductProvider>().watchRestockMovements(),
      builder: (context, restockSnapshot) {
        return StreamBuilder<List<StockMovement>>(
          stream: context.read<ProductProvider>().watchSalesMovements(),
          builder: (context, salesSnapshot) {
            if (!restockSnapshot.hasData || !salesSnapshot.hasData) {
              return const AppLoadingIndicator();
            }

            final movements = [...restockSnapshot.data!, ...salesSnapshot.data!]
              ..sort((a, b) => b.tanggal.compareTo(a.tanggal));

            final totalMasuk = movements
                .where((movement) => movement.type == StockMovementType.masuk)
                .fold<int>(0, (sum, movement) => sum + movement.qty);
            final totalKeluar = movements
                .where((movement) => movement.type == StockMovementType.keluar)
                .fold<int>(0, (sum, movement) => sum + movement.qty);

            if (movements.isEmpty) {
              return const EmptyState(
                icon: Icons.history_rounded,
                title: 'Riwayat stok kosong',
                subtitle:
                    'Barang masuk dan penjualan akan muncul di halaman ini.',
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SummaryTile(
                        label: 'Masuk',
                        value: '$totalMasuk item',
                        icon: Icons.call_received_rounded,
                        color: const Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryTile(
                        label: 'Keluar',
                        value: '$totalKeluar item',
                        icon: Icons.call_made_rounded,
                        color: const Color(0xFFD95B5B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Riwayat Stok',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                for (final movement in movements)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _MovementTile(movement: movement),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(label, style: TextStyle(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({required this.movement});

  final StockMovement movement;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isIn = movement.type == StockMovementType.masuk;
    final color = isIn ? scheme.primary : scheme.error;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: .12),
          child: Icon(
            isIn ? Icons.add_rounded : Icons.remove_rounded,
            color: color,
          ),
        ),
        title: Text(
          movement.namaBarang,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(AppFormatters.date(movement.tanggal)),
        trailing: Text(
          '${isIn ? '+' : '-'}${movement.qty}',
          style: TextStyle(color: color, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
