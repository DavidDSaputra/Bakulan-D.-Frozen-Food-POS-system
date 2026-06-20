import 'package:flutter/material.dart';

import '../models/activity_log.dart';
import '../services/firestore_service.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  final _service = FirestoreService();
  String? _selectedUserId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Aktivitas')),
      body: StreamBuilder<List<ActivityLog>>(
        stream: _service.watchActivityLogs(limit: 300),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const AppLoadingIndicator();
          final logs = snapshot.data!;

          if (logs.isEmpty) {
            return const EmptyState(
              icon: Icons.history_toggle_off_rounded,
              title: 'Belum ada log aktivitas',
              subtitle: 'Aktivitas akun dan transaksi akan muncul di sini.',
            );
          }

          final users = <String, String>{};
          for (final log in logs) {
            users[log.userId] = log.userName;
          }

          final filteredLogs = _selectedUserId == null
              ? logs
              : logs.where((log) => log.userId == _selectedUserId).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              DropdownButtonFormField<String?>(
                initialValue: _selectedUserId,
                decoration: const InputDecoration(
                  labelText: 'Filter akun',
                  prefixIcon: Icon(Icons.person_search_rounded),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Semua akun'),
                  ),
                  ...users.entries.map(
                    (entry) => DropdownMenuItem<String?>(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _selectedUserId = value),
              ),
              const SizedBox(height: 16),
              for (final log in filteredLogs) ...[
                _ActivityLogTile(log: log),
                const SizedBox(height: 10),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ActivityLogTile extends StatelessWidget {
  const _ActivityLogTile({required this.log});

  final ActivityLog log;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final badgeColor = _badgeColor(log.action, scheme);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      log.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _actionLabel(log.action),
                  style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(icon: Icons.badge_outlined, label: log.userName),
              _MetaChip(icon: Icons.fingerprint_rounded, label: log.userId),
              _MetaChip(
                icon: Icons.schedule_rounded,
                label: AppFormatters.date(log.timestamp),
              ),
            ],
          ),
          if (log.metadata.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ActivityDetailSection(log: log),
          ],
        ],
      ),
    );
  }

  Color _badgeColor(String action, ColorScheme scheme) {
    if (action.contains('delete') || action.contains('reduce')) {
      return scheme.error;
    }
    if (action.contains('create') ||
        action.contains('add') ||
        action == 'login') {
      return scheme.primary;
    }
    return scheme.secondary;
  }

  String _actionLabel(String action) {
    return switch (action) {
      'login' => 'Login',
      'logout' => 'Logout',
      'sale_create' => 'Transaksi',
      'stock_add' => 'Tambah Stok',
      'stock_reduce' => 'Kurangi Stok',
      'product_create' => 'Tambah Barang',
      'product_update' => 'Edit Barang',
      'product_delete' => 'Hapus Barang',
      'product_activate' => 'Aktifkan',
      'product_deactivate' => 'Nonaktifkan',
      'account_create' => 'Buat Akun',
      _ => action,
    };
  }
}

class _ActivityDetailSection extends StatelessWidget {
  const _ActivityDetailSection({required this.log});

  final ActivityLog log;

  @override
  Widget build(BuildContext context) {
    final rows = _detailRows();
    final lineItems = _lineItems();

    if (rows.isEmpty && lineItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: .34),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (rows.isNotEmpty)
            for (final row in rows) ...[
              _DetailRow(label: row.label, value: row.value),
              if (row != rows.last) const SizedBox(height: 8),
            ],
          if (lineItems.isNotEmpty) ...[
            if (rows.isNotEmpty) const SizedBox(height: 12),
            Text(
              'Rincian Item',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            for (final item in lineItems) ...[
              _LineItemCard(item: item),
              if (item != lineItems.last) const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }

  List<_DetailEntry> _detailRows() {
    final metadata = log.metadata;
    return switch (log.action) {
      'sale_create' => [
        if (metadata['qty_total'] != null)
          _DetailEntry(
            label: 'Total Item',
            value:
                '${AppFormatters.number(_readInt(metadata['qty_total']))} item',
          ),
        if (metadata['metode_pembayaran'] != null)
          _DetailEntry(
            label: 'Metode Bayar',
            value: metadata['metode_pembayaran'].toString(),
          ),
        if (metadata['total_harga'] != null)
          _DetailEntry(
            label: 'Total Belanja',
            value: AppFormatters.rupiah(_readInt(metadata['total_harga'])),
          ),
        if (_lineItems().isEmpty && metadata['barang'] != null)
          _DetailEntry(
            label: 'Daftar Barang',
            value: metadata['barang'].toString(),
          ),
      ],
      'stock_add' || 'stock_reduce' => [
        if (metadata['nama_barang'] != null)
          _DetailEntry(
            label: 'Barang',
            value: metadata['nama_barang'].toString(),
          ),
        if (metadata['qty'] != null)
          _DetailEntry(
            label: 'Jumlah',
            value: AppFormatters.number(_readInt(metadata['qty'])),
          ),
        if (metadata['stok_awal'] != null)
          _DetailEntry(
            label: 'Stok Awal',
            value: AppFormatters.number(_readInt(metadata['stok_awal'])),
          ),
        if (metadata['stok_akhir'] != null)
          _DetailEntry(
            label: 'Stok Akhir',
            value: AppFormatters.number(_readInt(metadata['stok_akhir'])),
          ),
        if ((metadata['keterangan']?.toString().trim() ?? '').isNotEmpty)
          _DetailEntry(
            label: 'Keterangan',
            value: metadata['keterangan'].toString(),
          ),
      ],
      'product_create' || 'product_update' => [
        if (metadata['nama_barang'] != null)
          _DetailEntry(
            label: 'Barang',
            value: metadata['nama_barang'].toString(),
          ),
        if (metadata['stok'] != null)
          _DetailEntry(
            label: 'Stok',
            value: AppFormatters.number(_readInt(metadata['stok'])),
          ),
        if (metadata['harga_jual'] != null)
          _DetailEntry(
            label: 'Harga Jual',
            value: AppFormatters.rupiah(_readInt(metadata['harga_jual'])),
          ),
      ],
      'product_delete' => [
        if (metadata['nama_barang'] != null)
          _DetailEntry(
            label: 'Barang',
            value: metadata['nama_barang'].toString(),
          ),
      ],
      'account_create' => [
        if (metadata['username'] != null)
          _DetailEntry(
            label: 'Username',
            value: metadata['username'].toString(),
          ),
        if (metadata['role'] != null)
          _DetailEntry(label: 'Role', value: metadata['role'].toString()),
      ],
      _ => _genericRows(metadata),
    };
  }

  List<Map<String, dynamic>> _lineItems() {
    final raw = log.metadata['line_items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<_DetailEntry> _genericRows(Map<String, dynamic> metadata) {
    final ignoredKeys = {'line_items'};
    return metadata.entries
        .where((entry) => !ignoredKeys.contains(entry.key))
        .map(
          (entry) => _DetailEntry(
            label: _readableLabel(entry.key),
            value: entry.value.toString(),
          ),
        )
        .toList();
  }

  int _readInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _readableLabel(String raw) {
    return raw
        .split('_')
        .map((part) {
          if (part.isEmpty) return part;
          return '${part[0].toUpperCase()}${part.substring(1)}';
        })
        .join(' ');
  }
}

class _DetailEntry {
  const _DetailEntry({required this.label, required this.value});

  final String label;
  final String value;
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _LineItemCard extends StatelessWidget {
  const _LineItemCard({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final itemName = item['nama_barang']?.toString() ?? '-';
    final qty = _readInt(item['qty']);
    final subtotal = _readInt(item['subtotal']);
    final unitPrice = _readInt(item['harga_jual']);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            itemName,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            '${AppFormatters.number(qty)} x ${AppFormatters.rupiah(unitPrice)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppFormatters.rupiah(subtotal),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  int _readInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
