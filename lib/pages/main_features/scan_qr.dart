// qr_scan.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
// ⬇️ NEW
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScanQrPage extends StatefulWidget {
  final void Function(String code)? onScanned;
  const ScanQrPage({super.key, this.onScanned});

  @override
  State<ScanQrPage> createState() => _ScanQrPageState();
}

class _QrData {
  final String? nameWeb;
  final String? saldo;
  const _QrData({this.nameWeb, this.saldo});
}

_QrData _parseQrPayload(String raw) {
  // 1) Coba sebagai URL
  final asUri = Uri.tryParse(raw);
  if (asUri != null && (asUri.hasScheme || raw.startsWith('www.'))) {
    final q = asUri.queryParameters;
    final nw = q['name_web'];
    final sd = q['saldo'];
    if ((nw != null && nw.isNotEmpty) || (sd != null && sd.isNotEmpty)) {
      return _QrData(nameWeb: nw, saldo: sd);
    }
  }

  // 2) Coba sebagai JSON
  try {
    final Map<String, dynamic> m = jsonDecode(raw);
    final nw = (m['name_web'] ?? m['nameWeb'])?.toString();
    final sd = m['saldo']?.toString();
    if ((nw != null && nw.isNotEmpty) || (sd != null && sd.isNotEmpty)) {
      return _QrData(nameWeb: nw, saldo: sd);
    }
  } catch (_) {}

  // 3) Key=Value (k=v&k=v / k=v;k=v / k=v,k=v)
  final sep = raw.contains('&')
      ? '&'
      : raw.contains(';')
      ? ';'
      : raw.contains(',')
      ? ','
      : null;
  if (sep != null) {
    final map = <String, String>{};
    for (final part in raw.split(sep)) {
      final eq = part.indexOf('=');
      if (eq > 0) {
        final k = part.substring(0, eq).trim();
        final v = part.substring(eq + 1).trim();
        map[k] = v;
      }
    }
    final nw = map['name_web'] ?? map['nameWeb'];
    final sd = map['saldo'];
    if ((nw != null && nw.isNotEmpty) || (sd != null && sd.isNotEmpty)) {
      return _QrData(nameWeb: nw, saldo: sd);
    }
  }

  return const _QrData();
}

class _ScanQrPageState extends State<ScanQrPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _isHandlingResult = false;
  bool _torch = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ⬇️ NEW: ambil displayName dari Firestore (users/<uid>), fallback ke FirebaseAuth.displayName
  Future<String> _getDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return '';
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final name = (doc.data()?['displayName'] as String?)?.trim();
      if (name != null && name.isNotEmpty) return name;
    } catch (_) {}
    return (user.displayName ?? '').trim();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isHandlingResult) return;

    final barcode = capture.barcodes.firstOrNull;
    final value = barcode?.rawValue;
    if (value == null || value.isEmpty) return;

    setState(() => _isHandlingResult = true);
    await _controller.stop();
    if (!mounted) return;

    try {
      // Ambil displayName dari Firestore / Auth seperti sebelumnya
      final nameApp = await _getDisplayName();
      final nm = (nameApp.isEmpty) ? 'Pengguna' : nameApp;

      // === pake parser QR ===
      final parsed = _parseQrPayload(value);
      final nameWeb = (parsed.nameWeb == null || parsed.nameWeb!.isEmpty)
          ? 'haydar' // fallback kalau QR tak bawa name_web
          : parsed.nameWeb!;
      // Sanitasi saldo: hanya digit
      final saldo = (parsed.saldo ?? '').replaceAll(RegExp(r'[^0-9]'), '');
      if (saldo.isEmpty) {
        // fallback kalau QR tak bawa saldo
        // (optional: kamu bisa kasih error)
        // throw Exception('Saldo tidak ditemukan di QR');
      }

      final uri = Uri.https(
        'well-pelican-real.ngrok-free.app',
        '/api/v1/transaction/update-balance',
        {
          'name_web': nameWeb,
          'saldo': saldo.isEmpty ? '0' : saldo,
          'name_app': nm,
        },
      );

      // Panggil API
      // ignore: use_build_context_synchronously
      final res = await http.get(uri);
      if (!mounted) return;

      if (res.statusCode >= 200 && res.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saldo berhasil diperbarui')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal update saldo: ${res.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      // Tutup halaman TANPA mengirim balik link QR (biar tidak muncul lagi di layar sebelumnya)
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double windowSize = 240.0;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pindai Kode QR',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          SizedBox.expand(
            child: CustomPaint(
              painter: _ScannerOverlayPainter(
                holeSize: const Size.square(windowSize),
              ),
            ),
          ),
          _buildControls(context),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return Positioned(
      bottom: 48 + MediaQuery.of(context).padding.bottom,
      left: 0,
      right: 0,
      child: Center(
        child: FloatingActionButton(
          heroTag: 'qr-flash-toggle',
          onPressed: () {
            setState(() => _torch = !_torch);
            _controller.toggleTorch();
          },
          backgroundColor: Colors.black.withOpacity(0.4),
          child: Icon(
            _torch ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
            color: _torch ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }
}

/// Painter untuk overlay gelap dengan lubang dan sudut pemindai.
class _ScannerOverlayPainter extends CustomPainter {
  final Size holeSize;
  final double borderRadius;
  final Color overlayColor;
  final Color cornerColor;

  _ScannerOverlayPainter({
    required this.holeSize,
    this.borderRadius = 24.0,
    this.overlayColor = Colors.black54,
    this.cornerColor = Colors.greenAccent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final holeRect = Rect.fromCenter(center: center, width: holeSize.width, height: holeSize.height);
    final holeRRect = RRect.fromRectAndRadius(holeRect, Radius.circular(borderRadius));

    // DIUBAH: Cara yang lebih efisien untuk membuat path dengan lubang
    final overlayPath = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(holeRRect)
      ..fillType = PathFillType.evenOdd; // Menggunakan aturan even-odd

    canvas.drawPath(overlayPath, Paint()..color = overlayColor);

    // Menggambar sudut pemindai
    const cornerLength = 28.0;
    const strokeWidth = 5.0;
    final paint = Paint()
      ..color = cornerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Gambar 4 sudut dengan path
    canvas.drawPath(
        Path()
          ..moveTo(holeRect.left, holeRect.top + cornerLength)
          ..lineTo(holeRect.left, holeRect.top)
          ..lineTo(holeRect.left + cornerLength, holeRect.top),
        paint);
    canvas.drawPath(
        Path()
          ..moveTo(holeRect.right - cornerLength, holeRect.top)
          ..lineTo(holeRect.right, holeRect.top)
          ..lineTo(holeRect.right, holeRect.top + cornerLength),
        paint);
    canvas.drawPath(
        Path()
          ..moveTo(holeRect.left, holeRect.bottom - cornerLength)
          ..lineTo(holeRect.left, holeRect.bottom)
          ..lineTo(holeRect.left + cornerLength, holeRect.bottom),
        paint);
    canvas.drawPath(
        Path()
          ..moveTo(holeRect.right - cornerLength, holeRect.bottom)
          ..lineTo(holeRect.right, holeRect.bottom)
          ..lineTo(holeRect.right, holeRect.bottom - cornerLength),
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}