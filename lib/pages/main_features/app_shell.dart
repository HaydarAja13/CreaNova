// lib/app_shell.dart
import 'package:flutter/material.dart';
import '../../widgets/nav_bar.dart';
import 'home_screen.dart';
import 'tukarin_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const kBg    = AppColors.kBg;

  int _index = 0;

  late final List<Widget> _tabs = const [
    HomeScreen(key: PageStorageKey('home')),
    TukarInScreen(key: PageStorageKey('tukarin')),
    HistoryScreen(key: PageStorageKey('history')),
    ProfileScreen(key: PageStorageKey('profile')),
  ];
  final _bucket = PageStorageBucket();

  @override
  Widget build(BuildContext context) {
    const kBarHeight   = 64.0;
    const kFabDiameter = 64.0;
    final bottomSafe   = MediaQuery.of(context).padding.bottom;
    final spacer       = bottomSafe + kBarHeight + kFabDiameter * 0.5 + 12;

    return Scaffold(
      backgroundColor: kBg,
      extendBody: true,

      // ===== BODY: tanpa push/pop, ganti tab via IndexedStack =====
      body: PageStorage(
        bucket: _bucket,
        child: Stack(
          children: [
            // konten tab
            IndexedStack(index: _index, children: _tabs),
            Positioned.fill(
              child: IgnorePointer(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(height: spacer),
                ),
              ),
            ),
          ],
        ),
      ),

      // ===== FAB: gradient + border putih bulat =====
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        width: kFabDiameter,
        height: kFabDiameter,
        child: FloatingActionButton(
          onPressed: () async {
            // Go to scanner and wait for a result
            final String? code = await Navigator.of(context).pushNamed('/scan-qr') as String?;
            if (code != null && context.mounted) {
              // do something with the result (e.g., verify ticket, fetch bank sampah, etc.)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('QR: $code')),
              );
            }
          },
          shape: const CircleBorder(),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF85A947),
                  Color(0xFF123524),
                ],
              ),
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: const Center(
              child: Icon(Icons.qr_code_scanner, color: kBg),
            ),
          ),
        ),
      ),

      // ===== NAVBAR: persist untuk semua tab, tanpa reload =====
      bottomNavigationBar: NavBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        white: kBg,
        activeColor: Colors.white,
        inactiveColor: const Color(0xFF777777),
      ),
    );
  }
}
