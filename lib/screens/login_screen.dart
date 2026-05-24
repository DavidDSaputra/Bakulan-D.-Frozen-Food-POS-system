import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/snackbar.dart';
import '../utils/validators.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await context.read<AuthProvider>().login(
        _usernameController.text,
        _passwordController.text,
      );
      if (mounted) showAppSnackBar(context, 'Login berhasil');
    } catch (error) {
      if (mounted) {
        showAppSnackBar(
          context,
          'Login gagal. Periksa username dan password.',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.primary.withValues(alpha: .16),
              scheme.surface,
              scheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 520),
                  curve: Curves.easeOutCubic,
                  tween: Tween(begin: 0, end: 1),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 22 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              scheme.primary,
                              Color.lerp(scheme.primary, scheme.tertiary, .42)!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: .25),
                              offset: const Offset(0, 20),
                              blurRadius: 38,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                color: scheme.onPrimary.withValues(alpha: .16),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: scheme.onPrimary.withValues(
                                    alpha: .22,
                                  ),
                                ),
                              ),
                              child: Icon(
                                Icons.storefront_rounded,
                                color: scheme.onPrimary,
                                size: 34,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Bakulan D. Frozen',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: scheme.onPrimary,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sistem kasir dan stok frozen food berbasis mobile.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: scheme.onPrimary.withValues(
                                      alpha: .84,
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Masuk Akun',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Gunakan akun owner atau petugas kasir.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: 20),
                                AppTextField(
                                  controller: _usernameController,
                                  label: 'Username atau Email',
                                  icon: Icons.person_rounded,
                                  validator: (value) => Validators.requiredText(
                                    value,
                                    field: 'Username',
                                  ),
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 14),
                                AppTextField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  icon: Icons.lock_rounded,
                                  obscureText: true,
                                  validator: (value) => Validators.requiredText(
                                    value,
                                    field: 'Password',
                                  ),
                                  textInputAction: TextInputAction.done,
                                ),
                                const SizedBox(height: 22),
                                Consumer<AuthProvider>(
                                  builder: (context, auth, _) {
                                    return AppButton(
                                      label: 'Login',
                                      icon: Icons.login_rounded,
                                      isLoading: auth.isLoading,
                                      onPressed: _login,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest.withValues(
                            alpha: .62,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(alpha: .44),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: scheme.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Username kasir dipetakan ke email kasir@bakulandfrozen.local.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
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
          ),
        ),
      ),
    );
  }
}
