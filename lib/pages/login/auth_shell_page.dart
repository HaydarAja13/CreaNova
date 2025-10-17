import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth_service.dart';
import '../../services/user_repository.dart';
import '../../widgets/auth_tabs.dart';

class AuthShellPage extends StatefulWidget {
  const AuthShellPage({super.key});

  @override
  State<AuthShellPage> createState() => _AuthShellPageState();
}

class _AuthShellPageState extends State<AuthShellPage> {
  // true = Daftar (kanan), false = Login (kiri)
  bool _isLogin = true;

  // Palette
  static const Color kDarkGreen = Color(0xFF123524);
  static const Color kWhite = Color(0xFFFAFAFA);
  static const Color kMuted = Color(0xFF8B9399);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: kWhite,
      body: Stack(
        children: [
          Container(height: 310, width: double.infinity, color: kDarkGreen),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 64),
                  Text(
                    _isLogin ? 'Masuk' : 'Buat Akun',
                    style: const TextStyle(
                      color: kWhite, fontSize: 28, fontWeight: FontWeight.w700, height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isLogin
                        ? 'Selamat datang kembali di TukarIn.\nAyo lanjutkan perjalanan hijau kamu!'
                        : 'Gabung bersama ribuan pengguna TukarIn.\nUbah sampahmu jadi poin dan reward menarik!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13.5, height: 1.35, fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 64),

                  // Card putih
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    decoration: BoxDecoration(
                      color: kWhite,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 8))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Tabs ganti isi, bukan route
                        AuthTabs(
                          activeLeft: _isLogin,
                          onTapLeft:  () => setState(() => _isLogin = true),
                          onTapRight: () => setState(() => _isLogin = false),
                        ),
                        const SizedBox(height: 48),

                        // Area form yang berganti halus
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: _isLogin
                              ? const _LoginForm(key: ValueKey('login'))
                              : const _RegisterForm(key: ValueKey('register')),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: media.size.height * 0.06),
                  Center(
                    child: Text(
                      '2025 © TukarIn',
                      style: TextStyle(color: kMuted, fontSize: 12.5, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ====================== SHARED FIELDS ======================
class _Label extends StatelessWidget {
  final String text;
  final Color color;
  const _Label(this.text, {required this.color});
  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(color: color, fontSize: 13.5, fontWeight: FontWeight.w600));
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final String? Function(String?)? validator;

  static const Color kTextDark = Color(0xFF0B1215);
  static const Color kFieldBorder = Color(0xFFE6E6E6);

  const _Field({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: kTextDark, fontSize: 14.5),
      validator: validator ?? (v) { if ((v ?? '').trim().isEmpty) return 'Tidak boleh kosong'; return null; },
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: suffix,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kFieldBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kFieldBorder, width: 1.2)),
      ),
    );
  }
}

// ====================== REGISTER FORM ======================
class _RegisterForm extends StatefulWidget {
  const _RegisterForm({super.key});
  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();

  bool _obscure = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  static const Color kDarkGreen = Color(0xFF123524);
  static const Color kWhite = Color(0xFFFAFAFA);
  static const Color kTextDark = Color(0xFF0B1215);
  static const Color kMuted = Color(0xFF8B9399);

  @override
  void dispose() {
    _emailC.dispose();
    _passC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _Label('Email', color: kTextDark),
        const SizedBox(height: 8),
        _Field(
          controller: _emailC,
          hint: 'Email@gmail.com',
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            final t = (v ?? '').trim();
            if (t.isEmpty) return 'Email wajib diisi';
            final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(t);
            if (!ok) return 'Format email tidak valid';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _Label('Password', color: kTextDark),
        const SizedBox(height: 8),
        _Field(
          controller: _passC,
          hint: '••••••••',
          obscure: _obscure,
          validator: (v) {
            final t = v ?? '';
            if (t.isEmpty) return 'Password wajib diisi';
            if (t.length < 6) return 'Minimal 6 karakter';
            return null;
          },
          suffix: IconButton(
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 22, color: kMuted),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12.5)),
        ],
        const SizedBox(height: 12),
        const SizedBox(height: 48),

        SizedBox(
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kDarkGreen,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isSubmitting ? null : _onRegisterPressed,
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(kWhite)))
                : const Text('Daftar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kWhite)),
          ),
        ),

        const SizedBox(height: 18),
        _DividerOr(),
        const SizedBox(height: 12),
        _GoogleButton(),
      ]),
    );
  }

  Future<void> _onRegisterPressed() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() { _isSubmitting = true; _errorMessage = null; });

    try {
      final cred = await authService.value.createAccount(
        email: _emailC.text.trim(),
        password: _passC.text,
      );
      await cred.user?.sendEmailVerification();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link verifikasi telah dikirim ke email kamu')),
      );
      Navigator.of(context).pushReplacementNamed('/verify');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = switch (e.code) {
        'email-already-in-use'   => 'Email sudah terdaftar.',
        'invalid-email'          => 'Format email tidak valid.',
        'weak-password'          => 'Password terlalu lemah (min. 6 karakter).',
        'operation-not-allowed'  => 'Pendaftaran dinonaktifkan.',
        'network-request-failed' => 'Jaringan bermasalah. Coba lagi.',
        _                        => e.message ?? 'Terjadi kesalahan. Coba lagi.',
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Terjadi kesalahan tak terduga.');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
}

// ====================== LOGIN FORM ======================
class _LoginForm extends StatefulWidget {
  const _LoginForm({super.key});
  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();

  bool _obscure = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  static const Color kDarkGreen = Color(0xFF123524);
  static const Color kWhite = Color(0xFFFAFAFA);
  static const Color kTextDark = Color(0xFF0B1215);
  static const Color kMuted = Color(0xFF8B9399);

  @override
  void dispose() {
    _emailC.dispose();
    _passC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _Label('Email', color: kTextDark),
        const SizedBox(height: 8),
        _Field(
          controller: _emailC,
          hint: 'Email@gmail.com',
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            final t = (v ?? '').trim();
            if (t.isEmpty) return 'Email wajib diisi';
            final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(t);
            if (!ok) return 'Format email tidak valid';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _Label('Password', color: kTextDark),
        const SizedBox(height: 8),
        _Field(
          controller: _passC,
          hint: '••••••••',
          obscure: _obscure,
          validator: (v) {
            final t = v ?? '';
            if (t.isEmpty) return 'Password wajib diisi';
            if (t.length < 6) return 'Minimal 6 karakter';
            return null;
          },
          suffix: IconButton(
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 22, color: kMuted),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12.5)),
        ],
        const SizedBox(height: 12),
        const SizedBox(height: 48),

        SizedBox(
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kDarkGreen,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isSubmitting ? null : _onLoginPressed,
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(kWhite)))
                : const Text('Masuk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kWhite)),
          ),
        ),

        const SizedBox(height: 18),
        _DividerOr(),
        const SizedBox(height: 12),
        _GoogleButton(),
      ]),
    );
  }

  Future<void> _onLoginPressed() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() { _isSubmitting = true; _errorMessage = null; });

    try {
      final cred = await authService.value.signIn(
        email: _emailC.text.trim(),
        password: _passC.text,
      );
      await cred.user?.reload();
      final verified = cred.user?.emailVerified ?? false;

      if (!mounted) return;
      if (!verified) {
        await FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email belum terverifikasi')));
        Navigator.of(context).pushReplacementNamed('/verify');
        return;
      }
      await UserRepository().ensureDefaults();
      Navigator.of(context).pushNamedAndRemoveUntil('/shell', (r) => false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = switch (e.code) {
        'user-not-found'        => 'Akun tidak ditemukan.',
        'wrong-password'        => 'Password salah.',
        'invalid-email'         => 'Format email tidak valid.',
        'user-disabled'         => 'Akun dinonaktifkan.',
        'network-request-failed'=> 'Masalah jaringan.',
        _                       => e.message ?? 'Gagal login.',
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Terjadi kesalahan tak terduga.');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
}

// ====================== SMALL PARTS ======================
class _DividerOr extends StatelessWidget {
  const _DividerOr();
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Container(height: 1, color: const Color(0xFFECECEC))),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Text('atau gunakan', style: TextStyle(fontSize: 12)),
      ),
      Expanded(child: Container(height: 1, color: const Color(0xFFECECEC))),
    ]);
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE3E8E5)),
          backgroundColor: const Color(0xFFEFF4ED),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {
          // TODO: Google Sign-In
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icons/google.png', width: 22, height: 22, errorBuilder: (_, __, ___) => const Icon(Icons.circle_outlined, size: 20)),
            const SizedBox(width: 10),
            const Text('Google', style: TextStyle(color: Color(0xFF0B1215), fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
