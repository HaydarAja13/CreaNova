import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../app_config.dart';
import '../../../models/bank_site.dart';
import 'nearest_finder.dart';

class NearestBankMapScreen extends StatefulWidget {
  final List<BankSite>? sites;   // daftar bank dari backend (opsional)
  final BankSite? selected;      // preselected (opsional)

  const NearestBankMapScreen({super.key, this.sites, this.selected});

  @override
  State<NearestBankMapScreen> createState() => _NearestBankMapScreenState();
}

class _NearestBankMapScreenState extends State<NearestBankMapScreen> {
  GoogleMapController? _map;
  LatLng? _me;
  BankSite? _selected;

  // icons
  BitmapDescriptor? _userIcon, _bankIcon, _bankSelIcon;

  // daftar bank aktif
  late List<BankSite> _sites;

  // directions state & cache
  LatLng? _routeFrom, _routeTo;
  List<LatLng> _routePts = [];
  String? _distanceText, _durationText;
  bool _loadingRoute = false;
  final Map<String, _RouteData> _directionsCache = {}; // key = "${lat},${lng}"

  bool _traffic = false;

  @override
  void initState() {
    super.initState();
    _sites = [...(widget.sites ?? const [])];
    _init();
  }

  @override
  void dispose() {
    _map?.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _loadIcons();

    // permission
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izin lokasi diperlukan untuk menampilkan rute')),
      );
      return;
    }

    // lokasi user
    final p = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
    final me = LatLng(p.latitude, p.longitude);

    // isi dummy kalau list kosong (bisa dihapus jika selalu dari backend)
    if (_sites.isEmpty) {
      _sites = const [
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
    }

    // urutkan berdasarkan jarak
    _sites.sort((a, b) {
      final da = _dist(me, LatLng(a.lat, a.lng));
      final db = _dist(me, LatLng(b.lat, b.lng));
      return da.compareTo(db);
    });

    final initial = widget.selected ?? await findNearest(_sites);

    if (!mounted) return;
    setState(() {
      _me = me;
      _selected = initial;
    });

    // tarik rute awal
    if (initial != null) {
      _fetchRoute(me, LatLng(initial.lat, initial.lng), fit: true);
    }
  }

  // ---------- Icons ----------
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
    _userIcon    = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    _bankIcon    = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    _bankSelIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

    try { _userIcon    = await _bitmapFromAsset('assets/icons/user_pin.png', width: 92); } catch (_) {}
    try { _bankIcon    = await _bitmapFromAsset('assets/icons/bank_pin.png', width: 92); } catch (_) {}
    try { _bankSelIcon = await _bitmapFromAsset('assets/icons/bank_pin_selected.png', width: 92); } catch (_) {}

    if (mounted) setState(() {});
  }

  // ---------- Directions ----------
  String _keyFor(LatLng to) => '${to.latitude.toStringAsFixed(6)},${to.longitude.toStringAsFixed(6)}';

  Future<void> _fetchRoute(LatLng from, LatLng to, {bool fit = false}) async {
    // cache hit?
    final cacheKey = _keyFor(to);
    final cached = _directionsCache[cacheKey];
    if (cached != null) {
      setState(() {
        _routeFrom = from;
        _routeTo = to;
        _routePts = cached.points;
        _distanceText = cached.distanceText;
        _durationText = cached.durationText;
      });
      if (fit) _fitBoundsFor(from, to, _routePts);
      return;
    }

    if (_loadingRoute) return;
    setState(() => _loadingRoute = true);

    try {
      final url = Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
        'origin': '${from.latitude},${from.longitude}',
        'destination': '${to.latitude},${to.longitude}',
        'mode': 'driving',
        'key': AppConfig.googleMapsKey,
      });

      final r = await http.get(url);
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      final m = jsonDecode(r.body) as Map<String, dynamic>;
      final status = m['status'] as String? ?? 'UNKNOWN';
      if (status != 'OK') {
        final err = (m['error_message'] as String?) ?? status;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Rute tidak tersedia: $err')),
          );
        }
        return;
      }

      final routes = (m['routes'] as List?) ?? [];
      if (routes.isEmpty) return;
      final leg = (routes.first['legs'] as List).first as Map<String, dynamic>;
      final distanceText = (leg['distance']?['text'] as String?) ?? '';
      final durationText = (leg['duration']?['text'] as String?) ?? '';
      final polyStr = routes.first['overview_polyline']?['points'] as String? ?? '';

      final points = _decodePolyline(polyStr).map((e) => LatLng(e.$1, e.$2)).toList(growable: false);

      // simpan cache
      _directionsCache[cacheKey] = _RouteData(points, distanceText, durationText);

      if (!mounted) return;
      setState(() {
        _routeFrom = from;
        _routeTo = to;
        _routePts = points;
        _distanceText = distanceText;
        _durationText = durationText;
      });

      if (fit) _fitBoundsFor(from, to, points);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat rute')),
      );
    } finally {
      if (mounted) setState(() => _loadingRoute = false);
    }
  }

  Future<void> _fitBoundsFor(LatLng a, LatLng b, List<LatLng> extras) async {
    if (_map == null) return;
    final pts = <LatLng>[a, b, ...extras];
    double minLat = pts.first.latitude, maxLat = pts.first.latitude;
    double minLng = pts.first.longitude, maxLng = pts.first.longitude;
    for (final p in pts) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    await _map!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)),
        64,
      ),
    );
  }

  // ---------- Markers / Polylines ----------
  Set<Marker> _markers() {
    final me = _me;
    final markers = <Marker>{};

    if (me != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('me'),
          position: me,
          infoWindow: const InfoWindow(title: 'Lokasi Anda'),
          icon: _userIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          onTap: () => _map?.animateCamera(CameraUpdate.newLatLngZoom(me, 16)),
        ),
      );
    }

    for (final s in _sites) {
      final isSel = _selected?.name == s.name;
      final id = 'bank_${s.name}';
      markers.add(
        Marker(
          markerId: MarkerId(id),
          position: LatLng(s.lat, s.lng),
          infoWindow: InfoWindow(title: s.name, snippet: s.address),
          icon: isSel
              ? (_bankSelIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed))
              : (_bankIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)),
          onTap: () => _onSelectBank(s, recenter: true),
        ),
      );
    }
    return markers;
  }

  Set<Polyline> _polylines() {
    if (_routePts.isEmpty) return {};
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        width: 6,
        color: const Color(0xFF1A73E8),
        points: _routePts,
      ),
    };
  }

  void _onSelectBank(BankSite s, {bool recenter = false}) {
    setState(() => _selected = s);
    if (_me != null) {
      _fetchRoute(_me!, LatLng(s.lat, s.lng), fit: true);
    }
    if (recenter) {
      _map?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(s.lat, s.lng), zoom: 16),
        ),
      );
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final me = _me ?? const LatLng(-6.966667, 110.416664); // fallback Semarang
    final selected = _selected;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: me, zoom: _me != null ? 14 : 12),
              onMapCreated: (c) => _map = c,
              markers: _markers(),
              polylines: _polylines(),
              trafficEnabled: _traffic,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
            ),
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 1,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Setor Langsung',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black)),
                  const Spacer(),
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 1,
                    child: IconButton(
                      icon: Icon(_traffic ? Icons.traffic : Icons.traffic_outlined),
                      onPressed: () => setState(() => _traffic = !_traffic),
                      tooltip: 'Toggle traffic',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // My location button
          Positioned(
            right: 12,
            top: 70,
            child: SafeArea(
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 2,
                child: IconButton(
                  icon: const Icon(Icons.my_location),
                  onPressed: () {
                    final m = _me;
                    if (m != null) {
                      _map?.animateCamera(CameraUpdate.newLatLngZoom(m, 16));
                    }
                  },
                ),
              ),
            ),
          ),

          // Bottom: carousel + action
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              minimum: const EdgeInsets.fromLTRB(0, 0, 0, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // info bar jarak/ETA (jika ada)
                  if (_distanceText != null || _durationText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.07), blurRadius: 12, offset: const Offset(0, 6))],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.directions_car, color: Color(0xFF123524)),
                          const SizedBox(width: 8),
                          if (_distanceText != null)
                            Text(_distanceText!, style: const TextStyle(fontWeight: FontWeight.w700)),
                          if (_distanceText != null && _durationText != null)
                            const SizedBox(width: 8),
                          if (_durationText != null)
                            Text('• $_durationText', style: const TextStyle(color: Colors.black87)),
                          const Spacer(),
                          if (_loadingRoute) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                        ],
                      ),
                    ),

                  // horizontal list bank
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      scrollDirection: Axis.horizontal,
                      itemCount: _sites.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final s = _sites[i];
                        final isSel = selected?.name == s.name;
                        return _BankCardMini(
                          site: s,
                          me: _me,
                          selected: isSel,
                          onTap: () => _onSelectBank(s, recenter: true),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // actions: buka maps
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                side: const BorderSide(color: Color(0xFF123524)),
                                foregroundColor: const Color(0xFF123524),
                              ),
                              icon: const Icon(Icons.map_outlined),
                              label: const Text('Buka di Google Maps'),
                              onPressed: selected == null ? null : () => _openExternalMaps(selected),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF123524),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: selected == null ? null : () => Navigator.pop(context, selected),
                              child: const Text('Pilih bank ini', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                      ],
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

  // ---------- utils ----------
  Future<void> _openExternalMaps(BankSite s) async {
    final dest = '${s.lat},${s.lng}';
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$dest&travelmode=driving');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak bisa membuka Google Maps')));
    }
  }

  double _dist(LatLng a, LatLng b) {
    const r = 6371.0;
    final dLat = _deg(b.latitude - a.latitude);
    final dLng = _deg(b.longitude - a.longitude);
    final la1 = _deg(a.latitude);
    final la2 = _deg(b.latitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(la1) * math.cos(la2) * math.sin(dLng / 2) * math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return r * c;
  }

  double _deg(double d) => d * math.pi / 180.0;
}

// mini card bank
class _BankCardMini extends StatelessWidget {
  final BankSite site;
  final LatLng? me;
  final bool selected;
  final VoidCallback? onTap;

  const _BankCardMini({
    required this.site,
    required this.me,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final distKm = (me == null) ? null : _distanceKm(me!, LatLng(site.lat, site.lng));

    return Material(
      color: Colors.white,
      elevation: selected ? 3 : 1,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(site.imageUrl, width: 86, height: 86, fit: BoxFit.cover),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(site.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(site.address, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black54, fontSize: 12.5)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(site.hours, style: const TextStyle(fontSize: 12.5)),
                        const Spacer(),
                        if (distKm != null)
                          Text('${distKm.toStringAsFixed(distKm < 1 ? 1 : 1)} Km',
                              style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _distanceKm(LatLng a, LatLng b) {
    const r = 6371.0;
    final dLat = _deg(b.latitude - a.latitude);
    final dLng = _deg(b.longitude - a.longitude);
    final la1 = _deg(a.latitude);
    final la2 = _deg(b.latitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(la1) * math.cos(la2) * math.sin(dLng / 2) * math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return r * c;
  }

  double _deg(double d) => d * math.pi / 180.0;
}

// polyline decoder
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

class _RouteData {
  final List<LatLng> points;
  final String distanceText;
  final String durationText;
  const _RouteData(this.points, this.distanceText, this.durationText);
}
