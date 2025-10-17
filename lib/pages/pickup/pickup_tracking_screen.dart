import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../app_config.dart';

class PickupTrackingScreen extends StatefulWidget {
  const PickupTrackingScreen({super.key});

  @override
  State<PickupTrackingScreen> createState() => _PickupTrackingScreenState();
}

class _PickupTrackingScreenState extends State<PickupTrackingScreen> {
  final _db = FirebaseFirestore.instance;
  GoogleMapController? _map;

  // cache route
  LatLng? _routeFrom, _routeTo;
  List<LatLng> _routePts = [];

  BitmapDescriptor? _userIcon, _bankIcon, _courierIcon;

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
    try {
      _userIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/icons/user_pin.png',
      );
    } catch (_) {}
    try {
      _bankIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/icons/bank_pin.png',
      );
    } catch (_) {}
    try {
      _courierIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/icons/courier_pin.png',
      );
    } catch (_) {}
    if (mounted) setState(() {});
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

          return GoogleMap(
            initialCameraPosition: CameraPosition(target: user, zoom: 14),
            onMapCreated: (c) => _map = c,
            markers: markers,
            polylines: polylines,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
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
