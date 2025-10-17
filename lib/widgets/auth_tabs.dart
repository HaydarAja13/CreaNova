// lib/widgets/auth_tabs.dart
import 'package:flutter/material.dart';

class AuthTabs extends StatelessWidget {
  /// true  => "Daftar" aktif (kanan)
  /// false => "Login"  aktif (kiri)
  final bool activeLeft;

  /// Dipanggil saat tab "Login" ditekan (ketika tidak aktif)
  final VoidCallback? onTapLeft;

  /// Dipanggil saat tab "Daftar" ditekan (ketika tidak aktif)
  final VoidCallback? onTapRight;

  const AuthTabs({
    super.key,
    required this.activeLeft,
    this.onTapLeft,
    this.onTapRight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4ED),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Segment(
              label: 'Login',
              active: activeLeft,
              onTap: onTapLeft,
            ),
          ),
          Expanded(
            child: _Segment(
              label: 'Daftar',
              active: !activeLeft,
              onTap: onTapRight,
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;

  static const Color kDarkGreen = Color(0xFF123524);
  static const Color kTextDark  = Color(0xFF0B1215);
  static const Color kWhite     = Color(0xFFFAFAFA);

  const _Segment({
    required this.label,
    required this.active,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = Center(
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: active ? kWhite : kTextDark,
        ),
      ),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: active ? kDarkGreen : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: active ? null : onTap,
        child: child,
      ),
    );
  }
}
