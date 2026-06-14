import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/snackbar.dart';
import '../utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  static const _brandBlue = Color(0xFFFF5A1F);
  static const _brandDark = Color(0xFFC63D0F);
  static const _aqua = Color(0xFFFFE0D3);
  static const _ice = Color(0xFFFFF7F2);
  static const _paper = Color(0xFFFFFFFF);
  static const _ink = Color(0xFF243757);
  static const _muted = Color(0xFF42526D);
  static const _line = Color(0xFFFFC8B2);
  static const _coral = Color(0xFFE97670);

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AnimationController _introController;

  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 980),
    )..forward();
  }

  @override
  void dispose() {
    _introController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;

    try {
      await context.read<AuthProvider>().login(
        _usernameController.text,
        _passwordController.text,
      );
      if (mounted) showAppSnackBar(context, 'Login berhasil');
    } catch (_) {
      if (mounted) {
        showAppSnackBar(
          context,
          'Login gagal. Periksa username dan password.',
          isError: true,
        );
      }
    }
  }

  Future<void> _loginWithBiometric() async {
    try {
      await context.read<AuthProvider>().loginWithBiometric();
      if (mounted) showAppSnackBar(context, 'Login sidik jari berhasil');
    } catch (error) {
      if (mounted) {
        showAppSnackBar(
          context,
          error.toString().replaceAll('Exception: ', ''),
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 820;

    return Scaffold(
      backgroundColor: _ice,
      body: SafeArea(
        child: Stack(
          children: [
            const _LoginBackdrop(),
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 40 : 18,
                  vertical: isWide ? 30 : 18,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 11,
                              child: _IntroMotion(
                                controller: _introController,
                                from: 0,
                                to: .68,
                                xOffset: -24,
                                child: const _BrandStory(),
                              ),
                            ),
                            const SizedBox(width: 28),
                            Expanded(
                              flex: 10,
                              child: _IntroMotion(
                                controller: _introController,
                                from: .16,
                                to: 1,
                                yOffset: 28,
                                child: _LoginPanel(
                                  formKey: _formKey,
                                  usernameController: _usernameController,
                                  passwordController: _passwordController,
                                  showPassword: _showPassword,
                                  onTogglePassword: () {
                                    setState(() {
                                      _showPassword = !_showPassword;
                                    });
                                  },
                                  onLogin: _login,
                                  onBiometricLogin: _loginWithBiometric,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _IntroMotion(
                              controller: _introController,
                              from: 0,
                              to: .58,
                              yOffset: 18,
                              child: const _BrandStory(compact: true),
                            ),
                            const SizedBox(height: 16),
                            _IntroMotion(
                              controller: _introController,
                              from: .14,
                              to: 1,
                              yOffset: 22,
                              child: _LoginPanel(
                                formKey: _formKey,
                                usernameController: _usernameController,
                                passwordController: _passwordController,
                                showPassword: _showPassword,
                                onTogglePassword: () {
                                  setState(() {
                                    _showPassword = !_showPassword;
                                  });
                                },
                                onLogin: _login,
                                onBiometricLogin: _loginWithBiometric,
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
    );
  }
}

class _LoginBackdrop extends StatelessWidget {
  const _LoginBackdrop();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(painter: _LoginBackdropPainter()),
    );
  }
}

class _LoginBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()..color = _LoginScreenState._ice;
    canvas.drawRect(Offset.zero & size, base);

    final glow = Paint()..color = _LoginScreenState._aqua;
    canvas.drawCircle(Offset(size.width * .13, size.height * .2), 96, glow);

    final coralBlock = Paint()..color = const Color(0xFFFFE7E4);
    canvas.drawRect(
      Rect.fromLTWH(size.width * .82, 0, size.width * .08, size.height),
      coralBlock,
    );

    final block = Paint()..color = const Color(0xFFFFE0D3);
    canvas.drawRect(
      Rect.fromLTWH(size.width * .68, 0, size.width * .11, size.height),
      block,
    );

    final line = Paint()
      ..color = const Color(0xFFFFC8B2)
      ..strokeWidth = 1;
    for (var i = 0; i < 9; i++) {
      final x = size.width * (.04 + i * .12);
      canvas.drawLine(Offset(x, 0), Offset(x - 90, size.height), line);
    }

    final bottom = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * .78)
        ..quadraticBezierTo(
          size.width * .44,
          size.height * .7,
          size.width,
          size.height * .86,
        )
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      bottom,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _IntroMotion extends StatelessWidget {
  const _IntroMotion({
    required this.controller,
    required this.child,
    this.from = 0,
    this.to = 1,
    this.xOffset = 0,
    this.yOffset = 0,
  });

  final AnimationController controller;
  final Widget child;
  final double from;
  final double to;
  final double xOffset;
  final double yOffset;

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(from, to, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final value = animation.value;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(xOffset * (1 - value), yOffset * (1 - value)),
            child: child,
          ),
        );
      },
    );
  }
}

class _BrandStory extends StatelessWidget {
  const _BrandStory({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(18, compact ? 16 : 22, 18, 18),
      decoration: BoxDecoration(
        color: _LoginScreenState._paper,
        border: Border.all(color: _LoginScreenState._line, width: 1.2),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0868B8),
            offset: Offset(0, 16),
            blurRadius: 34,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_LogoHero(compact: compact)],
      ),
    );
  }
}

class _LogoHero extends StatelessWidget {
  const _LogoHero({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: compact ? 190 : 320,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 18 : 28,
        vertical: compact ? 14 : 18,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0E8),
        border: Border.all(color: _LoginScreenState._line, width: 1.2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120868B8),
            offset: Offset(0, 10),
            blurRadius: 18,
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/logo.jpeg',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.ac_unit,
          color: _LoginScreenState._brandBlue,
          size: 54,
        ),
      ),
    );
  }
}

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({
    required this.formKey,
    required this.usernameController,
    required this.passwordController,
    required this.showPassword,
    required this.onTogglePassword,
    required this.onLogin,
    required this.onBiometricLogin,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool showPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;
  final VoidCallback onBiometricLogin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      decoration: BoxDecoration(
        color: _LoginScreenState._paper,
        border: Border.all(color: _LoginScreenState._line, width: 1.2),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F0868B8),
            offset: Offset(0, 18),
            blurRadius: 32,
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _PanelHandle(),
            const SizedBox(height: 18),
            Text(
              'Masuk ke POS',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: _LoginScreenState._ink,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Gunakan akun owner atau kasir untuk mulai transaksi.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _LoginScreenState._muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            _LoginTextField(
              controller: usernameController,
              label: 'Username atau Email',
              icon: Icons.person_outline,
              validator: (value) =>
                  Validators.requiredText(value, field: 'Username'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            _LoginTextField(
              controller: passwordController,
              label: 'Password',
              icon: Icons.lock_outline,
              obscureText: !showPassword,
              validator: (value) =>
                  Validators.requiredText(value, field: 'Password'),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onLogin(),
              trailing: IconButton(
                tooltip: showPassword
                    ? 'Sembunyikan password'
                    : 'Lihat password',
                onPressed: onTogglePassword,
                icon: Icon(
                  showPassword ? Icons.visibility_off : Icons.visibility,
                  color: _LoginScreenState._brandBlue,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return _LoginButton(
                  isLoading: auth.isLoading,
                  onPressed: onLogin,
                );
              },
            ),
            FutureBuilder<bool>(
              future: context.read<AuthProvider>().canUseBiometricLogin(),
              builder: (context, snapshot) {
                final canUse = snapshot.data == true;
                if (!canUse) return const SizedBox(height: 16);
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return OutlinedButton.icon(
                        onPressed: auth.isBiometricLoading
                            ? null
                            : onBiometricLogin,
                        icon: auth.isBiometricLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.fingerprint_rounded),
                        label: const Text('Masuk dengan Sidik Jari'),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const _LoginHint(),
          ],
        ),
      ),
    );
  }
}

class _PanelHandle extends StatelessWidget {
  const _PanelHandle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 6,
          decoration: BoxDecoration(
            color: _LoginScreenState._brandBlue,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: _LoginScreenState._coral,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

class _LoginTextField extends StatefulWidget {
  const _LoginTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.obscureText = false,
    this.textInputAction,
    this.onSubmitted,
    this.trailing,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? trailing;

  @override
  State<_LoginTextField> createState() => _LoginTextFieldState();
}

class _LoginTextFieldState extends State<_LoginTextField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocus);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocus() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: focused ? Colors.white : const Color(0xFFF7FBFF),
        border: Border.all(
          color: focused
              ? _LoginScreenState._brandBlue
              : _LoginScreenState._line,
          width: focused ? 1.7 : 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        validator: widget.validator,
        obscureText: widget.obscureText,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onSubmitted,
        cursorColor: _LoginScreenState._ink,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: _LoginScreenState._ink,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          filled: false,
          labelText: widget.label,
          labelStyle: TextStyle(
            color: focused
                ? _LoginScreenState._brandBlue
                : _LoginScreenState._muted,
            fontWeight: FontWeight.w700,
          ),
          prefixIcon: Icon(
            widget.icon,
            color: focused ? _LoginScreenState._ink : _LoginScreenState._muted,
            size: 21,
          ),
          suffixIcon: widget.trailing,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
        ),
      ),
    );
  }
}

class _LoginButton extends StatefulWidget {
  const _LoginButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isLoading
          ? null
          : (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? .985 : 1,
        duration: const Duration(milliseconds: 120),
        child: FilledButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            elevation: 0,
            backgroundColor: _LoginScreenState._brandDark,
            disabledBackgroundColor: _LoginScreenState._muted,
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: widget.isLoading
                ? const SizedBox(
                    key: ValueKey('loading'),
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    key: ValueKey('label'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Login'),
                      SizedBox(width: 9),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _LoginHint extends StatelessWidget {
  const _LoginHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBDD),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: _LoginScreenState._brandBlue,
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Username kasir otomatis memakai email kasir@bakulandfrozen.local.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _LoginScreenState._muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
