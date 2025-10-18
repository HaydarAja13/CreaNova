// lib/tukarin_screen.dart
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../models/bank_site.dart';
import '../pickup/pickup_location_screen.dart';

class TukarInScreen extends StatefulWidget {
  const TukarInScreen({super.key});

  @override
  State<TukarInScreen> createState() => _TukarInScreenState();
}

class _TukarInScreenState extends State<TukarInScreen> {
  static const kGreen = Color(0xFF123524);
  static const kBg    = Color(0xFFFAFAFA);
  static const kText  = Color(0xFF0B1215);

  // ---- dynamic sites from backend ----
  List<BankSite> _allSites = [];
  bool _sitesLoading = true;
  String? _sitesError;

  // ---- state ----
  final _searchC = TextEditingController();
  Timer? _debounce;
  String _query = '';
  Position? _pos;
  BankSite? _selected;

  GoogleMapController? _map;
  CameraPosition _initialCam = const CameraPosition(
    target: LatLng(-7.0563, 110.4390), // fallback Semarang-ish
    zoom: 14,
  );

  // marker icons (with safe fallbacks)
  BitmapDescriptor? _userIcon;
  BitmapDescriptor? _bankIcon;
  BitmapDescriptor? _bankSelIcon;

  @override
  void initState() {
    super.initState();
    _searchC.addListener(_onSearchChanged);
    _loadIcons();
    _initLocation();
    _fetchSites();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchC.dispose();
    _map?.dispose();
    super.dispose();
  }

  // ---------- Icons ----------
  Future<BitmapDescriptor> _bitmapFromAsset(String path, {int width = 84}) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    final fi = await codec.getNextFrame();
    final bytes = (await fi.image.toByteData(format: ui.ImageByteFormat.png))!;
    return BitmapDescriptor.fromBytes(bytes.buffer.asUint8List());
  }

  Future<void> _loadIcons() async {
    // fallbacks first
    _userIcon    = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    _bankIcon    = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    _bankSelIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

    try { _userIcon    = await _bitmapFromAsset('assets/icons/user_pin.png', width: 96); } catch (_) {}
    try { _bankIcon    = await _bitmapFromAsset('assets/icons/bank_pin.png', width: 96); } catch (_) {}
    try { _bankSelIcon = await _bitmapFromAsset('assets/icons/bank_pin_selected.png', width: 96); } catch (_) {}

    if (mounted) setState(() {});
  }

  // ---------- Location & camera ----------
  Future<void> _initLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin lokasi ditolak permanen. Buka pengaturan.')),
        );
        await Geolocator.openAppSettings();
        return;
      }

      if (await Geolocator.isLocationServiceEnabled()) {
        final p = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        _pos = p;
        _selected ??= _nearestTo(p.latitude, p.longitude);
        _initialCam = CameraPosition(target: LatLng(p.latitude, p.longitude), zoom: 15);
        if (mounted) setState(() {});
        // optionally pan camera if already created
        _map?.animateCamera(CameraUpdate.newCameraPosition(_initialCam));
      } else {
        if (_allSites.isNotEmpty) {
          _selected ??= _allSites.first;
        }
      }
    } catch (_) {
      if (_allSites.isNotEmpty) {
        _selected ??= _allSites.first;
      }
    }
  }

  BankSite? _nearestTo(double lat, double lng) {
    if (_allSites.isEmpty) return null;
    BankSite best = _allSites.first;
    double bestD = double.infinity;
    for (final s in _allSites) {
      final d = Geolocator.distanceBetween(lat, lng, s.lat, s.lng);
      if (d < bestD) { bestD = d; best = s; }
    }
    return best;
  }

  // ---------- Search ----------
  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 160), () {
      if (!mounted) return;
      setState(() => _query = _searchC.text);
    });
  }

  List<BankSite> _filteredSites() {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _allSites;
    return _allSites.where((s) =>
    s.name.toLowerCase().contains(q) || s.address.toLowerCase().contains(q)
    ).toList();
  }

  // ---- Fetch sites from API ----
  Future<void> _fetchSites() async {
    setState(() {
      _sitesLoading = true;
      _sitesError = null;
    });
    try {
      final uri = Uri.parse('https://well-pelican-real.ngrok-free.app/api/users');
      final res = await http.get(uri);
      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }
      final body = jsonDecode(res.body);
      final List data = body is List ? body : (body['data'] as List? ?? const []);
      final items = <BankSite>[];
      for (final raw in data) {
        final m = raw as Map<String, dynamic>;
        final lat = _toDouble(m['bankLat']);
        final lng = _toDouble(m['bankLng']);
        if (lat == null || lng == null) continue;
        final name = (m['name'] ?? 'Lokasi').toString();
        final address = (m['bankAddress'] ?? '').toString();
        final imageUrl = (m['avatar_url'] ?? m['photoUrl'] ?? 'https://picsum.photos/seed/${name.hashCode}/800/600').toString();
        items.add(BankSite(
          name: name,
          address: address.isEmpty ? 'Alamat belum tersedia' : address,
          hours: '08.00 - 17.00',
          lat: lat,
          lng: lng,
          imageUrl: imageUrl,
        ));
      }
      if (!mounted) return;
      setState(() {
        _allSites = items;
        _sitesLoading = false;
      });
      // choose nearest if we already have location and none selected
      if (_pos != null && _selected == null && _allSites.isNotEmpty) {
        setState(() {
          _selected = _nearestTo(_pos!.latitude, _pos!.longitude);
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sitesError = 'Gagal memuat lokasi: $e';
        _sitesLoading = false;
        _allSites = [];
      });
    }
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    final s = v.toString();
    if (s.isEmpty) return null;
    return double.tryParse(s.replaceAll(',', '.'));
  }

  // ---------- Map helpers ----------
  Set<Marker> _markers() {
    final map = <String, Marker>{};

    // user marker (if we have it)
    if (_pos != null) {
      const id = 'user';
      map[id] = Marker(
        markerId: const MarkerId(id),
        position: LatLng(_pos!.latitude, _pos!.longitude),
        infoWindow: const InfoWindow(title: 'Lokasi Anda'),
        icon: _userIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );
    }

    // bank markers
    for (final s in _filteredSites()) {
      final id = 'bank_${s.name}';
      final isSel = _selected?.name == s.name;
      map[id] = Marker(
        markerId: MarkerId(id),
        position: LatLng(s.lat, s.lng),
        infoWindow: InfoWindow(title: s.name, snippet: s.address),
        icon: isSel
            ? (_bankSelIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed))
            : (_bankIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)),
        onTap: () {
          setState(() => _selected = s);
        },
      );
    }

    return map.values.toSet();
  }

  Future<void> _focusTo(LatLng target, {double zoom = 16}) async {
    if (_map == null) return;
    await _map!.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: target, zoom: zoom)),
    );
  }

  Future<void> _fitToUserAnd(BankSite s) async {
    if (_map == null) return;
    if (_pos == null) {
      await _focusTo(LatLng(s.lat, s.lng), zoom: 16);
      return;
    }
    final sw = LatLng(
      math.min(_pos!.latitude, s.lat),
      math.min(_pos!.longitude, s.lng),
    );
    final ne = LatLng(
      math.max(_pos!.latitude, s.lat),
      math.max(_pos!.longitude, s.lng),
    );
    await _map!.animateCamera(CameraUpdate.newLatLngBounds(LatLngBounds(southwest: sw, northeast: ne), 64));
  }

  // ---------- External navigation ----------
  Future<void> _openInMaps(BankSite s) async {
    final name = Uri.encodeComponent(s.name);
    final base = 'https://www.google.com/maps/dir/?api=1';
    final dest = '&destination=${s.lat},${s.lng}($name)';
    final origin = (_pos != null)
        ? '&origin=${_pos!.latitude},${_pos!.longitude}'
        : '';
    final uri = Uri.parse('$base$origin$dest&travelmode=driving');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    final sites = _filteredSites();

    // keep in sync with your shell
    const kBarHeight = 32.0;
    const kFabDiameter = 32.0;
    final bottomSafe = MediaQuery.of(context).padding.bottom;
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
                _SquareIconButton(icon: Icons.local_shipping, onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PickupLocationScreen()),
                  );
                }),
              ],
            ),
            const SizedBox(height: 12),

            // ===== Search =====
            _SearchBar(
              controller: _searchC,
              hint: 'Cari Bank Sampah...',
              onChanged: (_) {}, // handled by controller + debounce
            ),
            const SizedBox(height: 12),

            // ===== Map =====
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: navSpacer),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: GoogleMap(
                          initialCameraPosition: _initialCam,
                          onMapCreated: (c) => _map = c,
                          markers: _markers(),
                          myLocationEnabled: _pos != null, // show blue dot if granted
                          myLocationButtonEnabled: false,
                          mapToolbarEnabled: false,
                          compassEnabled: true,
                          zoomControlsEnabled: false,
                          // gestures enabled by default
                        ),
                      ),

                      // Zoom & my location
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Column(
                          children: [
                            _RoundIcon(
                              icon: Icons.add,
                              onTap: () {
                                _map?.animateCamera(CameraUpdate.zoomIn());
                              },
                            ),
                            const SizedBox(height: 8),
                            _RoundIcon(
                              icon: Icons.remove,
                              onTap: () {
                                _map?.animateCamera(CameraUpdate.zoomOut());
                              },
                            ),
                            const SizedBox(height: 8),
                            _RoundIcon(icon: Icons.my_location, onTap: () async {
                              if (_pos == null) { await _initLocation(); return; }
                              _focusTo(LatLng(_pos!.latitude, _pos!.longitude), zoom: 16);
                            }),
                          ],
                        ),
                      ),

                      // Bottom chips carousel
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
                              itemCount: sites.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 10),
                              itemBuilder: (_, i) {
                                final s = sites[i];
                                final selected = _selected?.name == s.name;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() => _selected = s);
                                    _fitToUserAnd(s);
                                  },
                                  onDoubleTap: () => _openInMaps(s),
                                  child: _SiteChipCard(
                                    site: s,
                                    selected: selected,
                                    onDirection: () => _openInMaps(s),
                                  ),
                                );
                              },
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
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Cari Bank Sampah...',
                  hintStyle: TextStyle(color: Colors.black45, fontSize: 14.5),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              site.imageUrl,
              width: 46,
              height: 46,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 46, height: 46,
                  color: const Color(0xFFEFF4ED),
                  child: const Center(
                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                width: 46, height: 46,
                color: const Color(0xFFEFF4ED),
                child: const Icon(Icons.photo, color: Colors.black38),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(site.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: _TukarInScreenState.kText)),
              const SizedBox(height: 2),
              Text(site.address, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54, fontSize: 12)),
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
