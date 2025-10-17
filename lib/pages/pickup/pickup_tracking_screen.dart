import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;
import 'package:flutter/services.dart' show rootBundle;

import '../../app_config.dart';

class PickupTrackingScreen extends StatefulWidget {
  const PickupTrackingScreen({super.key});

  @override
  State<PickupTrackingScreen> createState() => _PickupTrackingScreenState();
}

// Resize aset ke lebar tertentu (px) → BitmapDescriptor
Future<BitmapDescriptor> _bitmapFromAsset(String path, {int width = 2}) async {
  final data = await rootBundle.load(path);
  final codec = await ui.instantiateImageCodec(
    data.buffer.asUint8List(),
    targetWidth: width,
  );
  final frame = await codec.getNextFrame();
  final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
}


class _PickupTrackingScreenState extends State<PickupTrackingScreen> {
  final _db = FirebaseFirestore.instance;
  GoogleMapController? _map;

  // cache route
  LatLng? _routeFrom, _routeTo;
  List<LatLng> _routePts = [];

  BitmapDescriptor? _userIcon, _bankIcon, _courierIcon;

  String _fmtDate(dynamic ts) {
    DateTime? dt;
    if (ts is Timestamp) dt = ts.toDate();
    if (ts is DateTime) dt = ts;
    dt ??= DateTime.now();
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y • $hh:$mm';
  }

  @override
  void initState() {
    super.initState();
    _loadIcons();
  }

  @override
  void dispose() {
    _map?.dispose();
    super.dispose();
  }

  Future<void> _loadIcons() async {
    _userIcon    = await _bitmapFromAsset('assets/icons/user_pin.png', width: 64);
    _bankIcon    = await _bitmapFromAsset('assets/icons/bank_pin.png', width: 64);
    _courierIcon = await _bitmapFromAsset('assets/icons/courier_pin.png', width: 64);
    setState(() {});
  }

  Future<void> _ensureRoute(LatLng from, LatLng to) async {
    // avoid refetch
    if (_routeFrom == from && _routeTo == to && _routePts.isNotEmpty) return;

    _routeFrom = from;
    _routeTo = to;

    final key = AppConfig.googleMapsKey;
    final url = Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
      'origin': '${from.latitude},${from.longitude}',
      'destination': '${to.latitude},${to.longitude}',
      'mode': 'driving',
      'key': key,
    });

    try {
      final r = await http.get(url);
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      final m = jsonDecode(r.body) as Map<String, dynamic>;
      final routes = (m['routes'] as List?) ?? [];
      if (routes.isEmpty) return;

      final polyStr =
          routes.first['overview_polyline']?['points'] as String? ?? '';
      final decoded = _decodePolyline(polyStr)
          .map((e) => LatLng(e.$1, e.$2))
          .toList(growable: false);

      if (!mounted) return;
      setState(() => _routePts = decoded);

      // fit camera AFTER we have points, and after the frame
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _fitToBounds(decoded);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat rute: $e')),
      );
    }
  }

  Future<void> _fitToBounds(List<LatLng> pts) async {
    if (_map == null || pts.isEmpty) return;
    double minLat = pts.first.latitude, maxLat = pts.first.latitude;
    double minLng = pts.first.longitude, maxLng = pts.first.longitude;
    for (final p in pts) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    await _map!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
  }

  @override
  Widget build(BuildContext context) {
    final orderId =
    (ModalRoute.of(context)?.settings.arguments as Map?)?['orderId'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pelacakan Kurir'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: orderId == null
          ? const Center(child: Text('ID order tidak ditemukan'))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _db.collection('pickup_orders').doc(orderId).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Gagal memuat: ${snap.error}'));
          }
          final m = snap.data?.data();
          if (m == null) return const Center(child: Text('Data tidak ada'));

          final user = LatLng(
            (m['userLat'] as num?)?.toDouble() ?? 0,
            (m['userLng'] as num?)?.toDouble() ?? 0,
          );
          final bank = LatLng(
            (m['bankLat'] as num?)?.toDouble() ?? 0,
            (m['bankLng'] as num?)?.toDouble() ?? 0,
          );
          final clat = (m['courierLat'] as num?)?.toDouble();
          final clng = (m['courierLng'] as num?)?.toDouble();
          final courier =
          (clat != null && clng != null) ? LatLng(clat, clng) : null;

          // Trigger route fetch AFTER build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _ensureRoute(user, bank);
          });

          // Build markers locally (no setState)
          final markers = <Marker>{
            Marker(
              markerId: const MarkerId('user'),
              position: user,
              infoWindow: const InfoWindow(title: 'Lokasi Anda'),
              icon: _userIcon ??
                  BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure),
            ),
            Marker(
              markerId: const MarkerId('bank'),
              position: bank,
              infoWindow: const InfoWindow(title: 'Bank Sampah'),
              icon: _bankIcon ??
                  BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen),
            ),
            if (courier != null)
              Marker(
                markerId: const MarkerId('courier'),
                position: courier,
                infoWindow: const InfoWindow(title: 'Kurir'),
                icon: _courierIcon ??
                    BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueOrange),
              ),
          };

          final polylines = <Polyline>{
            if (_routePts.isNotEmpty)
              Polyline(
                polylineId: const PolylineId('route'),
                width: 5,
                color: Colors.blueAccent,
                points: _routePts,
              )
          };

          // Extract extra fields for the detail sheet
          final createdText = _fmtDate(m['createdAt']);
          final bankName   = m['bankName'] as String? ?? '-';
          final bankAddr   = m['bankAddress'] as String? ?? '-';
          final userAddr   = m['userAddress'] as String? ?? '-';
          final timeslot   = m['timeslot'] as String? ?? '-';
          final status     = (m['status'] as String? ?? 'requested').toLowerCase();
          final totalWeight = (m['totalWeight'] as num?)?.toDouble() ?? 0;
          final totalPoints = (m['totalPoints'] as num?)?.toInt() ?? 0;
          final photoUrl    = m['photoUrl'] as String?;
          final items = (m['items'] as List?)
              ?.whereType<Map>()
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
              .toList(growable: false) ?? const <Map<String, dynamic>>[];

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(target: user, zoom: 14),
                onMapCreated: (c) => _map = c,
                markers: markers,
                polylines: polylines,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                compassEnabled: false,
                mapToolbarEnabled: false,
              ),

              // Detail sheet
              _OrderDetailSheet(
                bankName: bankName,
                bankAddress: bankAddr,
                userAddress: userAddr,
                createdText: createdText,
                timeslot: timeslot,
                status: status,
                totalWeight: totalWeight,
                totalPoints: totalPoints,
                photoUrl: photoUrl,
                items: items,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Minimal polyline decoder → returns list of (lat, lng) tuples.
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

    shift = 0;
    result = 0;
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

class _OrderDetailSheet extends StatelessWidget {
  final String bankName;
  final String bankAddress;
  final String userAddress;
  final String createdText;
  final String timeslot;
  final String status;
  final double totalWeight;
  final int totalPoints;
  final String? photoUrl;
  final List<Map<String, dynamic>> items;

  const _OrderDetailSheet({
    required this.bankName,
    required this.bankAddress,
    required this.userAddress,
    required this.createdText,
    required this.timeslot,
    required this.status,
    required this.totalWeight,
    required this.totalPoints,
    required this.photoUrl,
    required this.items,
  });

  Color get _statusBg {
    final s = status.toLowerCase();
    if (s == 'delivered' || s == 'completed' || s == 'done') return const Color(0xFFE4F2E6);
    return const Color(0xFFFFF1E0);
  }

  Color get _statusFg {
    final s = status.toLowerCase();
    if (s == 'delivered' || s == 'completed' || s == 'done') return Colors.green.shade700;
    return const Color(0xFFB86E00);
  }

  String get _statusLabel {
    switch (status.toLowerCase()) {
      case 'requested':        return 'Diminta';
      case 'driver_assigned':  return 'Kurir Ditugaskan';
      case 'on_the_way':
      case 'on_route':         return 'Dalam Perjalanan';
      case 'arrived':          return 'Tiba';
      case 'weighing':         return 'Penimbangan';
      case 'delivered':
      case 'completed':
      case 'done':             return 'Selesai';
      case 'cancelled':        return 'Dibatalkan';
      default:                 return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Material(
          color: Colors.white,
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // grabber
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (photoUrl != null)
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                opaque: true,
                                pageBuilder: (_, __, ___) => _PhotoViewer(url: photoUrl!),
                                transitionsBuilder: (_, anim, __, child) {
                                  return FadeTransition(opacity: anim, child: child);
                                },
                              ),
                            );
                          },
                          child: Hero(
                            tag: 'order-photo-$photoUrl',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                photoUrl!,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                loadingBuilder: (c, w, p) =>
                                p == null ? w : Container(width: 72, height: 72, alignment: Alignment.center, child: const CircularProgressIndicator(strokeWidth: 2)),
                                errorBuilder: (c, e, s) => Container(
                                  width: 72, height: 72,
                                  color: const Color(0xFFF1F5EF),
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.broken_image_outlined, color: Colors.black26),
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                      Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5EF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.photo_outlined, color: Colors.black26),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(bankName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(bankAddress, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: _statusBg, borderRadius: BorderRadius.circular(999)),
                                  child: Text(_statusLabel, style: TextStyle(color: _statusFg, fontWeight: FontWeight.w600, fontSize: 12)),
                                ),
                                const Spacer(),
                                Text(createdText, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  _kv(Icons.schedule, 'Jadwal', timeslot),
                  const SizedBox(height: 6),
                  _kv(Icons.place_rounded, 'Alamat Anda', userAddress),

                  const Divider(height: 18),

                  Row(
                    children: [
                      Expanded(child: _metric('Perkiraan Berat', '${totalWeight.toStringAsFixed(1)} Kg')),
                      const SizedBox(width: 10),
                      Expanded(child: _metric('Perkiraan Poin', '$totalPoints Pts')),
                    ],
                  ),

                  if (items.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 56,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final it = items[i];
                          final name = it['name']?.toString() ?? '-';
                          final w = (it['weightKg'] as num?)?.toDouble() ?? 0;
                          final pts = (it['points'] as num?)?.toInt() ?? 0;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F9F6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.recycling, size: 18, color: Colors.black54),
                                const SizedBox(width: 8),
                                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(width: 8),
                                Text('${w.toStringAsFixed(1)} Kg • $pts pts', style: const TextStyle(color: Colors.black54)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _kv(IconData icon, String k, String v) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 8),
        Text(k, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            v,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _metric(String k, String v) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
          const SizedBox(height: 6),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _PhotoViewer extends StatelessWidget {
  final String url;
  const _PhotoViewer({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Foto Setoran'),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () {
              // Optional: do something like share/save
            },
          ),
        ],
      ),
      body: Center(
        child: Hero(
          tag: 'order-photo-$url',
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 5,
            child: Image.network(
              url,
              fit: BoxFit.contain,
              loadingBuilder: (c, w, p) =>
              p == null ? w : const SizedBox(width: 48, height: 48, child: CircularProgressIndicator(strokeWidth: 2)),
              errorBuilder: (c, e, s) => const Icon(Icons.broken_image_outlined, size: 64, color: Colors.white38),
            ),
          ),
        ),
      ),
    );
  }
}
