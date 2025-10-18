import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:myapp/app_config.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth_service.dart';
import '../../models/article_item.dart';
import '../../services/user_repository.dart';
import '../../widgets/article_carousel.dart';
import '../../widgets/bank_card.dart';
import '../../models/bank_site.dart';
import 'chatbot/chatbot.dart';
import 'maps/nearest_bank_map_screen.dart';
import 'maps/nearest_finder.dart';
import 'kategori_barang/kategori_barang.dart';
import 'berita/berita.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const kGreen = AppColors.kGreen;
  static const kBg = AppColors.kBg;
  static const kText = AppColors.kText;
  static const cucumberGreen = AppColors.kText;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = UserRepository();

  late Future<Map<String, dynamic>> _profileDataFuture;

  @override
  void initState() {
    super.initState();
    _profileDataFuture = _repo.getProfile();
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _profileDataFuture = _repo.getProfile();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const kBarHeight = 32.0;
    const kFabDiameter = 64.0;
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    final spacer = bottomSafe + kBarHeight + kFabDiameter * 0.2;

    final sites = const [
      BankSite(
        name: 'BS. Omah Resik',
        address: 'Jl. Ulin Selatan VI No.114, Padangsari',
        hours: '09.00 - 16.00',
        lat: -7.0563,
        lng: 110.4390,
        imageUrl: 'https://picsum.photos/id/1011/1200/800',
      ),
      BankSite(
        name: 'BS. Tembalang',
        address: 'Jl. Pembangunan…',
        hours: '08.00 - 17.00',
        lat: -7.0580,
        lng: 110.4452,
        imageUrl: 'https://picsum.photos/id/1015/1200/800',
      ),
    ];

    final user = authService.value.currentUser;
    final name = user?.displayName;

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: HomeScreen.kGreen,
      backgroundColor: Colors.white,
      child: CustomScrollView(
        slivers: [
          // HEADER HIJAU
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF123524),
                    Color(0xFF2F522D),
                    Color(0xFF4C6F36),
                    Color(0xFF85A947),
                  ],
                  stops: [0.0, 0.63, 0.79, 1.0],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // status bar spacer already by SafeArea, but keep height
                  const SizedBox(height: 44),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi, $name',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            FutureBuilder<Map<String, dynamic>>(
                              future: _profileDataFuture,
                              builder: (context, snapshot) {
                                String locationText = 'Memuat alamat...';
                                if (snapshot.connectionState ==
                                    ConnectionState.done) {
                                  if (snapshot.hasData) {
                                    final address =
                                        snapshot.data?['address'] as String?;
                                    if (address != null && address.isNotEmpty) {
                                      locationText = address;
                                    } else {
                                      locationText = 'Alamat belum diatur';
                                    }
                                  } else {
                                    locationText = 'Gagal memuat alamat';
                                  }
                                }
                                return Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        locationText,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12.5,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Icon(
                            Icons.notifications_active,
                            color: HomeScreen.kGreen,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 27),

                  // CARD TOTAL UANG
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.06),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          stream: UserRepository().streamMe(),
                          builder: (context, snap) {
                            if (snap.connectionState ==
                                ConnectionState.waiting) {
                              return const _MoneyPlaceholder();
                            }
                            final data = snap.data?.data();
                            final totalMoney =
                                (data?['totalMoney'] as num?) ?? 0;
                            final formattedMoney = NumberFormat.decimalPattern(
                              'id_ID',
                            ).format(totalMoney);
                            return _MoneyDisplay(
                              formattedMoney: formattedMoney,
                            );
                          },
                        ),
                        const Spacer(),
                        _MiniAction(icon: Icons.history, label: 'History'),
                        const SizedBox(width: 12),
                        _MiniAction(
                          icon: Icons.compare_arrows,
                          label: 'Transfer',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ... (Sisa slivers lainnya tetap sama) ...
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('TukarIn'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      _QuickAction(
                        icon: Icons.local_shipping,
                        label: 'Dijemput Kurir',
                        onTap: () {
                          Navigator.pushNamed(context, '/pickup/location');
                        },
                      ),
                      _QuickAction(
                        icon: Icons.assignment_return,
                        label: 'Setor Langsung',
                        onTap: () async {
                          final chosen = await Navigator.of(context).push<BankSite>(
                            MaterialPageRoute(
                              builder: (_) => NearestBankMapScreen(
                                sites:
                                    sites, // <-- pakai daftar bank yang sudah kamu definisikan di atas
                                // selected: sites.first // (opsional) preselect
                              ),
                            ),
                          );

                          if (chosen != null && mounted) {
                            // untuk "Setor Langsung": buka Google Maps turn-by-turn ke bank terpilih
                            final dest = '${chosen.lat},${chosen.lng}';
                            final url = Uri.parse(
                              'https://www.google.com/maps/dir/?api=1&destination=$dest&travelmode=driving',
                            );
                            if (!await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            )) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Tidak bisa membuka Google Maps',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      ),
                      _QuickAction(
                        icon: Icons.delete,
                        label: 'Kategori Sampah',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const KategoriBarangPage(),
                            ),
                          );
                        },
                      ),
                      _QuickAction(
                        icon: Icons.smart_toy_outlined,
                        label: 'ChatBot',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ChatBotPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),

          // BANK SAMPAH TERDEKAT
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('Bank Sampah Terdekat'),
                  const SizedBox(height: 10),
                  FutureBuilder<BankSite?>(
                    future: findNearest(
                      sites,
                    ), // fungsi opsional yang aku kasih sebelumnya
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 160,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      final nearest = snap.data ?? sites.first; // fallback
                      return BankCard(
                        site: nearest,
                        staticMapsApiKey: AppConfig.googleStaticMapsKey,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // ===== ARTIKEL
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeaderRight(
                    'Artikel',
                    'Selengkapnya',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BeritaPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  ArticleCarousel(
                    items: const [
                      ArticleItem(
                        id: 'a1',
                        title:
                            'Semarang Bersih Sukses Membentuk 1.074 Bank Sampah P…',
                        date: '1 Agustus 2025',
                        source: 'TukarIn',
                        imageUrl: 'https://picsum.photos/id/1011/1200/800',
                        isNew: true,
                      ),
                      ArticleItem(
                        id: 'a2',
                        title:
                            'Panduan Pilah Sampah Plastik di Rumah yang Praktis',
                        date: '29 Juli 2025',
                        source: 'TukarIn',
                        imageUrl: 'https://picsum.photos/id/1015/1200/800',
                      ),
                      ArticleItem(
                        id: 'a3',
                        title:
                            'Cerita Bank Sampah Warga: Dari Nol Jadi Mandiri',
                        date: '25 Juli 2025',
                        source: 'TukarIn',
                        imageUrl: 'https://picsum.photos/id/1021/1200/800',
                      ),
                    ],
                    onTap: (item) {
                      // TODO: buka halaman detail artikel / route dengan item.id/link
                      // Navigator.pushNamed(context, '/article', arguments: item);
                    },
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: spacer)),
        ],
      ),
    );
  }
}

// ... (Widget kecil lainnya tetap sama, saya tambahkan placeholder Uang untuk kerapian)

class _MoneyDisplay extends StatelessWidget {
  const _MoneyDisplay({required this.formattedMoney});
  final String formattedMoney;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Total Uang',
          style: TextStyle(color: HomeScreen.kText, fontSize: 12.5),
        ),
        const SizedBox(height: 6),
        Text(
          formattedMoney,
          style: const TextStyle(
            color: HomeScreen.kText,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Rupiah',
          style: TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    );
  }
}

class _MoneyPlaceholder extends StatelessWidget {
  const _MoneyPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total Uang',
          style: TextStyle(color: HomeScreen.kText, fontSize: 12.5),
        ),
        SizedBox(height: 6),
        Text(
          '-',
          style: TextStyle(
            color: HomeScreen.kText,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.0,
          ),
        ),
        SizedBox(height: 2),
        Text('Rupiah', style: TextStyle(color: Colors.black54, fontSize: 12)),
      ],
    );
  }
}

// ...
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  static const kGreen = Color(0xFF123524);
  static const kBg = Color(0xFFFAFAFA);
  static const kText = Color(0xFF0B1215);
  static const cucumberGreen = Color(0xFF85A947);
}

// ==== SMALL PARTS ====

class _MiniAction extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MiniAction({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF4ED),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF123524)),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF0B1215)),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap; // NEW

  const _QuickAction({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cardWidth = (MediaQuery.of(context).size.width - 16 * 2 - 14) / 2;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap, // NEW
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: cardWidth,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          constraints: const BoxConstraints(minHeight: 70),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF4ED),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF123524)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0B1215),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16.5,
        fontWeight: FontWeight.w700,
        color: AppColors.kText,
      ),
    );
  }
}

class _SectionHeaderRight extends StatelessWidget {
  final String left;
  final String right;
  final VoidCallback? onTap;
  const _SectionHeaderRight(this.left, this.right, {this.onTap});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          left,
          style: const TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            color: AppColors.kText,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onTap,
          child: Text(
            right,
            style: const TextStyle(
              color: AppColors.kGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
