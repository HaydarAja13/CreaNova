// lib/profile_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:myapp/auth_service.dart';
import 'package:intl/intl.dart';

import '../../services/user_repository.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const kGreen = Color(0xFF123524);
  static const kBg    = Color(0xFFFAFAFA);
  static const kText  = Color(0xFF0B1215);

  @override
  Widget build(BuildContext context) {
    final user = authService.value.currentUser;
    final name  = user?.displayName ?? 'Pengguna';
    final email = user?.email ?? '-';

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: UserRepository().streamMe(),
          builder: (context, snap) {
            final data = snap.data?.data();
            final totalMoney   = (data?['totalMoney'] as num?) ?? 0;
            final totalTrashKg = (data?['totalTrashKg'] as num?) ?? 0;
            return ListView(
              padding: const EdgeInsets.only(bottom: 12),
              children: [
                // ===== Header =====
                const Text(
                  'Profil',
                  style: TextStyle(color: kText, fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 20),

                // Avatar + badge edit + nama + email
                Center(
                  child:  CircleAvatar(
                    radius: 46,
                    backgroundColor: const Color(0xFFEFF4ED),
                    backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                    child: user?.photoURL == null
                        ? const Icon(Icons.person, color: kGreen, size: 46)
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Column(
                    children: [
                      Text(name, style: const TextStyle(color: kText, fontSize: 16.5, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(email, style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ===== Dua statistik =====
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      // 2. Gunakan Expanded agar setiap stat memiliki lebar yang sama
                      Expanded(
                        child: _StatBubble(
                          icon: Icons.monetization_on_outlined,
                          label: 'Total Uang',
                          // 3. Format angka agar lebih mudah dibaca (misal: 1.500.000)
                          value: NumberFormat.decimalPattern('id_ID').format(totalMoney),
                          color: Colors.amber,
                        ),
                      ),

                      // 4. Tambahkan pemisah visual di tengah
                      SizedBox(
                        height: 40, // Atur tinggi pemisah
                        child: VerticalDivider(color: Colors.grey.shade300),
                      ),

                      Expanded(
                        child: _StatBubble(
                          icon: Icons.recycling_outlined,
                          label: 'Total Sampah',
                          // Format angka desimal dan tambahkan unit
                          value: '${NumberFormat('#,##0.0', 'id_ID').format(totalTrashKg)} Kg',
                          color: kGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // ===== Pengaturan (tanpa 'Voucherku', tanpa 'Tantangan') =====
                const Text('Pengaturan',
                    style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),

                _SettingsCard(
                  items: [
                    _SettingsItem(
                      icon: Icons.person_outline,
                      label: 'Info Akun Saya',
                      onTap: () => Navigator.pushNamed(context, '/account'),
                    ),
                    _SettingsItem(
                      icon: Icons.place_outlined,
                      label: 'Alamatku',
                      onTap: () => Navigator.pushNamed(context, '/address'),
                    ),
                    _SettingsItem(
                      icon: Icons.logout_outlined,
                      label: 'Keluar',
                      danger: true,
                      onTap: () async {
                        await authService.value.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil('/auth', (_) => false);
                        }
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// ===== KOMPONEN KECIL =====

class _StatBubble extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatBubble({required this.icon, required this.label, required this.value, required this.color});

  static const kText  = ProfileScreen.kText;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 16, offset: const Offset(0, 8)),
            ],
            border: Border.all(color: const Color(0xFFE7EDE4)),
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: kText, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<_SettingsItem> items;
  const _SettingsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _SettingsTile(item: items[i]),
            if (i != items.length - 1) const Divider(height: 1, color: Color(0xFFEAEAEA)),
          ],
        ],
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool danger;
  const _SettingsItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.danger = false,
  });
}

class _SettingsTile extends StatelessWidget {
  final _SettingsItem item;
  const _SettingsTile({required this.item});

  static const kGreen = ProfileScreen.kGreen;
  static const kText  = ProfileScreen.kText;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5EF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: item.danger ? Colors.red : kGreen),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  color: item.danger ? Colors.red : kText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              item.danger ? Icons.arrow_forward_ios_rounded : Icons.chevron_right_rounded,
              size: item.danger ? 16 : 22,
              color: item.danger ? Colors.red : Colors.black38,
            ),
          ],
        ),
      ),
    );
  }
}
