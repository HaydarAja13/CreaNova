import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/services/user_repository.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/app_config.dart';
import 'package:image_picker/image_picker.dart'; // <-- IMPORT BARU
import 'package:path/path.dart' as p;             // <-- IMPORT BARU

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  static const kGreen = Color(0xFF123524);
  static const kText = Color(0xFF0B1215);

  final _nameC = TextEditingController();
  final _addrC = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _repo = UserRepository(); // <-- DIJADIKAN VARIABEL KELAS
  bool _saving = false;

  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    final u = FirebaseAuth.instance.currentUser;
    _nameC.text = (u?.displayName ?? '').trim();
  }

  @override
  void dispose() {
    _nameC.dispose();
    _addrC.dispose();
    super.dispose();
  }

  // FUNGSI BARU: Logika untuk memilih dan mengunggah foto
  Future<void> _pickAndUploadPhoto() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x == null) return;

    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Konfigurasi Cloudinary (sesuaikan jika perlu)
      const cloudName = 'dbad7of94';
      const uploadPreset = 'tukarin-project';

      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final req = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] = 'users/$uid'
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          x.path,
          filename: 'avatar${p.extension(x.path)}',
        ));

      final res = await req.send();
      final body = await res.stream.bytesToString();
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception('Upload failed: ${res.statusCode} $body');
      }

      final secureUrl = (jsonDecode(body) as Map)['secure_url'] as String;

      // Update URL foto di Firebase Auth dan Firestore
      await FirebaseAuth.instance.currentUser!.updatePhotoURL(secureUrl);
      await _repo.upsertProfile(photoURL: secureUrl);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto profil diperbarui')),
      );
      // Refresh UI untuk menampilkan avatar baru
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal upload: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    setState(() => _saving = true);
    try {
      final name = _nameC.text.trim();
      final address = _addrC.text.trim();

      final u = FirebaseAuth.instance.currentUser;
      if (u != null && name.isNotEmpty) {
        await u.updateDisplayName(name);
      }

      await _repo.ensureDefaults();
      await _repo.upsertProfile(displayName: name, address: address, lat: _lat, lng: _lng);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil disimpan')),
      );
      Navigator.of(context).pushReplacementNamed('/shell');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openAddressSearch() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (context) => const _AddressSearchPage()),
    );
    if (result != null && mounted) {
      setState(() {
        _addrC.text = result['address'] as String;
        _lat = result['lat'] as double?;
        _lng = result['lng'] as double?;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final kHintBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE6E6E6)),
    );
    final media = MediaQuery.of(context);
    // VARIABEL BARU: Untuk mengakses data user dengan mudah
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
              physics: const BouncingScrollPhysics(),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      'assets/icons/lamp.png',
                      width: 79,
                      height: 79,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                      const Icon(Icons.emoji_objects_outlined, size: 64, color: kGreen),
                    ),
                    const SizedBox(width: 32),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Lanjutkan\nPendaftaran',
                              style: TextStyle(
                                  color: kText, fontSize: 24, fontWeight: FontWeight.w800, height: 1.15)),
                          SizedBox(height: 6),
                          Text('Lengkapi data dirimu sekarang !', style: TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 50),
                // WIDGET BARU: Avatar dengan tombol edit
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundColor: const Color(0xFFEFF4ED),
                        backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                        child: user?.photoURL == null
                            ? const Icon(Icons.person, color: kGreen, size: 52)
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          elevation: 2,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _pickAndUploadPhoto,
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(Icons.edit, color: kGreen, size: 20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Nama', style: TextStyle(color: kText, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameC,
                        maxLength: 100,
                        decoration: InputDecoration(
                          hintText: 'Nama Lengkap',
                          counterText: '${_nameC.text.length}/100',
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: kHintBorder,
                          focusedBorder: kHintBorder,
                          border: kHintBorder,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          if ((v ?? '').trim().isEmpty) return 'Nama tidak boleh kosong';
                          if ((v ?? '').trim().length < 3) return 'Min. 3 karakter';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('Alamat', style: TextStyle(color: kText, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _addrC,
                        readOnly: true,
                        onTap: _openAddressSearch,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Cari dan pilih alamatmu',
                          suffixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: kHintBorder,
                          focusedBorder: kHintBorder,
                          border: kHintBorder,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        validator: (v) {
                          if ((v ?? '').trim().isEmpty) return 'Alamat tidak boleh kosong';
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kGreen,
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Konfirmasi',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      SizedBox(height: media.viewPadding.bottom > 0 ? 40 : 160),
                      const Center(
                        child: Text('2025 © TukarIn',
                            style: TextStyle(color: Colors.black54, fontSize: 12.5)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_saving)
              Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator())),
          ],
        ),
      ),
    );
  }
}


// ... Kode _AddressSearchPage dan _Prediction tetap sama persis, tidak perlu diubah ...
// Anda bisa copy-paste bagian ini dari kode sebelumnya

// ======================================================================
// WIDGET BARU: Halaman Pencarian Alamat (diletakkan di file yang sama)
// ======================================================================

class _AddressSearchPage extends StatefulWidget {
  const _AddressSearchPage();

  @override
  State<_AddressSearchPage> createState() => _AddressSearchPageState();
}

class _AddressSearchPageState extends State<_AddressSearchPage> {
  final _searchC = TextEditingController();
  Timer? _debounce;
  bool _loading = false;
  List<_Prediction> _preds = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchC.dispose();
    super.dispose();
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
        'includedRegionCodes': ['id'], 'languageCode': 'id',
      });
      final headers = {'Content-Type': 'application/json', 'X-Goog-Api-Key': key};
      final resp = await http.post(url, headers: headers, body: body);

      if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode}: ${resp.body}');

      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final suggestions = (json['suggestions'] as List?) ?? [];
      final list = suggestions
          .map<_Prediction>((p) => _Prediction.fromGoogle(p as Map<String, dynamic>))
          .toList();
      setState(() => _preds = list);
    } catch (e) {
      setState(() => _preds = []);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectPrediction(_Prediction p) async {
    setState(() => _loading = true);
    final coords = await _fetchPlaceDetails(p.placeId);
    if (coords == null || !mounted) {
      setState(() => _loading = false);
      return;
    }

    final result = {
      'address': p.description,
      'lat': coords['lat'],
      'lng': coords['lng'],
    };

    Navigator.of(context).pop(result);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cari Alamat')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchC,
              autofocus: true,
              onChanged: _onQuery,
              decoration: const InputDecoration(
                hintText: 'Ketik nama jalan atau lokasi...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
            ),
          ),
          if (_loading) const Center(child: CircularProgressIndicator()),
          Expanded(
            child: ListView.builder(
              itemCount: _preds.length,
              itemBuilder: (context, index) {
                final p = _preds[index];
                return ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: Text(p.mainText, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(p.secondaryText),
                  onTap: () => _selectPrediction(p),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Prediction {
  final String description, placeId, mainText, secondaryText;
  _Prediction({required this.description, required this.placeId, required this.mainText, required this.secondaryText});

  factory _Prediction.fromGoogle(Map<String, dynamic> p) {
    final pred = p['placePrediction'] as Map<String, dynamic>? ?? {};
    final structured = pred['structuredFormat'] as Map<String, dynamic>? ?? {};
    return _Prediction(
      description: pred['text']?['text'] as String? ?? '',
      placeId: pred['placeId'] as String? ?? '',
      mainText: structured['mainText']?['text'] as String? ?? '',
      secondaryText: structured['secondaryText']?['text'] as String? ?? '',
    );
  }
}