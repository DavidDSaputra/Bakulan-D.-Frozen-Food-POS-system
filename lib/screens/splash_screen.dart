import 'dart:math' as math;

import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _loopController;
  late final Animation<double> _logoScale;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 980),
    )..forward();
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _logoScale = Tween<double>(begin: .86, end: 1).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutBack),
    );
    _fade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0, .74, curve: Curves.easeOutCubic),
    );
    _slide = Tween<Offset>(begin: const Offset(0, .08), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _introController,
            curve: const Interval(.08, 1, curve: Curves.easeOutCubic),
          ),
        );
  }

  @override
  void dispose() {
    _introController.dispose();
    _loopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final logoSize = math.min(
            292.0,
            math.max(212.0, constraints.maxWidth * .58),
          );

          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [
                        Color(0xFF071827),
                        Color(0xFF102C44),
                        Color(0xFF181A21),
                      ]
                    : const [
                        Color(0xFFE9F8FF),
                        Color(0xFFFFFFFF),
                        Color(0xFFFFF6F2),
                      ],
              ),
            ),
            child: Stack(
              children: [
                _FrostSparkle(
                  animation: _loopController,
                  top: constraints.maxHeight * .14,
                  left: constraints.maxWidth * .18,
                  size: 28,
                  delay: .12,
                  color: scheme.primary,
                ),
                _FrostSparkle(
                  animation: _loopController,
                  top: constraints.maxHeight * .2,
                  left: constraints.maxWidth * .76,
                  size: 22,
                  delay: .48,
                  color: scheme.tertiary,
                ),
                _FrostSparkle(
                  animation: _loopController,
                  top: constraints.maxHeight * .68,
                  left: constraints.maxWidth * .21,
                  size: 18,
                  delay: .72,
                  color: scheme.primary,
                ),
                _FrostSparkle(
                  animation: _loopController,
                  top: constraints.maxHeight * .72,
                  left: constraints.maxWidth * .78,
                  size: 26,
                  delay: .34,
                  color: const Color(0xFFE87461),
                ),
                Center(
                  child: FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slide,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedBuilder(
                            animation: Listenable.merge([
                              _introController,
                              _loopController,
                            ]),
                            builder: (context, child) {
                              final breathing =
                                  math.sin(
                                    _loopController.value * math.pi * 2,
                                  ) *
                                  .018;
                              return Transform.scale(
                                scale: _logoScale.value + breathing,
                                child: child,
                              );
                            },
                            child: Container(
                              width: logoSize,
                              height: logoSize,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerLowest.withValues(
                                  alpha: isDark ? .9 : .96,
                                ),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: scheme.primary.withValues(alpha: .14),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: scheme.primary.withValues(
                                      alpha: isDark ? .24 : .16,
                                    ),
                                    offset: const Offset(0, 22),
                                    blurRadius: 44,
                                  ),
                                  BoxShadow(
                                    color: scheme.shadow.withValues(
                                      alpha: isDark ? .28 : .1,
                                    ),
                                    offset: const Offset(0, 10),
                                    blurRadius: 26,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Image.asset(
                                  'assets/images/logo.jpeg',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                        Icons.ac_unit_rounded,
                                        color: scheme.primary,
                                        size: logoSize * .36,
                                      ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 26),
                          Text(
                            'Bakulan D Frozen',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'POS Frozen Food',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: 168,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                minHeight: 6,
                                backgroundColor: scheme.primaryContainer
                                    .withValues(alpha: .55),
                                color: scheme.primary,
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
          );
        },
      ),
    );
  }
}

class _FrostSparkle extends StatelessWidget {
  const _FrostSparkle({
    required this.animation,
    required this.top,
    required this.left,
    required this.size,
    required this.delay,
    required this.color,
  });

  final Animation<double> animation;
  final double top;
  final double left;
  final double size;
  final double delay;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final phase = (animation.value + delay) % 1;
          final drift = math.sin(phase * math.pi * 2) * 10;
          final float = math.cos((phase + delay) * math.pi * 2) * 7;
          final opacity = .34 + (math.sin(phase * math.pi * 2) + 1) * .18;

          return Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(drift, float),
              child: Transform.rotate(angle: phase * math.pi * 2, child: child),
            ),
          );
        },
        child: Icon(
          Icons.ac_unit_rounded,
          color: color.withValues(alpha: .82),
          size: size,
        ),
      ),
    );
  }
}
