import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final Future<void> Function() onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  static const _orange = Color(0xFFFF5A1F);
  static const _surface = Colors.white;

  final _pageController = PageController();
  late final AnimationController _floatController;
  int _index = 0;
  bool _finishing = false;

  final _slides = const [
    _OnboardingSlideData(
      title: 'Kasir Lebih Cepat',
      subtitle:
          'Masukkan barang, pilih jumlah, dan selesaikan transaksi tanpa langkah yang bertele-tele.',
      assetPath: 'assets/images/3dicons-notebook-dynamic-color.png',
    ),
    _OnboardingSlideData(
      title: 'Owner Lebih Paham',
      subtitle:
          'Laporan, laba, dan riwayat transaksi tampil rapi supaya keputusan toko lebih mudah diambil.',
      assetPath: 'assets/images/3dicons-target-dynamic-color.png',
    ),
    _OnboardingSlideData(
      title: 'Stok Lebih Rapi',
      subtitle:
          'Stok opname, barang aktif, dan pergerakan barang terpantau lebih nyaman dari satu tempat.',
      assetPath: 'assets/images/splash_calculator.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_index < _slides.length - 1) {
      await _pageController.animateToPage(
        _index + 1,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    if (_finishing) return;
    setState(() => _finishing = true);
    await widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: _orange,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: _surface,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _surface,
        body: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (context, index) {
                  return _OnboardingPage(
                    data: _slides[index],
                    floatAnimation: _floatController,
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                child: Row(
                  children: [
                    SizedBox(
                      width: 64,
                      child: TextButton(
                        onPressed: _finishing ? null : widget.onFinished,
                        style: TextButton.styleFrom(
                          foregroundColor: _orange,
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        child: const Text('Skip'),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: _SlideDots(
                          count: _slides.length,
                          index: _index,
                          accent: _orange,
                        ),
                      ),
                    ),
                    _NextButton(
                      accent: _orange,
                      finishing: _finishing,
                      onPressed: _finishing ? null : _next,
                      isLast: _index == _slides.length - 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data, required this.floatAnimation});

  final _OnboardingSlideData data;
  final Animation<double> floatAnimation;

  static const _orange = Color(0xFFFF5A1F);
  static const _muted = Color(0xFF9AA3B2);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 58,
          child: _HeroPanel(
            assetPath: data.assetPath,
            floatAnimation: floatAnimation,
          ),
        ),
        const SizedBox(height: 18),
        Expanded(
          flex: 42,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _orange,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Text(
                    data.subtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _muted,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.assetPath, required this.floatAnimation});

  final String assetPath;
  final Animation<double> floatAnimation;

  static const _orange = Color(0xFFFF5A1F);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageSize = math.min(
          constraints.maxWidth * .58,
          constraints.maxHeight * .72,
        );

        return Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: double.infinity,
                height: constraints.maxHeight * .84,
                decoration: const BoxDecoration(
                  color: _orange,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(220),
                    bottomRight: Radius.circular(220),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: constraints.maxHeight * .12,
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: floatAnimation,
                    builder: (context, child) {
                      final bob = math.sin(floatAnimation.value * math.pi) * 10;
                      final scale =
                          1 + (math.sin(floatAnimation.value * math.pi) * .02);
                      return Transform.translate(
                        offset: Offset(0, -bob),
                        child: Transform.scale(scale: scale, child: child),
                      );
                    },
                    child: SizedBox(
                      width: imageSize,
                      height: imageSize,
                      child: Image.asset(
                        assetPath,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.white,
                            size: 84,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: imageSize * .56,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SlideDots extends StatelessWidget {
  const _SlideDots({
    required this.count,
    required this.index,
    required this.accent,
  });

  final int count;
  final int index;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index ? accent : const Color(0xFFF0D8CD),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({
    required this.accent,
    required this.finishing,
    required this.onPressed,
    required this.isLast,
  });

  final Color accent;
  final bool finishing;
  final VoidCallback? onPressed;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: accent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: .22),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: InkResponse(
          onTap: onPressed,
          radius: 28,
          containedInkWell: true,
          customBorder: const CircleBorder(),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: finishing
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      isLast
                          ? Icons.rocket_launch_rounded
                          : Icons.arrow_forward_rounded,
                      key: ValueKey(isLast),
                      color: Colors.white,
                      size: 22,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlideData {
  const _OnboardingSlideData({
    required this.title,
    required this.subtitle,
    required this.assetPath,
  });

  final String title;
  final String subtitle;
  final String assetPath;
}
