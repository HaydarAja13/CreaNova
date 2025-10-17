import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/auth_service.dart';
import 'package:myapp/services/user_repository.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class AccountInfoScreen extends StatefulWidget {
  const AccountInfoScreen({super.key});

  @override
  State<AccountInfoScreen> createState() => _AccountInfoScreenState();
}

class _AccountInfoScreenState extends State<AccountInfoScreen> {
  static const kGreen = Color(0xFF123524);
  static const kText  = Color(0xFF0B1215);

  final _nameC = TextEditingController();
  final _repo = UserRepository();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = authService.value.currentUser;
    _nameC.text = u?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameC.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x == null) return;

    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Cloudinary config
      const cloudName = 'dbad7of94';
      const uploadPreset = 'tukarin-project';

      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final req = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] = 'users/$uid'
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          x.path,
          filename: 'avatar${p.extension(x.path)}',
        ));

      final res = await req.send();
      final body = await res.stream.bytesToString();
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception('Upload failed: ${res.statusCode} $body');
      }

      final secureUrl = (jsonDecode(body) as Map)['secure_url'] as String;

      await FirebaseAuth.instance.currentUser!.updatePhotoURL(secureUrl);
      await _repo.upsertProfile(photoURL: secureUrl);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto profil diperbarui')),
      );
      setState(() {}); // refresh avatar
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal upload: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveName() async {
    final name = _nameC.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      await FirebaseAuth.instance.currentUser!.updateDisplayName(name);
      await _repo.upsertProfile(displayName: name);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama diperbarui')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal update nama: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _sendResetEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada email pada akun ini')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Link reset dikirim ke ${user.email}')),
      );
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'invalid-email' => 'Email tidak valid.',
        'user-not-found' => 'Akun tidak ditemukan.',
        'too-many-requests' => 'Terlalu banyak percobaan. Coba lagi nanti.',
        _ => e.message ?? 'Gagal mengirim email reset.',
      };
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteAccountFlow() async {
    // 1) Confirm
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Akun?'),
        content: const Text('Tindakan ini permanen dan tidak bisa dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (sure != true) return;

    // 2) Ask current password for reauth (email/password flow)
    final pwd = await showDialog<String>(
      context: context,
      builder: (ctx) => const _InputPasswordDialog(),
    );
    if (pwd == null || pwd.isEmpty) return;

    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final email = user.email;
      if (email == null) throw FirebaseAuthException(code: 'no-email', message: 'Akun tidak punya email.');

      // Re-authenticate
      final cred = EmailAuthProvider.credential(email: email, password: pwd);
      await user.reauthenticateWithCredential(cred);

      // Delete auth user
      await user.delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akun dihapus.')),
      );
      // Navigate to splash/login
      // ignore: use_build_context_synchronously
      Navigator.of(context).pushNamedAndRemoveUntil('/auth', (_) => false);
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'wrong-password' => 'Password salah.',
        'requires-recent-login' => 'Sesi login sudah lama. Silakan login ulang.',
        _ => e.message ?? 'Gagal menghapus akun.',
      };
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const kBarHeight = 64.0;
    const kFabDiameter = 64.0;
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    final spacer = bottomSafe + kBarHeight + (kFabDiameter * .5) + 12;

    final u = FirebaseAuth.instance.currentUser;

    return SafeArea(
      bottom: false,
      child: Material(
        color: Colors.white,
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.fromLTRB(16, 12, 16, spacer),
              children: [
                const Text('Info Akun Saya',
                    style: TextStyle(color: kText, fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),

                // Avatar + tombol edit
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: const Color(0xFFEFF4ED),
                        backgroundImage: u?.photoURL != null ? NetworkImage(u!.photoURL!) : null,
                        child: u?.photoURL == null
                            ? const Icon(Icons.person, color: kGreen, size: 48)
                            : null,
                      ),
                      Positioned(
                        right: 0, bottom: 0,
                        child: Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _pickAndUploadPhoto,
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.edit, color: kGreen, size: 18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Nama
                const Text('Nama', style: TextStyle(fontWeight: FontWeight.w700, color: kText)),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameC,
                  decoration: InputDecoration(
                    hintText: 'Nama lengkap',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE6E6E6)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveName,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Keamanan', style: TextStyle(fontWeight: FontWeight.w700, color: kText)),
                const SizedBox(height: 8),

                Material(
                  color: Colors.white,
                  child: ListTile(
                    leading: const Icon(Icons.email_outlined, color: kGreen),
                    title: const Text('Kirim Email Reset Password'),
                    onTap: _saving ? null : _sendResetEmail,
                  ),
                ),
                const SizedBox(height: 6),
                Material(
                  color: Colors.white,
                  child: ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('Hapus Akun'),
                    onTap: _saving ? null : _deleteAccountFlow,
                  ),
                ),
              ],
            ),

            if (_saving)
              Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

class _InputPasswordDialog extends StatefulWidget {
  const _InputPasswordDialog();
  @override
  State<_InputPasswordDialog> createState() => _InputPasswordDialogState();
}

class _InputPasswordDialogState extends State<_InputPasswordDialog> {
  final c = TextEditingController();
  bool ob = true;
  @override
  void dispose() { c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Konfirmasi Password'),
      content: TextField(
        controller: c,
        obscureText: ob,
        decoration: InputDecoration(
          hintText: 'Password saat ini',
          suffixIcon: IconButton(
            onPressed: () => setState(() => ob = !ob),
            icon: Icon(ob ? Icons.visibility_off : Icons.visibility),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: const Text('Lanjut')),
      ],
    );
  }
}


