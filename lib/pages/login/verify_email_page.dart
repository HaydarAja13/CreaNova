import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/user_repository.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  // Palette
  static const Color kDarkGreen = Color(0xFF123524);
  static const Color kWhite = Color(0xFFFAFAFA);
  static const Color kTextDark = Color(0xFF0B1215);
  static const Color kMuted = Color(0xFF8B9399);

  // status
  bool _resending = false;
  String? _msg;
  bool _alreadyHandled = false; // prevent multi-trigger

  // resend cooldown
  static const int _cooldown = 60;
  int _left = _cooldown;
  Timer? _cooldownTimer;

  // auto check verification
  static const _pollInterval = Duration(seconds: 3);
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
    _startPollingVerification();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _left = _cooldown);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_left <= 1) {
        t.cancel();
        setState(() => _left = 0);
      } else {
        setState(() => _left--);
      }
    });
  }

  void _startPollingVerification() {
    // langsung cek sekali lalu tiap beberapa detik
    _checkAndNavigate();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _checkAndNavigate());
  }

  Future<void> _checkAndNavigate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _alreadyHandled) return;

    try {
      await user.reload();
      final verified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;

      if (!mounted || _alreadyHandled) return;
      if (verified) {
        _alreadyHandled = true;
        _pollTimer?.cancel();
        _cooldownTimer?.cancel();

        // Tampilkan pesan sukses
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email berhasil diverifikasi!'),
          ),
        );

        // Beri waktu snackbarnya tampil, lalu navigate
        await Future.delayed(const Duration(milliseconds: 900));
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/complete-profile');
      }
    } catch (_) {
      // diamkan; polling berikutnya akan mencoba lagi
    }
  }

  Future<void> _resend() async {
    if (_resending || _left > 0) return;
    setState(() { _resending = true; _msg = null; });
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (!mounted) return;
      setState(() => _msg = 'Email verifikasi dikirim ulang.');
      _startCooldown();
    } catch (_) {
      if (!mounted) return;
      setState(() => _msg = 'Gagal mengirim ulang. Coba beberapa menit lagi.');
    } finally {
      setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    final media = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: kWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back
              const SizedBox(height: 12),
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: kTextDark),
                onPressed: () => Navigator.of(context).pushReplacementNamed('/auth'),
              ),
              const SizedBox(height: 12),

              // Header: icon + (title + desc) di kanan
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icons/verify_email.png',
                    width: 90,
                    height: 90,
                    errorBuilder: (_, __, ___) =>
                    const Icon(Icons.verified_user_outlined, size: 64, color: kDarkGreen),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Verifikasi Akun',
                          style: TextStyle(
                            color: kTextDark,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kami telah mengirim tautan verifikasi ke email Anda:\n$email',
                          style: const TextStyle(
                            color: kTextDark,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Info + resend
              Center(
                child: Column(
                  children: [
                    Text(
                      'Belum menerima email? ${_formatLeft()}',
                      style: const TextStyle(color: kMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: (_left == 0 && !_resending) ? _resend : null,
                      child: _resending
                          ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Text(
                        'Kirim Ulang Email Verifikasi',
                        style: TextStyle(
                          color: kDarkGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_msg != null) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _msg!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 12.5),
                  ),
                ),
              ],

              SizedBox(height: media.size.height * 0.6),

              // Footer
              Center(
                child: Text(
                  '2025 © TukarIn',
                  style: TextStyle(color: kMuted, fontSize: 12.5, height: 1.4),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLeft() {
    final m = (_left ~/ 60).toString();
    final s = (_left % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
