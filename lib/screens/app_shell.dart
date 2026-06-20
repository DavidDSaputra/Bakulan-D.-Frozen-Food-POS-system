import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_theme.dart';
import '../utils/snackbar.dart';
import 'accounts_screen.dart';
import 'dashboard_screen.dart';
import 'products_screen.dart';
import 'reports_screen.dart';
import 'sales_screen.dart';
import 'stock_opname_screen.dart';
import 'stock_history_screen.dart';
import 'stock_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _dashboardGuideSeenKey = 'dashboard_guide_seen_v1';

  int _selectedIndex = 0;
  final Set<int> _visitedIndexes = {0};

  @override
  void initState() {
    super.initState();
    _showFirstLoginGuide();
  }

  Future<void> _showFirstLoginGuide() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_dashboardGuideSeenKey) ?? false;
    if (seen || !mounted) return;

    await Future<void>.delayed(const Duration(milliseconds: 720));
    if (!mounted) return;
    await _openDashboardGuide(markSeen: true);
  }

  Future<void> _openDashboardGuide({required bool markSeen}) async {
    if (_selectedIndex != 0) {
      await _selectTab(0, animated: true);
      await Future<void>.delayed(const Duration(milliseconds: 280));
    }

    if (!mounted) return;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Tutup guide',
      barrierColor: Colors.black.withValues(alpha: .38),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const _DashboardGuideDialog();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: .96, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );

    if (!markSeen) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dashboardGuideSeenKey, true);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final tabs = user?.role == UserRole.owner ? _ownerTabs : _kasirTabs;

    if (_selectedIndex >= tabs.length) {
      _selectedIndex = 0;
      _visitedIndexes
        ..clear()
        ..add(0);
    }
    _visitedIndexes.removeWhere((index) => index >= tabs.length);
    _visitedIndexes.add(_selectedIndex);
    final scheme = Theme.of(context).colorScheme;

    final hideBar = tabs[_selectedIndex].hideShellBar;

    return Scaffold(
      appBar: hideBar
          ? AppBar(
              toolbarHeight: 0,
              elevation: 0,
              backgroundColor: scheme.surface,
              surfaceTintColor: Colors.transparent,
            )
          : AppBar(
              backgroundColor: scheme.surface,
              foregroundColor: scheme.onSurface,
              surfaceTintColor: Colors.transparent,
              shadowColor: Colors.transparent,
              elevation: 0,
              titleSpacing: 18,
              title: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tabs[_selectedIndex].title,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      Text(
                        'Bakulan POS',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Guide',
                  onPressed: () => _openDashboardGuide(markSeen: false),
                  icon: const FaIcon(FontAwesomeIcons.bookOpen, size: 18),
                ),
                IconButton(
                  tooltip: 'Mode gelap',
                  onPressed: context.read<ThemeProvider>().toggleTheme,
                  icon: const FaIcon(FontAwesomeIcons.solidMoon, size: 18),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: IconButton(
                    tooltip: 'Logout',
                    onPressed: () async {
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) {
                        showAppSnackBar(context, 'Logout berhasil');
                      }
                    },
                    icon: const FaIcon(
                      FontAwesomeIcons.rightFromBracket,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
      body: IndexedStack(
        index: _selectedIndex,
        children: List.generate(tabs.length, (index) {
          if (!_visitedIndexes.contains(index)) {
            return const SizedBox.shrink();
          }
          return tabs[index].screen;
        }),
      ),
      bottomNavigationBar: _ShellNavBar(
        tabs: tabs,
        selectedIndex: _selectedIndex,
        onSelected: (index) => _selectTab(index),
      ),
    );
  }

  Future<void> _selectTab(int index, {bool animated = true}) async {
    if (index == _selectedIndex) return;
    if (!mounted) return;
    setState(() {
      _selectedIndex = index;
      _visitedIndexes.add(index);
    });
  }
}

class _ShellNavBar extends StatelessWidget {
  const _ShellNavBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_ShellTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _accent = AppTheme.brandPrimary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final highlightedIndex = tabs.indexWhere((tab) => tab.prominent);
    final showIndicator = selectedIndex != highlightedIndex;
    final isCompact = tabs.length >= 5;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tabWidth = constraints.maxWidth / tabs.length;
            const indicatorWidth = 34.0;
            final indicatorLeft =
                tabWidth * selectedIndex + (tabWidth - indicatorWidth) / 2;

            return Container(
              height: 68,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: .14),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    left: indicatorLeft,
                    top: 0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: showIndicator ? 1 : 0,
                      child: Container(
                        width: indicatorWidth,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _accent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < tabs.length; i++)
                        Expanded(
                          child: _NavItem(
                            tab: tabs[i],
                            selected: i == selectedIndex,
                            prominent: tabs[i].prominent,
                            compact: isCompact,
                            accent: _accent,
                            onTap: () => onSelected(i),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.prominent,
    required this.compact,
    required this.accent,
    required this.onTap,
  });

  final _ShellTab tab;
  final bool selected;
  final bool prominent;
  final bool compact;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = widget.selected ? widget.accent : scheme.onSurfaceVariant;
    final verticalOffset = widget.prominent
        ? (widget.selected ? -18.0 : -14.0)
        : (widget.selected ? -2.0 : 0.0);
    final iconSize = widget.prominent ? 21.0 : (widget.compact ? 18.0 : 20.0);
    final fontSize = widget.prominent ? 10.0 : (widget.compact ? 9.5 : 11.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? .96 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          offset: Offset(0, verticalOffset / 68),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            width: widget.prominent ? 68 : null,
            height: widget.prominent ? 68 : null,
            decoration: widget.prominent
                ? BoxDecoration(
                    color: widget.accent,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: widget.accent.withValues(
                          alpha: widget.selected ? .34 : .22,
                        ),
                        blurRadius: widget.selected ? 20 : 12,
                        offset: Offset(0, widget.selected ? 8 : 5),
                      ),
                    ],
                  )
                : null,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutBack,
                  scale: widget.selected ? 1.06 : 1,
                  child: FaIcon(
                    widget.tab.icon,
                    size: iconSize,
                    color: widget.prominent ? Colors.white : color,
                  ),
                ),
                const SizedBox(height: 5),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  style: TextStyle(
                    color: widget.prominent ? Colors.white : color,
                    fontSize: fontSize,
                    fontWeight: widget.selected
                        ? FontWeight.w900
                        : FontWeight.w700,
                    letterSpacing: 0,
                  ),
                  child: Text(
                    widget.tab.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class _DashboardGuideDialog extends StatefulWidget {
  const _DashboardGuideDialog();

  @override
  State<_DashboardGuideDialog> createState() => _DashboardGuideDialogState();
}

class _DashboardGuideDialogState extends State<_DashboardGuideDialog>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  late final AnimationController _motionController;
  int _index = 0;

  static const _steps = [
    _GuideStep(
      title: 'Mulai dari ringkasan omzet',
      subtitle:
          'Owner melihat omzet, sedangkan kasir mendapat ringkasan kerja tanpa angka omzet.',
      icon: FontAwesomeIcons.chartLine,
      accent: AppTheme.brandPrimary,
    ),
    _GuideStep(
      title: 'Pantau kondisi toko',
      subtitle:
          'Kartu statistik membantu membaca jumlah transaksi, total barang, stok menipis, dan item stok.',
      icon: FontAwesomeIcons.tableCellsLarge,
      accent: AppTheme.brandTintStrong,
    ),
    _GuideStep(
      title: 'Pindah modul dari bawah',
      subtitle:
          'Gunakan navigasi bawah untuk buka laporan, barang, stok, atau penjualan sesuai role akun.',
      icon: FontAwesomeIcons.handPointer,
      accent: AppTheme.brandMuted,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _motionController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_index < _steps.length - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final step = _steps[_index];

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Material(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Guide Dashboard',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Tutup',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 282,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _steps.length,
                        onPageChanged: (value) =>
                            setState(() => _index = value),
                        itemBuilder: (context, index) {
                          return _GuideStepView(
                            step: _steps[index],
                            animation: _motionController,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _steps.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: i == _index ? 26 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _index
                                  ? step.accent
                                  : scheme.outlineVariant,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        if (_index > 0)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                );
                              },
                              child: const Text('Kembali'),
                            ),
                          )
                        else
                          const Expanded(child: SizedBox.shrink()),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _next,
                            style: FilledButton.styleFrom(
                              backgroundColor: step.accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _index == _steps.length - 1
                                  ? 'Selesai'
                                  : 'Lanjut',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GuideStepView extends StatelessWidget {
  const _GuideStepView({required this.step, required this.animation});

  final _GuideStep step;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final lift = Curves.easeInOut.transform(animation.value) * 14;
            return Transform.translate(offset: Offset(0, -lift), child: child);
          },
          child: Container(
            width: 118,
            height: 118,
            decoration: BoxDecoration(
              color: step.accent.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: step.accent.withValues(alpha: .26)),
            ),
            child: Center(
              child: FaIcon(step.icon, color: step.accent, size: 46),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          step.title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          step.subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.45,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _GuideStep {
  const _GuideStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
}

class _ShellTab {
  const _ShellTab(
    this.title,
    this.icon,
    this.screen, {
    this.hideShellBar = false,
    this.prominent = false,
  });

  final String title;
  final IconData icon;
  final Widget screen;
  final bool hideShellBar;
  final bool prominent;
}

const _ownerTabs = [
  _ShellTab('Home', FontAwesomeIcons.tableCellsLarge, DashboardScreen()),
  _ShellTab('Barang', FontAwesomeIcons.boxOpen, ProductsScreen()),
  _ShellTab(
    'Laporan',
    FontAwesomeIcons.fileLines,
    ReportsScreen(),
    prominent: true,
  ),
  _ShellTab('Opname', FontAwesomeIcons.clipboardCheck, StockOpnameScreen()),
  _ShellTab('Akun', FontAwesomeIcons.usersGear, AccountsScreen()),
];

const _kasirTabs = [
  _ShellTab(
    'Home',
    FontAwesomeIcons.tableCellsLarge,
    DashboardScreen(),
    hideShellBar: true,
  ),
  _ShellTab('Barang', FontAwesomeIcons.boxOpen, ProductsScreen()),
  _ShellTab(
    'Penjualan',
    FontAwesomeIcons.cashRegister,
    SalesScreen(),
    hideShellBar: true,
    prominent: true,
  ),
  _ShellTab('Stok', FontAwesomeIcons.warehouse, StockScreen()),
  _ShellTab('Riwayat', FontAwesomeIcons.clockRotateLeft, StockHistoryScreen()),
];
