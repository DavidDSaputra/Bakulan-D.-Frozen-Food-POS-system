import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../models/product.dart';
import '../models/sales_transaction.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/sales_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/snackbar.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';
import 'basket_screen.dart';
import 'sales_screen.dart';
import 'transaction_detail_screen.dart';
import 'transaction_history_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return StreamBuilder<List<Product>>(
      stream: context.read<ProductProvider>().watchProducts(),
      builder: (context, productSnapshot) {
        return StreamBuilder<List<SalesTransaction>>(
          stream: context.read<SalesProvider>().watchTransactions(limit: 120),
          builder: (context, trxSnapshot) {
            if (!productSnapshot.hasData) {
              return const AppLoadingIndicator();
            }

            final products = productSnapshot.data!;
            final transactions = trxSnapshot.data ?? const <SalesTransaction>[];
            final isOwner = user?.isOwner == true;
            final userName = user?.nama ?? 'Pengguna';
            final revenue = transactions.fold<int>(
              0,
              (sum, trx) => sum + trx.totalHarga,
            );
            final lowStock = products
                .where((product) => product.stok <= 5)
                .length;
            final expiredProducts = products
                .where((product) => product.isExpired)
                .length;
            final expiringSoonProducts = products
                .where((product) => product.isExpiringSoon)
                .length;
            final totalStock = products.fold<int>(
              0,
              (sum, product) => sum + product.stok,
            );
            final availableProducts = products
                .where((product) => product.stok > 0)
                .length;
            final today = DateTime.now();
            final todayStart = DateTime(today.year, today.month, today.day);
            final todayEnd = todayStart.add(const Duration(days: 1));
            final todayTransactions = transactions
                .where(
                  (trx) =>
                      !trx.tanggal.isBefore(todayStart) &&
                      trx.tanggal.isBefore(todayEnd),
                )
                .length;

            if (!isOwner) {
              return _CashierDashboard(
                name: userName,
                todayTransactions: todayTransactions,
                lowStock: lowStock,
                availableProducts: availableProducts,
                expiringSoonProducts: expiringSoonProducts,
                expiredProducts: expiredProducts,
                transactions: transactions,
              );
            }

            return Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  children: [
                    _StaggeredEntry(
                      delay: const Duration(milliseconds: 40),
                      child: _DashboardHero(
                        name: userName,
                        isOwner: isOwner,
                        revenue: revenue,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _StaggeredEntry(
                      delay: const Duration(milliseconds: 120),
                      child: _StatsGrid(
                        isOwner: isOwner,
                        transactions: transactions.length,
                        products: products.length,
                        lowStock: lowStock,
                        totalStock: totalStock,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _StaggeredEntry(
                      delay: const Duration(milliseconds: 180),
                      child: _InventoryAlertPanel(
                        lowStock: lowStock,
                        expiringSoon: expiringSoonProducts,
                        expired: expiredProducts,
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (isOwner)
                      _StaggeredEntry(
                        delay: const Duration(milliseconds: 220),
                        child: _RecentTransactions(transactions: transactions),
                      )
                    else
                      const SizedBox.shrink(),
                  ],
                ),
                const Positioned(
                  top: 12,
                  right: 16,
                  child: _HomeAssistiveMenu(),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _CashierDashboard extends StatelessWidget {
  const _CashierDashboard({
    required this.name,
    required this.todayTransactions,
    required this.lowStock,
    required this.availableProducts,
    required this.expiringSoonProducts,
    required this.expiredProducts,
    required this.transactions,
  });

  final String name;
  final int todayTransactions;
  final int lowStock;
  final int availableProducts;
  final int expiringSoonProducts;
  final int expiredProducts;
  final List<SalesTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.brandSurface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _CashierHeader(name: name),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CashierSummary(
                  todayTransactions: todayTransactions,
                  lowStock: lowStock,
                  availableProducts: availableProducts,
                ),
                const SizedBox(height: 16),
                _InventoryAlertPanel(
                  lowStock: lowStock,
                  expiringSoon: expiringSoonProducts,
                  expired: expiredProducts,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _CashierQuickActions(),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
            child: _CashierRecentTransactions(transactions: transactions),
          ),
        ],
      ),
    );
  }
}

class _CashierHeader extends StatelessWidget {
  const _CashierHeader({required this.name});

  static const _orange = AppTheme.brandPrimary;
  static const _text = AppTheme.brandInk;

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'P';
    final dateLabel = AppFormatters.date(DateTime.now()).split(',').first;

    return SizedBox(
      height: 296,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 296,
            decoration: const BoxDecoration(
              color: _orange,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: _text,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Petugas kasir',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .72),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const _HomeAssistiveMenu(onDarkHeader: true),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppTheme.brandTint,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(
                              Icons.calendar_month_rounded,
                              color: _orange,
                              size: 17,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            dateLabel,
                            style: const TextStyle(
                              color: _text,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: Container(
                        height: 96,
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .22),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .68),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Image.asset(
                                'assets/images/logo.png',
                                cacheWidth: 160,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Kasir Praktis',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Fokus ke penjualan, keranjang, dan transaksi terbaru.',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      height: 1.28,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

class _HomeAssistiveMenu extends StatefulWidget {
  const _HomeAssistiveMenu({this.onDarkHeader = false});

  final bool onDarkHeader;

  @override
  State<_HomeAssistiveMenu> createState() => _HomeAssistiveMenuState();
}

class _HomeAssistiveMenuState extends State<_HomeAssistiveMenu>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final buttonColor = widget.onDarkHeader
        ? Colors.white.withValues(alpha: .16)
        : AppTheme.brandPrimary;
    final foreground = Colors.white;

    return SizedBox(
      width: 48,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: buttonColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.onDarkHeader
                ? Colors.white.withValues(alpha: .18)
                : scheme.outlineVariant.withValues(alpha: .36),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .12),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => _openPowerMenu(context),
            child: Icon(Icons.apps_rounded, color: foreground, size: 23),
          ),
        ),
      ),
    );
  }

  Future<void> _openPowerMenu(BuildContext context) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Tutup menu',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return _AssistivePowerMenu(
          onInfoCashier: () {
            Navigator.of(dialogContext).pop();
            _showCashierInfoSheet(context);
          },
          onToggleTheme: () {
            Navigator.of(dialogContext).pop();
            context.read<ThemeProvider>().toggleTheme();
          },
          onLogout: () async {
            Navigator.of(dialogContext).pop();
            await context.read<AuthProvider>().logout();
            if (context.mounted) {
              showAppSnackBar(context, 'Logout berhasil');
            }
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: .92, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  void _showCashierInfoSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const _CashierInfoSheet(),
    );
  }
}

class _AssistivePowerMenu extends StatelessWidget {
  const _AssistivePowerMenu({
    required this.onInfoCashier,
    required this.onToggleTheme,
    required this.onLogout,
  });

  final VoidCallback onInfoCashier;
  final VoidCallback onToggleTheme;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: ColoredBox(
          color: Colors.black.withValues(alpha: .26),
          child: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 54),
                    child: Container(
                      width: 176,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF37262C).withValues(alpha: .96),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .08),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .28),
                            blurRadius: 28,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              const SizedBox(width: 3),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          GridView.count(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: .98,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _AssistiveGridItem(
                                label: 'Info Kasir',
                                icon: Icons.groups_rounded,
                                onTap: onInfoCashier,
                              ),
                              _AssistiveGridItem(
                                label: 'Tema',
                                icon: Icons.dark_mode_rounded,
                                onTap: onToggleTheme,
                              ),
                              _AssistiveGridItem(
                                label: 'Logout',
                                icon: Icons.logout_rounded,
                                danger: true,
                                onTap: onLogout,
                              ),
                              _AssistiveGridItem(
                                label: 'Tutup',
                                icon: Icons.close_rounded,
                                onTap: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .72),
                                width: 1.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AssistiveGridItem extends StatelessWidget {
  const _AssistiveGridItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFFF7A7A) : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 27),
            const SizedBox(height: 7),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color.withValues(alpha: .88),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CashierInfoSheet extends StatelessWidget {
  const _CashierInfoSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<List<AppUser>>(
        stream: context.read<AuthProvider>().watchUsers(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: _SheetErrorMessage(),
            );
          }

          if (!snapshot.hasData) {
            return const SizedBox(height: 180, child: AppLoadingIndicator());
          }

          final cashiers = snapshot.data!.where((user) => user.isKasir).toList()
            ..sort((a, b) => a.nama.compareTo(b.nama));

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Info Kasir',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _CashierCountBadge(count: cashiers.length),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Daftar akun kasir yang terdaftar di POS.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                if (cashiers.isEmpty)
                  const EmptyState(
                    icon: Icons.point_of_sale_rounded,
                    title: 'Belum ada kasir',
                    subtitle: 'Akun kasir yang dibuat akan tampil di sini.',
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: cashiers.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return _CashierInfoTile(user: cashiers[index]);
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SheetErrorMessage extends StatelessWidget {
  const _SheetErrorMessage();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock_outline_rounded, color: scheme.error, size: 34),
        const SizedBox(height: 12),
        Text(
          'Info kasir belum bisa dibuka',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          'Rules lokal sudah disiapkan. Publish firestore.rules ke Firebase Console agar akun login bisa membaca collection users.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CashierCountBadge extends StatelessWidget {
  const _CashierCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.brandTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count kasir',
        style: const TextStyle(
          color: AppTheme.brandPrimary,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _CashierInfoTile extends StatelessWidget {
  const _CashierInfoTile({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = user.nama.trim().isNotEmpty
        ? user.nama.trim()[0].toUpperCase()
        : 'K';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .4)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.brandTint,
            foregroundColor: AppTheme.brandPrimary,
            child: Text(
              initial,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  user.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.point_of_sale_rounded, color: AppTheme.brandPrimary),
        ],
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.name,
    required this.isOwner,
    required this.revenue,
  });

  final String name;
  final bool isOwner;
  final int revenue;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.brandPrimary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandPrimary.withValues(alpha: .18),
            offset: const Offset(0, 10),
            blurRadius: 24,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, $name',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isOwner ? 'Owner toko' : 'Petugas kasir',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isOwner) ...[
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Omzet',
                  style: TextStyle(
                    color: AppTheme.brandTint,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 132),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      AppFormatters.rupiah(revenue),
                      maxLines: 1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.transactions,
    required this.isOwner,
    required this.products,
    required this.lowStock,
    required this.totalStock,
  });

  final int transactions;
  final bool isOwner;
  final int products;
  final int lowStock;
  final int totalStock;

  @override
  Widget build(BuildContext context) {
    final items = [
      if (isOwner)
        _StatData(
          title: 'Transaksi',
          value: '$transactions',
          icon: FontAwesomeIcons.bagShopping,
          color: AppTheme.brandPrimary,
        ),
      _StatData(
        title: 'Barang',
        value: '$products',
        icon: FontAwesomeIcons.boxOpen,
        color: AppTheme.brandPrimary,
      ),
      _StatData(
        title: 'Stok tipis',
        value: '$lowStock',
        icon: FontAwesomeIcons.triangleExclamation,
        color: AppTheme.brandPrimary,
      ),
      _StatData(
        title: isOwner ? 'Total stok' : 'Siap dijual',
        value: '$totalStock',
        icon: FontAwesomeIcons.snowflake,
        color: AppTheme.brandPrimary,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 620 ? 4 : 2;
        return GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 126,
          ),
          itemBuilder: (context, index) {
            return _StaggeredEntry(
              delay: Duration(milliseconds: 160 + index * 55),
              child: _CompactStatCard(data: items[index]),
            );
          },
        );
      },
    );
  }
}

class _CompactStatCard extends StatelessWidget {
  const _CompactStatCard({required this.data});

  final _StatData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .28)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: .04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: FaIcon(data.icon, color: data.color, size: 16),
            ),
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              data.value,
              maxLines: 1,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.title,
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

double _cashierAdaptiveItemWidth({
  required int index,
  required int itemCount,
  required int columns,
  required double maxWidth,
  required double spacing,
}) {
  final baseWidth = (maxWidth - (spacing * (columns - 1))) / columns;
  final lastRowCount = itemCount % columns;
  if (lastRowCount == 0) return baseWidth;

  final lastRowStart = itemCount - lastRowCount;
  if (index < lastRowStart) return baseWidth;

  return (maxWidth - (spacing * (lastRowCount - 1))) / lastRowCount;
}

void _pushScreen(BuildContext context, Widget screen) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}

class _CashierSummary extends StatelessWidget {
  const _CashierSummary({
    required this.todayTransactions,
    required this.lowStock,
    required this.availableProducts,
  });

  final int todayTransactions;
  final int lowStock;
  final int availableProducts;

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatData(
        title: 'Transaksi hari ini',
        value: '$todayTransactions',
        icon: FontAwesomeIcons.cashRegister,
        color: AppTheme.brandPrimary,
      ),
      _StatData(
        title: 'Stok tipis',
        value: '$lowStock',
        icon: FontAwesomeIcons.triangleExclamation,
        color: AppTheme.brandPrimary,
      ),
      _StatData(
        title: 'Barang siap jual',
        value: '$availableProducts',
        icon: FontAwesomeIcons.boxOpen,
        color: AppTheme.brandPrimary,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ringkasan Kasir',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 10.0;
            final columns = constraints.maxWidth >= 560 ? 3 : 2;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (var index = 0; index < items.length; index++)
                  SizedBox(
                    width: _cashierAdaptiveItemWidth(
                      index: index,
                      itemCount: items.length,
                      columns: columns,
                      maxWidth: constraints.maxWidth,
                      spacing: spacing,
                    ),
                    height: 132,
                    child: _CompactStatCard(data: items[index]),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CashierQuickActions extends StatelessWidget {
  const _CashierQuickActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shortcut Cepat',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        _PrimaryCashierAction(
          title: 'Mulai Penjualan',
          subtitle: 'Langsung buka halaman transaksi kasir.',
          icon: FontAwesomeIcons.cashRegister,
          onTap: () => _pushScreen(context, const SalesScreen()),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 10.0;
            final actions = [
              _CashierActionItem(
                title: 'Keranjang',
                subtitle: 'Cek item sebelum bayar',
                icon: FontAwesomeIcons.basketShopping,
                onTap: () => _pushScreen(context, const BasketScreen()),
              ),
              _CashierActionItem(
                title: 'Transaksi',
                subtitle: 'Lihat transaksi terbaru',
                icon: FontAwesomeIcons.receipt,
                onTap: () =>
                    _pushScreen(context, const TransactionHistoryScreen()),
              ),
            ];

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final action in actions)
                  SizedBox(
                    width: (constraints.maxWidth - spacing) / 2,
                    child: _CashierActionCard(item: action),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CashierActionItem {
  const _CashierActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
}

class _PrimaryCashierAction extends StatelessWidget {
  const _PrimaryCashierAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.brandPrimary,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: FaIcon(icon, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.brandTint,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _CashierActionCard extends StatelessWidget {
  const _CashierActionCard({required this.item});

  final _CashierActionItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 96,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: .34),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .035),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FaIcon(item.icon, color: AppTheme.brandPrimary, size: 20),
              const Spacer(),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.brandInk,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CashierRecentTransactions extends StatelessWidget {
  const _CashierRecentTransactions({required this.transactions});

  final List<SalesTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    final latest = transactions.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Recent Transactions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.brandInk,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TransactionHistoryScreen(),
                  ),
                );
              },
              label: const Text('See All'),
              icon: const Icon(Icons.chevron_right_rounded),
              iconAlignment: IconAlignment.end,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (latest.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.brandBorder),
            ),
            child: const Text(
              'Belum ada transaksi terbaru.',
              style: TextStyle(
                color: AppTheme.brandMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        else
          for (final transaction in latest)
            _TransactionTile(transaction: transaction),
      ],
    );
  }
}

class _InventoryAlertPanel extends StatelessWidget {
  const _InventoryAlertPanel({
    required this.lowStock,
    required this.expiringSoon,
    required this.expired,
  });

  final int lowStock;
  final int expiringSoon;
  final int expired;

  @override
  Widget build(BuildContext context) {
    final items = [
      _AlertData(
        title: 'Stok tipis',
        value: '$lowStock',
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFFE69A26),
      ),
      _AlertData(
        title: 'Segera kedaluwarsa',
        value: '$expiringSoon',
        icon: Icons.event_available_rounded,
        color: const Color(0xFF1976D2),
      ),
      _AlertData(
        title: 'Sudah kedaluwarsa',
        value: '$expired',
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFD93C2F),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alert Persediaan',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 10.0;
            final columns = constraints.maxWidth >= 620 ? 3 : 2;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (var index = 0; index < items.length; index++)
                  SizedBox(
                    width: _cashierAdaptiveItemWidth(
                      index: index,
                      itemCount: items.length,
                      columns: columns,
                      maxWidth: constraints.maxWidth,
                      spacing: spacing,
                    ),
                    height: 118,
                    child: _AlertCard(data: items[index]),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.data});

  final _AlertData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: data.color, size: 18),
          ),
          const Spacer(),
          Text(
            data.value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            data.title,
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

class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions({required this.transactions});

  final List<SalesTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Transaksi Terbaru',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.brandTint,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${transactions.length} data',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.brandPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (transactions.isEmpty)
          Container(
            height: 230,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: .42),
              ),
            ),
            child: EmptyState(
              iconWidget: FaIcon(
                FontAwesomeIcons.receipt,
                color: scheme.onPrimaryContainer,
                size: 34,
              ),
              title: 'Belum ada transaksi',
              subtitle: 'Transaksi berhasil akan muncul di sini.',
            ),
          )
        else
          ...transactions.take(5).toList().asMap().entries.map((entry) {
            final trx = entry.value;
            return _StaggeredEntry(
              delay: Duration(milliseconds: 270 + entry.key * 60),
              child: _TransactionTile(transaction: trx),
            );
          }),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final SalesTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TransactionDetailScreen(transaction: transaction),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.brandTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: FaIcon(
                    FontAwesomeIcons.receipt,
                    color: AppTheme.brandPrimary,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.namaBarang,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${transaction.qty} item - ${transaction.metodePembayaran}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    AppFormatters.rupiah(transaction.totalHarga),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
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

class _StaggeredEntry extends StatefulWidget {
  const _StaggeredEntry({required this.child, required this.delay});

  final Widget child;
  final Duration delay;

  @override
  State<_StaggeredEntry> createState() => _StaggeredEntryState();
}

class _StaggeredEntryState extends State<_StaggeredEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .08),
          end: Offset.zero,
        ).animate(_animation),
        child: widget.child,
      ),
    );
  }
}

class _StatData {
  const _StatData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
}

class _AlertData {
  const _AlertData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
}
