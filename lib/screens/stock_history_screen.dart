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
            return StreamBuilder<List<StockMovement>>(
              stream: context.read<ProductProvider>().watchOpnameMovements(),
              builder: (context, opnameSnapshot) {
                final hasAnyData =
                    restockSnapshot.hasData ||
                    salesSnapshot.hasData ||
                    opnameSnapshot.hasData;

                if (!hasAnyData) {
                  return const AppLoadingIndicator();
                }

                final movements = [
                  ...(restockSnapshot.data ?? const <StockMovement>[]),
                  ...(salesSnapshot.data ?? const <StockMovement>[]),
                  ...(opnameSnapshot.data ?? const <StockMovement>[]),
                ]..sort((a, b) => b.tanggal.compareTo(a.tanggal));

                if (movements.isEmpty) {
                  return const EmptyState(
                    icon: Icons.history_rounded,
                    title: 'Riwayat stok kosong',
                    subtitle:
                        'Barang masuk, penjualan, dan opname akan muncul di halaman ini.',
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
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
      },
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
    final sourceLabel = switch (movement.source) {
      StockMovementSource.restock => 'Barang masuk',
      StockMovementSource.sale => 'Penjualan',
      StockMovementSource.opname => 'Opname',
    };
    final note = movement.note.trim();
    final actorLabel =
        movement.userName.trim().isEmpty || movement.userName == '-'
        ? ''
        : ' oleh ${movement.userName.trim()}';

    return Card(
      child: ListTile(
        onTap: () => _showMovementDetail(context, movement),
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
        subtitle: Text(
          note.isEmpty
              ? '$sourceLabel$actorLabel - ${AppFormatters.date(movement.tanggal)}'
              : '$sourceLabel$actorLabel - $note\n${AppFormatters.date(movement.tanggal)}',
        ),
        isThreeLine: note.isNotEmpty,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${isIn ? '+' : '-'}${AppFormatters.number(movement.qty)}',
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  void _showMovementDetail(BuildContext context, StockMovement movement) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _MovementDetailSheet(movement: movement),
    );
  }
}

class _MovementDetailSheet extends StatelessWidget {
  const _MovementDetailSheet({required this.movement});

  final StockMovement movement;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isIn = movement.type == StockMovementType.masuk;
    final color = isIn ? scheme.primary : scheme.error;
    final sourceLabel = switch (movement.source) {
      StockMovementSource.restock => 'Barang masuk',
      StockMovementSource.sale => 'Penjualan',
      StockMovementSource.opname => 'Opname',
    };
    final typeLabel = isIn ? 'Stok masuk' : 'Stok keluar';
    final signedQty =
        '${isIn ? '+' : '-'}${AppFormatters.number(movement.qty)}';
    final note = movement.note.trim().isEmpty ? '-' : movement.note.trim();
    final actor = movement.userName.trim().isEmpty ? '-' : movement.userName;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: .12),
                  child: Icon(
                    isIn ? Icons.add_rounded : Icons.remove_rounded,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movement.namaBarang,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        sourceLabel,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Text(
                  signedQty,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _DetailRow(label: 'Jenis', value: typeLabel),
            _DetailRow(
              label: 'Tanggal',
              value: AppFormatters.date(movement.tanggal),
            ),
            _DetailRow(label: 'Petugas', value: actor),
            _DetailRow(label: 'Catatan', value: note),
            if (movement.proofUrl.trim().isNotEmpty)
              _DetailRow(label: 'Bukti', value: movement.proofUrl.trim()),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
