import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http; // <-- IMPORT BARU
import 'package:path/path.dart' as p;     // <-- IMPORT BARU

import '../../models/pickup_order.dart';
import '../../models/bank_site.dart';

class PickupFormScreen extends StatefulWidget {
  const PickupFormScreen({super.key});

  static const kGreen = Color(0xFF123524);
  static const kText  = Color(0xFF0B1215);

  @override
  State<PickupFormScreen> createState() => _PickupFormScreenState();
}

// Pricing cache: type -> {coefPoints, minKg, maxKg}
Map<String, Map<String, num>> _pricing = {};
bool _pricingLoaded = false;
final List<String> _defaultTypes = const ['Botol Plastik', 'Kardus', 'Kertas'];

class _PickupFormScreenState extends State<PickupFormScreen> {
  final _db = FirebaseFirestore.instance;
  final _nameC = TextEditingController();
  String _timeslot = 'Jumat 8 Agustus 09.00 - 10.00';
  static const int kMaxOrdersPerSlot = 8; // ubah sesuai kebijakan

  final List<WasteItem> _items = [];
  File? _photo;
  bool _saving = false;
  List<String> _slots = [];

  String _slotKeyFromTimeslot(BankSite bank, String timeslot) {
    // contoh timeslot: "Jum, 18 Okt 09:00 - 10:00"
    // jadi kunci: 2025-10-18_09:00__Bank_Omah_Resik
    final re = RegExp(r'(\d{1,2})\s+([A-Za-zA-Z]+)\s+(\d{4}).*?(\d{2}:\d{2})');
    // Kalau format timeslot kamu beda, kamu bisa langsung pakai replaceAll:
    final safeBank = bank.name.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    final safeSlot = timeslot.replaceAll(RegExp(r'[^0-9A-Za-z:_-]+'), '_');
    return '${safeSlot}__$safeBank';
  }

  @override
  void initState() {
    super.initState();

    // Mengambil data awal dari argumen rute saat widget pertama kali dibuat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)!.settings.arguments as Map?;
      final profile = (args?['profile'] as Map<String, dynamic>?) ?? {};
      if (mounted) {
        setState(() {
          _nameC.text = (profile['displayName'] as String?) ?? '';
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final args = ModalRoute.of(context)!.settings.arguments as Map?;
      final bank = args?['bank'] as BankSite?;
      if (bank != null) {
        _slots = await _generateSlots(bank.hours);
        _timeslot = _slots.isNotEmpty ? _slots.first : _timeslot;
        if (mounted) setState(() {});
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final args = ModalRoute.of(context)!.settings.arguments as Map?;
      final profile = (args?['profile'] as Map<String, dynamic>?) ?? {};
      if (mounted) {
        setState(() {
          _nameC.text = (profile['displayName'] as String?) ?? '';
        });
      }
      // Generate slots seperti langkah sebelumnya (jika sudah ditambahkan)
      final bank = args?['bank'] as BankSite?;
      if (bank != null) {
        // ... generate slots di sini kalau kamu sudah implement
      }
      // >>> Load pricing
      await _loadPricing();
    });
  }

  Future<void> _loadPricing() async {
    try {
      final snap = await _db.collection('waste_pricings').get();
      final map = <String, Map<String, num>>{};
      for (final d in snap.docs) {
        final m = d.data();
        map[d.id] = {
          'coefPoints': (m['coefPoints'] as num?) ?? 50, // default 50 pts/kg
          'minKg': (m['minKg'] as num?) ?? 0,
          'maxKg': (m['maxKg'] as num?) ?? 999,
        };
      }
      if (mounted) {
        setState(() {
          _pricing = map;
          _pricingLoaded = true;
        });
      }
    } catch (_) {
      // tetap pakai fallback tanpa crash
      if (mounted) setState(() => _pricingLoaded = true);
    }
  }

  int _calcPoints(String type, double kg) {
    final rule = _pricing[type];
    final coef = (rule?['coefPoints'] ?? 50).toDouble();
    final minKg = (rule?['minKg'] ?? 0).toDouble();
    final maxKg = (rule?['maxKg'] ?? 999).toDouble();
    final clamped = kg.clamp(minKg, maxKg);
    return (clamped * coef).round();
  }

  @override
  void dispose() { _nameC.dispose(); super.dispose(); }

  Future<void> _pickPhoto() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x != null) setState(() => _photo = File(x.path));
  }

  void _addItem() async {
    // jenis = key dari pricing; fallback ke default types jika pricing kosong
    final types = _pricing.isNotEmpty ? _pricing.keys.toList() : _defaultTypes;

    final res = await showDialog<WasteItem>(
      context: context,
      builder: (_) => _AddWasteItemDialog(
        types: types,
        calcPoints: _calcPoints,
      ),
    );
    if (res != null) {
      setState(() => _items.add(res));
    }
  }

  int get totalPoints => _items.fold(0, (a, b) => a + b.points);
  double get totalWeight => _items.fold(0.0, (a, b) => a + b.weightKg);

  // ——— Distance & time helpers ———

  double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    double deg2rad(double d) => d * math.pi / 180.0;
    const r = 6371.0; // km
    final dLat = deg2rad(lat2 - lat1);
    final dLng = deg2rad(lng2 - lng1);
    final aLat = deg2rad(lat1);
    final bLat = deg2rad(lat2);

    final h = math.sin(dLat/2) * math.sin(dLat/2) +
        math.cos(aLat) * math.cos(bLat) * math.sin(dLng/2) * math.sin(dLng/2);
    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return r * c;
  }

  bool _isWithinRadiusKm(double userLat, double userLng, double bankLat, double bankLng, {double maxKm = 10}) {
    final dist = _haversineKm(userLat, userLng, bankLat, bankLng);
    return dist <= maxKm;
  }

  /// Parse "HH.mm - HH.mm" atau "HH:MM - HH:MM" → (startMin, endMin)
  ({int start, int end}) _parseHourRange(String s) {
    final re = RegExp(r'(\d{1,2})[:\.](\d{2})\s*-\s*(\d{1,2})[:\.](\d{2})');
    final m = re.firstMatch(s);
    if (m == null) return (start: 0, end: 24 * 60);
    int toMin(String hh, String mm) => (int.parse(hh) * 60) + int.parse(mm);
    return (start: toMin(m.group(1)!, m.group(2)!), end: toMin(m.group(3)!, m.group(4)!));
  }

  /// Ambil jam dari _timeslot (format apapun yang mengandung "HH:MM - HH:MM" atau "HH.MM - HH.MM")
  ({int start, int end}) _extractTimesFromTimeslot(String slot) {
    // cari pola jam “09:00 - 10:00” atau “09.00 - 10.00”
    return _parseHourRange(slot);
  }

  /// Cek apakah jam slot berada dalam openHours bank (contoh "08.00 - 17.00")
  bool _isSlotInsideOpenHours(String slot, String openHours) {
    final s1 = _extractTimesFromTimeslot(slot);
    final s2 = _parseHourRange(openHours);
    // syarat minimal: slot start di >= open start, dan slot end <= open end
    return s1.start >= s2.start && s1.end <= s2.end;
  }

// ——— Precheck utama sebelum _submit ———
  Future<bool> _precheck(Map<String, dynamic> profile, BankSite bank) async {
    final lat = (profile['lat'] as num?)?.toDouble();
    final lng = (profile['lng'] as num?)?.toDouble();

    if (lat == null || lng == null) {
      _toast('Alamat belum diatur.');
      return false;
    }

    if (totalWeight < 0.5) {
      _toast('Minimal berat total 0.5 Kg.');
      return false;
    }

    if (!_isWithinRadiusKm(lat, lng, bank.lat, bank.lng, maxKm: 10)) {
      _toast('Lokasi di luar jangkauan layanan (maks 10 Km).');
      return false;
    }

    if (!_isSlotInsideOpenHours(_timeslot, bank.hours)) {
      _toast('Slot di luar jam operasional bank (${bank.hours}).');
      return false;
    }

    final slotKey = _timeslot.replaceAll(' ', '_');
    if (!await _isSlotAvailable(slotKey)) {
      _toast('Slot "$_timeslot" sudah penuh. Silakan pilih jam lain.');
      return false;
    }

    return true;
  }

  void _toast(String s) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  Future<void> _submit(Map<String, dynamic> profile, BankSite bank) async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan minimal 1 jenis sampah')),
      );
      return;
    }

    setState(() => _saving = true);
    String? photoUrl;

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // 1) Upload foto dulu (supaya transaksi cepat & atomic untuk Firestore saja)
      if (_photo != null) {
        // kamu masih pakai flow lama (unsigned) — aman untuk dev.
        // kalau sudah siap server signing, ganti dengan helper signed.
        final uri = Uri.parse('https://api.cloudinary.com/v1_1/dbad7of94/image/upload');
        final req = http.MultipartRequest('POST', uri)
          ..fields['upload_preset'] = 'tukarin-project'
          ..fields['folder'] = 'pickups/$uid'
          ..files.add(await http.MultipartFile.fromPath(
            'file',
            _photo!.path,
            filename: 'pickup_${DateTime.now().millisecondsSinceEpoch}${p.extension(_photo!.path)}',
          ));
        final res = await req.send();
        final body = await res.stream.bytesToString();
        if (res.statusCode != 200 && res.statusCode != 201) {
          throw Exception('Upload foto gagal: ${res.statusCode} $body');
        }
        photoUrl = (jsonDecode(body) as Map)['secure_url'] as String?;
      }

      // 2) Transaction: cek kapasitas slot + increment + create order
      final slotKey = _slotKeyFromTimeslot(bank, _timeslot);
      final slotRef = _db.collection('pickup_slots').doc(slotKey);

      String? orderId; // untuk dipakai navigasi setelah commit

      await _db.runTransaction((tx) async {
        // read slot
        final snap = await tx.get(slotRef);
        final current = (snap.data()?['count'] as int?) ?? 0;
        if (current >= kMaxOrdersPerSlot) {
          throw Exception('Slot "$_timeslot" sudah penuh.');
        }

        // siapkan order map (gunakan serverTimestamp di server-side field)
        final orderRef = _db.collection('pickup_orders').doc();
        orderId = orderRef.id;

        final orderMap = {
          'id': orderRef.id,
          'userId': uid,
          'userName': _nameC.text.trim(),
          'userAddress': profile['address'],
          'userLat': profile['lat'],
          'userLng': profile['lng'],

          'bankName': bank.name,
          'bankAddress': bank.address,
          'bankLat': bank.lat,
          'bankLng': bank.lng,

          'photoUrl': photoUrl,
          'timeslot': _timeslot,
          'items': _items.map((e) => e.toMap()).toList(),
          'totalWeight': totalWeight,
          'totalPoints': totalPoints,

          'status': 'requested',
          'createdAt': FieldValue.serverTimestamp(), // penting: konsisten server
          // snapshoot pricing (opsional, supaya historis tak berubah jika pricing update)
          // 'pricingSnapshot': _pricing,
        };

        // write: increment slot + create order
        tx.set(slotRef, {'count': FieldValue.increment(1)}, SetOptions(merge: true));
        tx.set(orderRef, orderMap);
      });

      if (!mounted) return;
      // 3) Navigasi ke tracking
      Navigator.pushReplacementNamed(context, '/pickup/track', arguments: {'orderId': orderId});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<List<String>> _generateSlots(String openHours, {int days = 7}) async {
    // parse jam seperti "08.00 - 17.00"
    TimeOfDay _parse(String s) {
      final p = s.replaceAll('.', ':').split(':');
      return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
    }

    final parts = openHours.split('-').map((e) => e.trim()).toList();
    final start = _parse(parts[0]);
    final end = _parse(parts[1]);

    final now = DateTime.now();
    List<String> slots = [];

    for (int i = 0; i < days; i++) {
      final day = now.add(Duration(days: i));
      DateTime cur = DateTime(day.year, day.month, day.day, start.hour);
      final endDt = DateTime(day.year, day.month, day.day, end.hour);

      while (cur.isBefore(endDt)) {
        final next = cur.add(const Duration(hours: 1));
        if (next.isAfter(endDt)) break;
        final label =
            "${_hari(day.weekday)}, ${day.day} ${_bulan(day.month)} ${_fmt(cur)} - ${_fmt(next)}";
        slots.add(label);
        cur = next;
      }
    }
    return slots;
  }

  String _fmt(DateTime t) =>
      "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
  String _hari(int w) => ["Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Min"][w - 1];
  String _bulan(int m) =>
      ["Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Agu", "Sep", "Okt", "Nov", "Des"][m - 1];

  Future<bool> _isSlotAvailable(String slotKey, {int maxOrders = 8}) async {
    final snap = await _db.collection('pickup_slots').doc(slotKey).get();
    final count = (snap.data()?['count'] as int?) ?? 0;
    return count < maxOrders;
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    final profile = (args?['profile'] as Map<String, dynamic>?) ?? {};
    final bank = args?['bank'] as BankSite?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Isi Data Penjemputan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: PickupFormScreen.kText,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            children: [
              _buildSectionHeader('Foto Sampah'),
              _buildPhotoPicker(),
              const SizedBox(height: 24),

              _buildSectionHeader('Info Penjemputan'),
              _buildFormFields(),
              const SizedBox(height: 24),

              _buildSectionHeader('Jenis Sampah'),
              _buildWasteList(),
              const SizedBox(height: 12),

              _buildAddItemButton(),
              const SizedBox(height: 24),

              _buildSummary(),
              const SizedBox(height: 24),

              _buildSubmitButton(profile, bank),
            ],
          ),
          if (_saving)
            Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  // ==== WIDGET BUILDER METHODS ====

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildPhotoPicker() {
    return GestureDetector(
      onTap: _pickPhoto,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9F6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
          image: _photo != null
              ? DecorationImage(image: FileImage(_photo!), fit: BoxFit.cover)
              : null,
        ),
        child: _photo == null
            ? const Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: Colors.grey, size: 32),
            SizedBox(height: 8),
            Text('Tambahkan Gambar', style: TextStyle(color: Colors.grey)),
          ],
        ))
            : null,
      ),
    );
  }

  Widget _buildFormFields() {
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nama', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(controller: _nameC, enabled: false,                 // <-- view-only
            showCursor: false, decoration: inputDecoration),
        const SizedBox(height: 16),
        const Text('Waktu Penjemputan', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _timeslot.isNotEmpty ? _timeslot : null,
          decoration: inputDecoration,
          hint: const Text('Pilih waktu penjemputan'),
          items: _slots.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) => setState(() => _timeslot = v ?? ''),
        )
      ],
    );
  }

  Widget _buildWasteList() {
    if (_items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text('Belum ada sampah yang ditambahkan.', style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _WasteListItem(
          item: _items[index],
          onDelete: () => setState(() => _items.removeAt(index)),
        );
      },
    );
  }

  Widget _buildAddItemButton() {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _addItem,
        icon: const Icon(Icons.add),
        label: const Text('Tambahkan Jenis Sampah'),
        style: OutlinedButton.styleFrom(
          foregroundColor: PickupFormScreen.kGreen,
          side: const BorderSide(color: PickupFormScreen.kGreen),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Perkiraan Berat', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('${totalWeight.toStringAsFixed(1)} Kg', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Perkiraan Poin', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('$totalPoints Pts', style: const TextStyle(fontWeight: FontWeight.bold, color: PickupFormScreen.kGreen)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(Map<String, dynamic> profile, BankSite? bank) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (bank == null || _saving)
            ? null
            : () async {
          // VALIDASI DAHULU
          final ok = await _precheck(profile, bank);
          if (!ok) return;
          await _submit(profile, bank);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: PickupFormScreen.kGreen,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _saving
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Ajukan Penjemputan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ==== DIALOG & HELPER WIDGETS ====

class _AddWasteItemDialog extends StatefulWidget {
  final List<String> types;
  final int Function(String type, double kg) calcPoints;
  const _AddWasteItemDialog({required this.types, required this.calcPoints});

  @override
  State<_AddWasteItemDialog> createState() => _AddWasteItemDialogState();
}

class _AddWasteItemDialogState extends State<_AddWasteItemDialog> {
  final _weightC = TextEditingController(text: '1.0');
  late String _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.types.isNotEmpty ? widget.types.first : 'Lainnya';
  }

  @override
  void dispose() {
    _weightC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final types = widget.types.isNotEmpty ? widget.types : ['Lainnya'];
    final weight = double.tryParse(_weightC.text) ?? 0.0;
    final previewPts = weight > 0 ? widget.calcPoints(_selectedType, weight) : 0;

    return AlertDialog(
      title: const Text('Tambah Jenis Sampah'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedType,
            items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _selectedType = v ?? _selectedType),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _weightC,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Perkiraan berat (kg)', border: OutlineInputBorder()),
            onChanged: (_) => setState(() {}), // refresh preview pts
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Perkiraan poin: $previewPts Pts',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () {
            final w = double.tryParse(_weightC.text) ?? 0;
            if (w <= 0) return;
            final pts = widget.calcPoints(_selectedType, w);
            final newItem = WasteItem(name: _selectedType, weightKg: w, points: pts);
            Navigator.pop(context, newItem);
          },
          child: const Text('Tambah'),
        ),
      ],
    );
  }
}

class _WasteListItem extends StatelessWidget {
  final WasteItem item;
  final VoidCallback onDelete;
  const _WasteListItem({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            Container(width: 56, height: 56, decoration: BoxDecoration(color: const Color(0xFFF1F5EF), borderRadius: BorderRadius.circular(12))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text('Perkiraan: ${item.weightKg.toStringAsFixed(1)} Kg', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                  Text('Poin: ${item.points} Pts', style: const TextStyle(color: PickupFormScreen.kGreen, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(
                    'Poin: ${item.points} Pts',
                    style: const TextStyle(color: PickupFormScreen.kGreen, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, color: Colors.red)),
          ],
        ),
      ),
    );
  }
}