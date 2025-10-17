// lib/pages/address_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/services/user_repository.dart';
import 'package:geolocator/geolocator.dart'; // <-- IMPORT BARU
import '../../../app_config.dart';

// ENUM untuk mengelola mode tampilan layar
enum _ScreenMode { view, search }

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});
  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  // THEME
  static const kGreen = Color(0xFF123524);
  static const kText = Color(0xFF0B1215);

  // STATE
  final _searchC = TextEditingController();
  final _repo = UserRepository();
  Timer? _debounce;

  // STATE MANAGEMENT
  bool _loading = false;
  bool _saving = false;
  bool _initing = true;
  _ScreenMode _mode = _ScreenMode.view;

  // Current saved profile location (from Firestore)
  String? _address;
  double? _lat;
  double? _lng;

  // State baru untuk menyimpan alamat PRATINJAU (belum di-save)
  String? _previewAddress;
  double? _previewLat;
  double? _previewLng;

  List<_Prediction> _preds = [];

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchC.dispose();
    super.dispose();
  }

  // ===================== LOGIC =====================
  Future<void> _loadInitial() async {
    try {
      final profile = await _repo.getProfile();
      setState(() {
        _address = profile['address'] as String?;
        _lat = (profile['lat'] as num?)?.toDouble();
        _lng = (profile['lng'] as num?)?.toDouble();
      });
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _initing = false);
    }
  }

  // FUNGSI BARU: Mendeteksi lokasi saat ini
  Future<void> _getCurrentLocation() async {
    setState(() => _saving = true); // Gunakan state _saving untuk loader
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin lokasi ditolak oleh pengguna.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak permanen, silakan aktifkan di pengaturan.');
      }

      final position = await Geolocator.getCurrentPosition();
      final address = await _fetchAddressFromCoords(position.latitude, position.longitude);

      setState(() {
        _previewLat = position.latitude;
        _previewLng = position.longitude;
        _previewAddress = address;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // FUNGSI BARU: Mengubah koordinat menjadi alamat (Reverse Geocoding)
  Future<String> _fetchAddressFromCoords(double lat, double lng) async {
    final key = AppConfig.googleStaticMapsKey; // Bisa pakai key yang sama
    if (key.isEmpty) throw Exception('Google API Key is empty');

    final url = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
      'latlng': '$lat,$lng',
      'key': key,
      'language': 'id',
    });

    final resp = await http.get(url);
    if (resp.statusCode != 200) throw Exception('Geocoding failed: ${resp.statusCode}');

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final results = json['results'] as List?;
    if (results == null || results.isEmpty) throw Exception('Alamat tidak ditemukan');

    return results.first['formatted_address'] as String;
  }

  Future<void> _onQuery(String q) async {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted || q.trim().length < 3) {
        setState(() => _preds = []);
        return;
      }
      await _fetchAutocomplete(q.trim());
    });
  }

  Future<void> _fetchAutocomplete(String input) async {
    setState(() => _loading = true);
    try {
      final key = AppConfig.googlePlacesKey;
      if (key.isEmpty) throw Exception('Google Places Key is empty');

      final url = Uri.https('places.googleapis.com', '/v1/places:autocomplete');
      final body = jsonEncode({
        'input': input,
        'locationBias': {
          "circle": {"center": {"latitude": -2.548926, "longitude": 118.0148634}, "radius": 50000.0}
        },
        'includedRegionCodes': ['id'],
        'languageCode': 'id',
      });
      final headers = {'Content-Type': 'application/json', 'X-Goog-Api-Key': key};
      final resp = await http.post(url, headers: headers, body: body);

      if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode}: ${resp.body}');

      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final suggestions = (json['suggestions'] as List?) ?? [];
      final list =
      suggestions.map<_Prediction>((p) => _Prediction.fromGoogle(p as Map<String, dynamic>)).toList();
      setState(() => _preds = list);
    } catch (e) {
      setState(() => _preds = []);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectPrediction(_Prediction p) async {
    setState(() {
      _loading = true;
      _preds = [];
      _searchC.clear();
    });

    final coords = await _fetchPlaceDetails(p.placeId);
    if (coords == null || !mounted) {
      setState(() => _loading = false);
      return;
    }

    setState(() {
      _previewAddress = p.description;
      _previewLat = coords['lat'];
      _previewLng = coords['lng'];
      _mode = _ScreenMode.view;
      _loading = false;
    });
  }

  Future<Map<String, double>?> _fetchPlaceDetails(String placeId) async {
    try {
      final key = AppConfig.googlePlacesKey;
      if (key.isEmpty) throw Exception('Google Places Key is empty');
      final url = Uri.https('places.googleapis.com', '/v1/places/$placeId');
      final headers = {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': key,
        'X-Goog-FieldMask': 'location',
      };
      final resp = await http.get(url, headers: headers);
      if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode} on place details: ${resp.body}');
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final location = json['location'] as Map<String, dynamic>?;
      if (location == null) throw Exception('Invalid place details response');
      return {'lat': (location['latitude'] as num).toDouble(), 'lng': (location['longitude'] as num).toDouble()};
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mendapatkan detail lokasi: $e')));
      return null;
    }
  }

  Future<void> _confirmAndSaveLocation() async {
    final addressToSave = _previewAddress ?? _address;
    final latToSave = _previewLat ?? _lat;
    final lngToSave = _previewLng ?? _lng;

    if (addressToSave == null || latToSave == null || lngToSave == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih alamat terlebih dahulu')));
      return;
    }

    setState(() => _saving = true);
    try {
      await _repo.upsertProfile(address: addressToSave, lat: latToSave, lng: lngToSave);
      setState(() {
        _address = addressToSave;
        _lat = latToSave;
        _lng = lngToSave;
        _previewAddress = null;
        _previewLat = null;
        _previewLng = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lokasi dikonfirmasi dan disimpan')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan alamat: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ===================== UI BUILDER =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          if (_mode == _ScreenMode.view) _buildViewMode() else _buildSearchMode(),
          if (_initing || _saving)
            Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  Widget _buildViewMode() {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          const Text('Alamatku', style: TextStyle(color: kText, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          // DIUBAH: Mengirim fungsi _getCurrentLocation ke Peta
          _MapStaticPreview(
            lat: _previewLat ?? _lat,
            lng: _previewLng ?? _lng,
            onBadgeTapped: _getCurrentLocation, // <-- KIRIM FUNGSI KE WIDGET
          ),
          const SizedBox(height: 12),
          _BottomAddressCard(
            address: _previewAddress ?? _address,
            onChange: () {
              setState(() {
                _mode = _ScreenMode.search;
                _preds = [];
              });
            },
            onConfirm: _confirmAndSaveLocation,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchMode() {
    final hasPlacesKey = AppConfig.googlePlacesKey.trim().isNotEmpty;
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _mode = _ScreenMode.view),
                ),
                const Text('Cari Alamat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kText)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 20, color: Colors.black45),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchC,
                        autofocus: true,
                        onChanged: hasPlacesKey ? _onQuery : null,
                        decoration: const InputDecoration(
                            border: InputBorder.none, isDense: true, hintText: 'Ketik nama jalan atau lokasi...'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (_loading) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
          Expanded(
            child: ListView.builder(
              itemCount: _preds.length,
              itemBuilder: (context, index) {
                final p = _preds[index];
                return Material(
                  color: Colors.white,
                  child: ListTile(
                    leading: const Icon(Icons.place_outlined, color: kGreen),
                    title: Text(p.mainText, style: const TextStyle(fontWeight: FontWeight.w700, color: kText)),
                    subtitle: Text(p.secondaryText.isEmpty ? p.description : p.secondaryText),
                    onTap: () => _selectPrediction(p),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

// ===================== WIDGETS =====================

class _MapStaticPreview extends StatelessWidget {
  final double? lat;
  final double? lng;
  final VoidCallback? onBadgeTapped; // <-- PROPERTI BARU
  const _MapStaticPreview({required this.lat, required this.lng, this.onBadgeTapped}); // <-- DIUBAH

  @override
  Widget build(BuildContext context) {
    final key = AppConfig.googleStaticMapsKey;
    final hasCoords = lat != null && lng != null;
    final hasKey = key.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Container(
            height: 220,
            color: const Color(0xFFE8EEE6),
            child: hasCoords && hasKey
                ? Image.network(
              _staticUrl(lat!, lng!, key),
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(child: Text('Gagal memuat peta'));
              },
            )
                : Center(
                child: Text(
                  !hasKey ? 'Google Static Map Key\nbelum disetel' : 'Belum ada lokasi tersimpan',
                  textAlign: TextAlign.center,
                )),
          ),
          if (hasCoords)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black12],
                    ),
                  ),
                ),
              ),
            ),
          if (hasCoords)
            Positioned(
              top: 12,
              right: 12,
              child: _MapBadge(onTap: onBadgeTapped), // <-- DIUBAH
            ),
        ],
      ),
    );
  }

  String _staticUrl(double lat, double lng, String key) {
    return 'https://maps.googleapis.com/maps/api/staticmap'
        '?center=$lat,$lng&zoom=16&size=640x220&scale=2'
        '&markers=color:0x123524%7C$lat,$lng&key=$key';
  }
}

class _MapBadge extends StatelessWidget {
  final VoidCallback? onTap; // <-- PROPERTI BARU
  const _MapBadge({this.onTap}); // <-- DIUBAH

  @override
  Widget build(BuildContext context) {
    // DIUBAH: Dibungkus dengan Material dan InkWell agar bisa diklik
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(.12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.my_location, size: 18, color: Color(0xFF123524)),
              SizedBox(width: 6),
              Text('Lokasi Anda', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0B1215))),
            ],
          ),
        ),
      ),
    );
  }
}


// ... Sisa kode widget lainnya (BottomAddressCard, _Prediction, etc) tetap sama
// Anda bisa copy-paste dari kode sebelumnya.

class _BottomAddressCard extends StatelessWidget {
  final String? address;
  final VoidCallback onChange;
  final VoidCallback onConfirm;
  const _BottomAddressCard({required this.address, required this.onChange, required this.onConfirm});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 18, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pilih Lokasi Anda',
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 16, color: _AddressScreenState.kText)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2.0),
                child: Icon(Icons.check_circle, color: Color(0xFF63B56B)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  address ?? 'Belum ada alamat tersimpan',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _AddressScreenState.kText, height: 1.4),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onChange,
                child: const Text('Ubah',
                    style: TextStyle(
                        color: _AddressScreenState.kGreen, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: _AddressScreenState.kGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Konfirmasi Lokasi',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Prediction {
  final String description;
  final String placeId;
  final String mainText;
  final String secondaryText;

  _Prediction({
    required this.description,
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
  });

  factory _Prediction.fromGoogle(Map<String, dynamic> p) {
    final placePrediction = p['placePrediction'] as Map<String, dynamic>? ?? {};
    final structuredFormat = placePrediction['structuredFormat'] as Map<String, dynamic>? ?? {};
    final mainText = structuredFormat['mainText'] as Map<String, dynamic>? ?? {};
    final secondaryText = structuredFormat['secondaryText'] as Map<String, dynamic>? ?? {};

    return _Prediction(
      description: placePrediction['text']?['text'] as String? ?? '',
      placeId: placePrediction['placeId'] as String? ?? '',
      mainText: mainText['text'] as String? ?? '',
      secondaryText: secondaryText['text'] as String? ?? '',
    );
  }
}