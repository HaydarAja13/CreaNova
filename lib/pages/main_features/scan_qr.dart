import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanQrPage extends StatefulWidget {
  /// (Opsional) Tangani payload QR sendiri. Jika null, halaman akan pop dengan string.
  final void Function(String code)? onScanned;

  const ScanQrPage({super.key, this.onScanned});

  @override
  State<ScanQrPage> createState() => _ScanQrPageState();
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

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isHandlingResult) return;

    final barcode = capture.barcodes.firstOrNull;
    final value = barcode?.rawValue;

    if (value == null || value.isEmpty) return;

    setState(() => _isHandlingResult = true);
    await _controller.stop();

    if (!mounted) return;

    if (widget.onScanned != null) {
      widget.onScanned!(value);
      Navigator.pop(context);
    } else {
      Navigator.pop(context, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double windowSize = 240.0;

    return Scaffold(
      backgroundColor: Colors.black,
      // Membuat body bisa berada di belakang AppBar
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
          // Pratinjau kamera
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // ✅ DIUBAH: Bungkus CustomPaint dengan SizedBox.expand()
          // Ini memaksa painter untuk menggunakan seluruh layar sebagai kanvasnya,
          // sehingga perhitungan `size.center` akan benar.
          SizedBox.expand(
            child: CustomPaint(
              painter: _ScannerOverlayPainter(
                holeSize: const Size.square(windowSize),
              ),
            ),
          ),

          // Tombol kontrol di bagian bawah
          _buildControls(context),
        ],
      ),
    );
  }

  /// Membangun tombol kontrol (senter)
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