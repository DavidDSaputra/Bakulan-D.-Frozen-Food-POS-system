import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../models/cashier_shift.dart';
import '../providers/auth_provider.dart';
import '../providers/operations_provider.dart';
import '../utils/formatters.dart';
import '../utils/number_input_formatter.dart';
import '../utils/snackbar.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';

class ShiftManagementScreen extends StatelessWidget {
  const ShiftManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final actor = context.watch<AuthProvider>().user;
    if (actor == null) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.point_of_sale_rounded,
          title: 'Sesi tidak ditemukan',
          subtitle: 'Silakan login kembali untuk mengakses shift kasir.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Shift Kasir')),
      body: StreamBuilder<CashierShift?>(
        stream: context.read<OperationsProvider>().watchActiveShift(actor.id),
        builder: (context, activeSnapshot) {
          return StreamBuilder<List<CashierShift>>(
            stream: context.read<OperationsProvider>().watchShiftHistory(
              limit: 80,
            ),
            builder: (context, historySnapshot) {
              if (!historySnapshot.hasData) return const AppLoadingIndicator();
              final activeShift = activeSnapshot.data;
              final shifts = historySnapshot.data!;

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _ActiveShiftCard(actor: actor, shift: activeShift),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Riwayat Shift',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Text(
                        '${shifts.length} data',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (shifts.isEmpty)
                    const SizedBox(
                      height: 220,
                      child: EmptyState(
                        icon: Icons.schedule_rounded,
                        title: 'Belum ada shift',
                        subtitle:
                            'Buka shift pertama untuk mulai mencatat kasir.',
                      ),
                    )
                  else
                    for (final shift in shifts) ...[
                      _ShiftHistoryTile(shift: shift),
                      const SizedBox(height: 10),
                    ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ActiveShiftCard extends StatelessWidget {
  const _ActiveShiftCard({required this.actor, required this.shift});

  final AppUser actor;
  final CashierShift? shift;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isOpen = shift?.isOpen == true;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOpen
                            ? 'Shift Sedang Berjalan'
                            : 'Belum Ada Shift Aktif',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        actor.nama,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: (isOpen ? scheme.primary : scheme.outline)
                        .withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isOpen ? 'OPEN' : 'OFF',
                    style: TextStyle(
                      color: isOpen ? scheme.primary : scheme.outline,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (shift != null) ...[
              _ShiftStatRow(
                label: 'Buka shift',
                value: AppFormatters.date(shift!.openedAt),
              ),
              _ShiftStatRow(
                label: 'Kas awal',
                value: AppFormatters.rupiah(shift!.openingCash),
              ),
              _ShiftStatRow(
                label: 'Invoice',
                value: AppFormatters.number(shift!.invoiceCount),
              ),
              _ShiftStatRow(
                label: 'Penjualan',
                value: AppFormatters.rupiah(shift!.totalSales),
              ),
            ] else
              Text(
                'Buka shift sebelum kasir mulai melayani transaksi supaya penjualan per sesi lebih rapi.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            const SizedBox(height: 18),
            Consumer<OperationsProvider>(
              builder: (context, operations, _) {
                return SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: operations.isLoading
                        ? null
                        : () => isOpen
                              ? _showCloseShiftSheet(context, shift!)
                              : _showOpenShiftSheet(context, actor),
                    icon: operations.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            isOpen
                                ? Icons.lock_clock_rounded
                                : Icons.lock_open_rounded,
                          ),
                    label: Text(isOpen ? 'Tutup Shift' : 'Buka Shift'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ShiftHistoryTile extends StatelessWidget {
  const _ShiftHistoryTile({required this.shift});

  final CashierShift shift;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
                    shift.userName,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: (shift.isOpen ? scheme.primary : scheme.secondary)
                        .withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    shift.isOpen ? 'Open' : 'Closed',
                    style: TextStyle(
                      color: shift.isOpen ? scheme.primary : scheme.secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Buka ${AppFormatters.date(shift.openedAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (shift.closedAt != null) ...[
              const SizedBox(height: 2),
              Text(
                'Tutup ${AppFormatters.date(shift.closedAt!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ShiftChip(
                  label: 'Kas awal',
                  value: AppFormatters.rupiah(shift.openingCash),
                ),
                if (shift.closingCash != null)
                  _ShiftChip(
                    label: 'Kas akhir',
                    value: AppFormatters.rupiah(shift.closingCash!),
                  ),
                _ShiftChip(
                  label: 'Invoice',
                  value: AppFormatters.number(shift.invoiceCount),
                ),
                _ShiftChip(
                  label: 'Total jual',
                  value: AppFormatters.rupiah(shift.totalSales),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShiftStatRow extends StatelessWidget {
  const _ShiftStatRow({required this.label, required this.value});

  final String label;
  final String value;

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
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShiftChip extends StatelessWidget {
  const _ShiftChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _ClosingCashGuide extends StatelessWidget {
  const _ClosingCashGuide({required this.shift, required this.expectedCash});

  final CashierShift shift;
  final int expectedCash;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cara hitung kas akhir',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          _GuideRow(
            label: 'Kas awal',
            value: AppFormatters.rupiah(shift.openingCash),
          ),
          _GuideRow(
            label: 'Penjualan cash',
            value: AppFormatters.rupiah(shift.cashSales),
          ),
          _GuideRow(
            label: 'Penjualan QRIS',
            value: AppFormatters.rupiah(shift.qrisSales),
          ),
          _GuideRow(
            label: 'Penjualan transfer',
            value: AppFormatters.rupiah(shift.transferSales),
          ),
          const Divider(height: 18),
          _GuideRow(
            label: 'Perkiraan kas akhir',
            value: AppFormatters.rupiah(expectedCash),
            isBold: true,
          ),
          const SizedBox(height: 8),
          Text(
            'Cash, QRIS, dan transfer dihitung sebagai kas shift. Jika ada selisih dari catatan toko, masukkan jumlah aktual.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideRow extends StatelessWidget {
  const _GuideRow({
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showOpenShiftSheet(BuildContext context, AppUser actor) async {
  final controller = TextEditingController();
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
              'Buka Shift',
              style: Theme.of(
                sheetContext,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandSeparatorInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Kas awal',
                prefixIcon: Icon(Icons.payments_rounded),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(sheetContext, true),
              child: const Text('Simpan Shift'),
            ),
          ],
        ),
      );
    },
  );

  final openingCash = AppFormatters.parseNumberInput(controller.text) ?? 0;
  controller.dispose();
  if (confirmed != true) return;
  if (!context.mounted) return;

  try {
    await context.read<OperationsProvider>().openShift(
      actor: actor,
      openingCash: openingCash,
    );
    if (context.mounted) showAppSnackBar(context, 'Shift berhasil dibuka');
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

Future<void> _showCloseShiftSheet(
  BuildContext context,
  CashierShift shift,
) async {
  final actor = context.read<AuthProvider>().user;
  if (actor == null) {
    showAppSnackBar(context, 'Sesi pengguna tidak ditemukan', isError: true);
    return;
  }

  final controller = TextEditingController();
  final expectedCash =
      shift.openingCash +
      shift.cashSales +
      shift.qrisSales +
      shift.transferSales;
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
              'Tutup Shift',
              style: Theme.of(
                sheetContext,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Hitung uang fisik di laci kas, lalu masukkan jumlahnya.',
              style: Theme.of(sheetContext).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            _ClosingCashGuide(shift: shift, expectedCash: expectedCash),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandSeparatorInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Kas akhir',
                prefixIcon: Icon(Icons.account_balance_wallet_rounded),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                controller.text = AppFormatters.number(expectedCash);
              },
              icon: const Icon(Icons.calculate_rounded),
              label: const Text('Isi sesuai perkiraan kas akhir'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(sheetContext, true),
              child: const Text('Tutup Shift'),
            ),
          ],
        ),
      );
    },
  );

  final closingCash = AppFormatters.parseNumberInput(controller.text) ?? 0;
  controller.dispose();
  if (confirmed != true) return;
  if (!context.mounted) return;

  try {
    await context.read<OperationsProvider>().closeShift(
      shift: shift,
      closingCash: closingCash,
      actor: actor,
    );
    if (context.mounted) showAppSnackBar(context, 'Shift berhasil ditutup');
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
