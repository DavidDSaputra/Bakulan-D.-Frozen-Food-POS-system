import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/operations_provider.dart';
import 'providers/product_provider.dart';
import 'providers/sales_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/app_shell.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'utils/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache.maximumSize = 300;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 48 << 20;
  await initializeDateFormatting('id_ID');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const BakulanApp());
}

class BakulanApp extends StatelessWidget {
  const BakulanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..listenToUser()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => SalesProvider()),
        ChangeNotifierProvider(create: (_) => OperationsProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Bakulan POS',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  static const _onboardingDoneKey = 'onboarding_done';

  bool _isCheckingIntro = true;
  bool _showIntro = false;

  @override
  void initState() {
    super.initState();
    _loadIntroPreference();
  }

  Future<void> _loadIntroPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final hasFinishedOnboarding = prefs.getBool(_onboardingDoneKey) ?? false;
    if (!mounted) return;
    setState(() {
      _showIntro = !hasFinishedOnboarding;
      _isCheckingIntro = false;
    });
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingDoneKey, true);
    if (!mounted) return;
    setState(() => _showIntro = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingIntro) {
      return const _AuthLoadingScreen();
    }

    if (_showIntro) {
      return OnboardingScreen(onFinished: _finishOnboarding);
    }

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final child = auth.isCheckingUser
            ? const _AuthLoadingScreen()
            : auth.user == null
            ? const LoginScreen()
            : const AppShell();

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 420),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, .035),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey(
              auth.isCheckingUser
                  ? 'checking'
                  : auth.user == null
                  ? 'login'
                  : 'app',
            ),
            child: child,
          ),
        );
      },
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.brandSurface,
      body: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      ),
    );
  }
}
