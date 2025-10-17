// lib/tukarin_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/bank_site.dart';
import '../../app_config.dart';

class TukarInScreen extends StatefulWidget {
  const TukarInScreen({super.key});

  @override
  State<TukarInScreen> createState() => _TukarInScreenState();
}

class _TukarInScreenState extends State<TukarInScreen> {
  static const kGreen = Color(0xFF123524);
  static const kBg    = Color(0xFFFAFAFA);
  static const kText  = Color(0xFF0B1215);

  // ---- data dummy awal (ganti ke data backendmu) ----
  final List<BankSite> _allSites = const [
    BankSite(
      name: 'Bank Sampah Omah Resik',
      address: 'Jl. Ulin Selatan VI No.114, Padangsari',
      hours: '09.00 - 16.00',
      lat: -7.0563, lng: 110.4390,
      imageUrl: 'https://picsum.photos/id/1011/1200/800'
    ),
    BankSite(
      name: 'Bank Sampah Umbulrejo',
      address: 'Jl. Umbulrejo No. 2',
      hours: '08.00 - 17.00',
      lat: -7.0590, lng: 110.4445,
      imageUrl: 'https://picsum.photos/id/1015/1200/800'
    ),
    BankSite(
      name: 'Bank Sampah Ngudi Lestari',
      address: 'Jl. Ngudi Lestari',
      hours: '08.00 - 16.00',
      lat: -7.0505, lng: 110.4480,
      imageUrl: 'https://picsum.photos/id/1021/1200/800'
    ),
  ];

  // ---- state ----
  String _query = '';
  Position? _pos;
  BankSite? _highlight;   // yang sedang dipilih/terdekat
  double _zoom = 14;      // kamu bisa naikkan/turunkan

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      if (await Geolocator.isLocationServiceEnabled()) {
        final p = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() => _pos = p);
        _pickNearest();
      }
    } catch (_) {
      // tetap jalan dengan center default kalau gagal izin
    }
  }

  void _pickNearest() {
    if (_pos == null) return;
    BankSite? best;
    double bestDist = double.infinity;
    for (final s in _allSites) {
      final d = Geolocator.distanceBetween(
        _pos!.latitude, _pos!.longitude, s.lat, s.lng,
      );
      if (d < bestDist) {
        bestDist = d;
        best = s;
      }
    }
    setState(() => _highlight = best);
  }

  // Bangun URL Static Maps (multi-marker), marker terpilih hijau
  String _buildStaticMapUrl() {
    // center: lokasi user jika ada, kalau tidak pakai site pertama
    final clat = _pos?.latitude  ?? _allSites.first.lat;
    final clng = _pos?.longitude ?? _allSites.first.lng;

    final params = <String, String>{
      'center': '$clat,$clng',
      'zoom': _zoom.toStringAsFixed(0),
      'size': '800x1000', // besar → tajam; widget akan scale down
      'scale': '2',
      'maptype': 'roadmap',
      'key': AppConfig.googleStaticMapsKey,
    };

    // marker user (biru)
    final markers = <String>[
      'color:blue|label:U|$clat,$clng',
    ];

    // marker bank sampah
    for (final s in _filteredSites()) {
      final isHi = _highlight?.name == s.name;
      final color = isHi ? 'green' : 'red';
      // label 1 huruf
      final label = s.name.isNotEmpty ? s.name[0].toUpperCase() : 'B';
      markers.add('color:$color|label:$label|${s.lat},${s.lng}');
    }

    // gabung markers; untuk Static Maps, param markers diulang-ulang
    final markerParams = markers
        .map((m) => 'markers=${Uri.encodeQueryComponent(m)}')
        .join('&');

    final query = params.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');

    return 'https://maps.googleapis.com/maps/api/staticmap?$query&$markerParams';
  }

  List<BankSite> _filteredSites() {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _allSites;
    return _allSites.where((s) =>
    s.name.toLowerCase().contains(q) || s.address.toLowerCase().contains(q)
    ).toList();
  }

  Future<void> _openInMaps(BankSite s) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${s.lat},${s.lng}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final sites = _filteredSites();
    // keep in sync with AppShell
    const kBarHeight = 32.0;
    const kFabDiameter = 32.0;
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    // how high we must float content above the navbar+FAB
    final navSpacer = bottomSafe + kBarHeight + kFabDiameter * 0.2;


    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== Header =====
            Row(
              children: [
                const Text('TukarIn', style: TextStyle(color: kText, fontSize: 22, fontWeight: FontWeight.w700)),
                const Spacer(),
                _SquareIconButton(icon: Icons.local_shipping, onTap: () {}),
              ],
            ),
            const SizedBox(height: 12),

            // ===== Search =====
            _SearchBar(
              controller: TextEditingController(text: _query),
              hint: 'Cari Bank Sampah...',
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 12),

            // ===== Map + overlays =====
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: navSpacer),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    children: [
                      // Static map
                      Positioned.fill(
                        child: Image.network(
                          _buildStaticMapUrl(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: const Color(0xFFE8EEE6), child: const Center(child: Text('Map error'))),
                        ),
                      ),

                      // Zoom controls
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Column(
                          children: [
                            _RoundIcon(
                              icon: Icons.add,
                              onTap: () => setState(() => _zoom = math.min(20, _zoom + 1)),
                            ),
                            const SizedBox(height: 8),
                            _RoundIcon(
                              icon: Icons.remove,
                              onTap: () => setState(() => _zoom = math.max(3, _zoom - 1)),
                            ),
                            const SizedBox(height: 8),
                            _RoundIcon(
                              icon: Icons.my_location,
                              onTap: _initLocation,
                            ),
                          ],
                        ),
                      ),

                      // Bottom sites carousel (chips-list)
                      if (sites.isNotEmpty)
                        Positioned(
                          left: 10,
                          right: 10,
                          bottom: 14,
                          child: SizedBox(
                            height: 96,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              itemBuilder: (_, i) {
                                final s = sites[i];
                                final selected = _highlight?.name == s.name;
                                return GestureDetector(
                                  onTap: () => setState(() => _highlight = s),
                                  onDoubleTap: () => _openInMaps(s),
                                  child: _SiteChipCard(site: s, selected: selected, onDirection: () => _openInMaps(s)),
                                );
                              },
                              separatorBuilder: (_, __) => const SizedBox(width: 10),
                              itemCount: sites.length,
                            ),
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

/// ===== UI helpers =====

class _SquareIconButton extends StatelessWidget {
  final IconData icon; final VoidCallback? onTap;
  const _SquareIconButton({required this.icon, this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF1F4F0),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(width: 42, height: 42, child: Icon(icon, color: _TukarInScreenState.kGreen)),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon; final VoidCallback? onTap;
  const _RoundIcon({required this.icon, this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 42, height: 42, child: Icon(icon, color: _TukarInScreenState.kGreen)),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  const _SearchBar({required this.hint, this.onChanged, this.controller});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white, borderRadius: BorderRadius.circular(24), elevation: 0,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            const Icon(Icons.search, size: 20, color: Colors.black45),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: hint,
                  hintStyle: const TextStyle(color: Colors.black45, fontSize: 14.5),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SiteChipCard extends StatelessWidget {
  final BankSite site;
  final bool selected;
  final VoidCallback onDirection;
  const _SiteChipCard({required this.site, required this.selected, required this.onDirection});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.94),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 10, offset: const Offset(0, 6))],
        border: Border.all(color: selected ? _TukarInScreenState.kGreen : Colors.transparent, width: 1.2),
      ),
      child: Row(
        children: [
          // MODIFIED: Mengganti Container dengan gambar dari network
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              site.imageUrl, // Mengambil URL dari objek site
              width: 46,
              height: 46,
              fit: BoxFit.cover, // Memastikan gambar mengisi area
              // Widget yang tampil saat gambar sedang di-load
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 46,
                  height: 46,
                  color: const Color(0xFFEFF4ED),
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2.0),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(site.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, color: _TukarInScreenState.kText)),
              const SizedBox(height: 2),
              Text(site.address, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54, fontSize: 12)),
            ]),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onDirection,
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: _TukarInScreenState.kGreen,
              child: Icon(Icons.navigation, color: _TukarInScreenState.kBg, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
