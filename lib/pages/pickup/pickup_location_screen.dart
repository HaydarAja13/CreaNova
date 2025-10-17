import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../app_config.dart';
import '../../models/bank_site.dart';
import '../main_features/maps/nearest_finder.dart';

class PickupLocationScreen extends StatefulWidget {
  const PickupLocationScreen({super.key});

  static const kGreen = Color(0xFF123524);
  static const kText  = Color(0xFF0B1215);

  @override
  State<PickupLocationScreen> createState() => _PickupLocationScreenState();
}

class _PickupLocationScreenState extends State<PickupLocationScreen> {
  final _db = FirebaseFirestore.instance;

  GoogleMapController? _map;

  Map<String, dynamic>? _profile;
  LatLng? _userLatLng;

  BankSite? _nearest;
  BankSite? _selected;

  // icons with safe fallbacks
  BitmapDescriptor? _userIcon;
  BitmapDescriptor? _bankIcon;
  BitmapDescriptor? _bankSelIcon;

  // cached route
  LatLng? _routeFrom, _routeTo;
  List<LatLng> _routePts = [];

  // contoh data bank (ganti dari backend bila perlu)
  final _sites = const [
    BankSite(
      name: 'BS. Omah Resik',
      address: 'Jl. Ulin Selatan VI No.114, Padangsari',
      hours: '09.00 - 16.00',
      lat: -7.0563, lng: 110.4390,
      imageUrl: 'https://picsum.photos/id/1011/800/600',
    ),
    BankSite(
      name: 'BS. Tembalang',
      address: 'Jl. Pembangunan…',
      hours: '08.00 - 17.00',
      lat: -7.0580, lng: 110.4452,
      imageUrl: 'https://picsum.photos/id/1015/800/600',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _map?.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _loadIcons();
    await _loadMe();

    if (_userLatLng != null) {
      _nearest = await findNearest(_sites);
      _selected = _nearest;

      // langsung tarik rute & fit ke bounds
      unawaited(_ensureRoute(
        _userLatLng!,
        LatLng(_selected!.lat, _selected!.lng),
        fitAfterDecode: true,
      ));
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadMe() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await _db.collection('users').doc(uid).get();
    _profile = doc.data() ?? {};
    final lat = (_profile?['lat'] as num?)?.toDouble();
    final lng = (_profile?['lng'] as num?)?.toDouble();
    if (lat != null && lng != null) {
      _userLatLng = LatLng(lat, lng);
    }
  }

  // ——— Icon helpers ———
  Future<BitmapDescriptor> _bitmapFromAsset(String path, {int width = 88}) async {
    final data = await DefaultAssetBundle.of(context).load(path);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    final fi = await codec.getNextFrame();
    final bytes = (await fi.image.toByteData(format: ui.ImageByteFormat.png))!;
    return BitmapDescriptor.fromBytes(bytes.buffer.asUint8List());
  }

  Future<void> _loadIcons() async {
    // set fallback dulu (hindari null!)
    _userIcon    = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    _bankIcon    = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    _bankSelIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);

    try { _userIcon    = await _bitmapFromAsset('assets/icons/user_pin.png', width: 92); } catch (_) {}
    try { _bankIcon    = await _bitmapFromAsset('assets/icons/bank_pin.png', width: 92); } catch (_) {}
    try { _bankSelIcon = await _bitmapFromAsset('assets/icons/bank_pin_selected.png', width: 92); } catch (_) {}

    if (mounted) setState(() {});
  }

  // ——— Directions & camera ———
  Future<void> _ensureRoute(LatLng from, LatLng to, {bool fitAfterDecode = false}) async {
    if (_routeFrom == from && _routeTo == to && _routePts.isNotEmpty) {
      if (fitAfterDecode) _fitToBoundsFor(from, to, _routePts);
      return;
    }

    _routeFrom = from;
    _routeTo   = to;

    final url = Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
      'origin': '${from.latitude},${from.longitude}',
      'destination': '${to.latitude},${to.longitude}',
      'mode': 'driving',
      'key': AppConfig.googleMapsKey,
    });

    try {
      final r = await http.get(url);
      if (r.statusCode != 200) {
        debugPrint('Directions HTTP ${r.statusCode}: ${r.body}');
        throw Exception('HTTP ${r.statusCode}');
      }
      final m = jsonDecode(r.body) as Map<String, dynamic>;
      final status = m['status'] as String?;  // <-- penting
      if (status != 'OK') {
        debugPrint('Directions status: $status, message: ${m['error_message']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Rute tidak tersedia: $status')),
          );
        }
        return;
      }

      final routes = (m['routes'] as List?) ?? [];
      if (routes.isEmpty) {
        debugPrint('Directions: routes empty');
        return;
      }

      final polyStr = routes.first['overview_polyline']?['points'] as String? ?? '';
      final decoded = _decodePolyline(polyStr)
          .map((e) => LatLng(e.$1, e.$2))
          .toList(growable: false);

      if (!mounted) return;
      setState(() => _routePts = decoded);

      if (fitAfterDecode) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _fitToBoundsFor(from, to, decoded));
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('Directions error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat rute')),
      );
    }
  }

  Future<void> _goToUser() async {
    if (_userLatLng == null || _map == null) return;
    await _map!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _userLatLng!, zoom: 16),
      ),
    );
    if (_selected != null) {
      // kalau mau tetap tampilkan rute setelah re-center
      unawaited(_ensureRoute(_userLatLng!, LatLng(_selected!.lat, _selected!.lng), fitAfterDecode: false));
    }
  }


  Future<void> _fitToBoundsFor(LatLng a, LatLng b, List<LatLng> route) async {
    if (_map == null) return;

    // hitung bounds dari user, bank, dan semua titik polyline
    double minLat = math.min(a.latitude, b.latitude);
    double maxLat = math.max(a.latitude, b.latitude);
    double minLng = math.min(a.longitude, b.longitude);
    double maxLng = math.max(a.longitude, b.longitude);
    for (final p in route) {
      if (p.latitude  < minLat) minLat = p.latitude;
      if (p.latitude  > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    await _map!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 64));
  }

  // ——— UI helpers ———
  Set<Marker> _markers() {
    // gunakan map sementara agar “last write wins” per id
    final map = <String, Marker>{};

    // 1) user marker (ID stabil)
    if (_userLatLng != null) {
      const id = 'user';
      map[id] = Marker(
        markerId: const MarkerId(id),
        position: _userLatLng!,
        infoWindow: const InfoWindow(title: 'Lokasi Anda'),
        icon: _userIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        onTap: _goToUser, // opsional
      );
    }

    // 2) bank markers — tepat 1 per bank
    for (final s in _sites) {
      final id = 'bank_${s.name}'; // ← PASTIKAN konsisten
      final isSel = _selected?.name == s.name;

      map[id] = Marker(
        markerId: MarkerId(id),
        position: LatLng(s.lat, s.lng),
        infoWindow: InfoWindow(title: s.name, snippet: s.address),
        icon: isSel
            ? (_bankSelIcon
            ?? _bankIcon
            ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose))
            : (_bankIcon
            ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)),
        onTap: () {
          setState(() => _selected = s);
          if (_userLatLng != null) {
            _ensureRoute(_userLatLng!, LatLng(s.lat, s.lng), fitAfterDecode: true);
          }
        },
      );
    }

    // (debug opsional)
    // debugPrint('markers: ${map.keys.toList()}');

    return map.values.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final hasUser = _userLatLng != null;
    final addr = _profile?['address'] as String? ?? 'Lokasi Penjemputan';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Pilih Lokasi Jemput'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          // ====== FULL (almost) SCREEN MAP ======
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: hasUser ? _userLatLng! : const LatLng(-6.2, 106.816666),
                zoom: hasUser ? 14 : 12,
              ),
              onMapCreated: (c) {
                _map = c;
                // Kalau data rute sudah ada (hot reload), langsung fit
                if (hasUser && _selected != null && _routePts.isNotEmpty) {
                  _fitToBoundsFor(_userLatLng!, LatLng(_selected!.lat, _selected!.lng), _routePts);
                }
              },
              markers: _markers(),
              polylines: {
                if (_routePts.isNotEmpty)
                  Polyline(
                    polylineId: const PolylineId('route'),
                    width: 6,
                    color: const Color(0xFF1A73E8),
                    points: _routePts,
                  ),
              },
              // gestures default: bisa digeser/zoom
            ),
          ),

          // top address pill (biar mirip mock) — opsional
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: _goToUser,               // <-- ini yang bikin kamera gerak
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.place_rounded, color: PickupLocationScreen.kGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          addr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // bottom sheet mini: card bank + tombol lanjutkan
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selected != null && hasUser)
                    _NearestBankTile(
                      site: _selected!,
                      distanceKm: _distanceKm(
                        _userLatLng!,
                        LatLng(_selected!.lat, _selected!.lng),
                      ),
                      onTap: () {
                        // fokuskan kamera ke bank
                        _map?.animateCamera(CameraUpdate.newCameraPosition(
                          CameraPosition(target: LatLng(_selected!.lat, _selected!.lng), zoom: 16),
                        ));
                      },
                    ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PickupLocationScreen.kGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: (hasUser && _selected != null)
                          ? () {
                        Navigator.pushNamed(
                          context,
                          '/pickup/form',
                          arguments: {
                            'profile': _profile,
                            'bank': _selected!,
                          },
                        );
                      }
                          : null,
                      child: const Text('Lanjutkan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _distanceKm(LatLng a, LatLng b) {
    const r = 6371.0;
    final dLat = _deg2rad(b.latitude - a.latitude);
    final dLng = _deg2rad(b.longitude - a.longitude);
    final la1 = _deg2rad(a.latitude);
    final la2 = _deg2rad(b.latitude);

    final h = math.sin(dLat/2)*math.sin(dLat/2) +
        math.cos(la1)*math.cos(la2)*math.sin(dLng/2)*math.sin(dLng/2);
    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1-h));
    return r * c;
  }

  double _deg2rad(double d) => d * math.pi / 180.0;
}

class _NearestBankTile extends StatelessWidget {
  final BankSite site;
  final double distanceKm;
  final VoidCallback? onTap;

  const _NearestBankTile({
    required this.site,
    required this.distanceKm,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final distStr = '${distanceKm.toStringAsFixed(distanceKm < 1 ? 1 : 1)} Km';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Image.network(
                      site.imageUrl,
                      width: 72, height: 72, fit: BoxFit.cover,
                    ),
                    Positioned(
                      left: 6, bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          distStr,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(site.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      site.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 6),
                    Text(site.hours, style: const TextStyle(color: Colors.black87)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// polyline decoder
List<(double, double)> _decodePolyline(String encoded) {
  final List<(double, double)> coords = [];
  int index = 0, lat = 0, lng = 0;

  while (index < encoded.length) {
    int b, shift = 0, result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1F) << shift;
      shift += 5;
    } while (b >= 0x20);
    final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lat += dlat;

    shift = 0; result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1F) << shift;
      shift += 5;
    } while (b >= 0x20);
    final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lng += dlng;

    coords.add((lat / 1e5, lng / 1e5));
  }
  return coords;
}
