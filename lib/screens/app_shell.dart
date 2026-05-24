import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/snackbar.dart';
import 'dashboard_screen.dart';
import 'products_screen.dart';
import 'reports_screen.dart';
import 'sales_screen.dart';
import 'stock_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final tabs = user?.role == UserRole.owner ? _ownerTabs : _kasirTabs;

    if (_selectedIndex >= tabs.length) _selectedIndex = 0;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onPrimary,
        flexibleSpace: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primary,
                Color.lerp(scheme.primary, scheme.tertiary, .34)!,
              ],
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tabs[_selectedIndex].title,
              style: TextStyle(
                color: scheme.onPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'Bakulan D. Frozen',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onPrimary.withValues(alpha: .78),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              tooltip: 'Mode gelap',
              onPressed: context.read<ThemeProvider>().toggleTheme,
              icon: const Icon(Icons.dark_mode_rounded),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: 'Logout',
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  showAppSnackBar(context, 'Logout berhasil');
                }
              },
              icon: const Icon(Icons.logout_rounded),
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(.035, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex),
          child: tabs[_selectedIndex].screen,
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: .08),
              offset: const Offset(0, -10),
              blurRadius: 24,
            ),
          ],
          border: Border(
            top: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: .42),
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) =>
              setState(() => _selectedIndex = index),
          destinations: [
            for (final tab in tabs)
              NavigationDestination(icon: Icon(tab.icon), label: tab.title),
          ],
        ),
      ),
    );
  }
}

class _ShellTab {
  const _ShellTab(this.title, this.icon, this.screen);

  final String title;
  final IconData icon;
  final Widget screen;
}

const _ownerTabs = [
  _ShellTab('Dashboard', Icons.dashboard_rounded, DashboardScreen()),
  _ShellTab('Laporan', Icons.receipt_long_rounded, ReportsScreen()),
];

const _kasirTabs = [
  _ShellTab('Dashboard', Icons.dashboard_rounded, DashboardScreen()),
  _ShellTab('Barang', Icons.inventory_2_rounded, ProductsScreen()),
  _ShellTab('Stok', Icons.warehouse_rounded, StockScreen()),
  _ShellTab('Penjualan', Icons.point_of_sale_rounded, SalesScreen()),
];
