import 'dart:math' as math;

import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _orange = Color(0xFFFF5A1F);

  late final AnimationController _floatController;
  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _orange,
      body: SafeArea(
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: _fadeController,
            curve: Curves.easeOutCubic,
          ),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _floatController,
                    builder: (context, child) {
                      final bob =
                          math.sin(_floatController.value * math.pi) * 12;
                      final scale = 1 +
                          (math.sin(_floatController.value * math.pi) * .03);
                      return Transform.translate(
                        offset: Offset(0, -bob),
                        child: Transform.scale(scale: scale, child: child),
                      );
                    },
                    child: _SplashIllustration(
                      assetPath: 'assets/images/splash_calculator.png',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Bakulan D Frozen',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'POS Frozen Food',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: .82),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: 150,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: .22),
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 34),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashIllustration extends StatelessWidget {
  const _SplashIllustration({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(
          constraints.maxWidth * .72,
          constraints.maxHeight * .58,
        );

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.calculate_rounded,
                    color: Colors.white,
                    size: 120,
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: size * .56,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        );
      },
    );
  }
}
