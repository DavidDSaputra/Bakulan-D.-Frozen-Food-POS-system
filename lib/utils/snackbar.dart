import 'dart:async';

import 'package:flutter/material.dart';

OverlayEntry? _activeToast;

void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
  double bottomMargin = 18,
}) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;

  _activeToast?.remove();
  _activeToast = null;

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) {
      return _TopToast(
        message: message,
        isError: isError,
        onClosed: () {
          if (_activeToast == entry) _activeToast = null;
          entry.remove();
        },
      );
    },
  );

  _activeToast = entry;
  overlay.insert(entry);
}

class _TopToast extends StatefulWidget {
  const _TopToast({
    required this.message,
    required this.isError,
    required this.onClosed,
  });

  final String message;
  final bool isError;
  final VoidCallback onClosed;

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _controller.forward();
    _timer = Timer(const Duration(milliseconds: 1450), _close);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (!mounted) return;
    await _controller.reverse();
    if (mounted) widget.onClosed();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final toastWidth = width < 390 ? width - 32 : 340.0;
    final top = media.padding.top + 12;
    final background = widget.isError ? scheme.error : const Color(0xFFC63D0F);
    final foreground = widget.isError ? scheme.onError : Colors.white;

    return Positioned(
      top: top,
      left: (width - toastWidth) / 2,
      width: toastWidth,
      child: SafeArea(
        top: false,
        child: Material(
          color: Colors.transparent,
          child: FadeTransition(
            opacity: _animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -.35),
                end: Offset.zero,
              ).animate(_animation),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: widget.isError ? .12 : .18,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .16),
                      offset: const Offset(0, 12),
                      blurRadius: 26,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.isError
                            ? Icons.error_outline_rounded
                            : Icons.check_rounded,
                        color: foreground,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          widget.message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: foreground,
                            fontWeight: FontWeight.w800,
                          ),
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
