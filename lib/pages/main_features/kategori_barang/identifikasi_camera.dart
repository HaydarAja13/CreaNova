import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import '../../../services/image_recognition_service.dart';
import '../../../widgets/waste_identification_result.dart';

class IdentifikasiCameraPage extends StatefulWidget {
  const IdentifikasiCameraPage({super.key});

  @override
  State<IdentifikasiCameraPage> createState() => _IdentifikasiCameraPageState();
}

class _IdentifikasiCameraPageState extends State<IdentifikasiCameraPage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  Map<String, dynamic>? _identificationResult;
  XFile? _capturedImage;
  bool _showFlash = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        _controller = CameraController(_cameras![0], ResolutionPreset.high);
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller != null &&
        _controller!.value.isInitialized &&
        !_isProcessing) {
      // Show flash effect first
      setState(() {
        _showFlash = true;
      });

      // Brief flash duration
      await Future.delayed(const Duration(milliseconds: 100));

      setState(() {
        _isProcessing = true;
        _showFlash = false;
      });

      try {
        final XFile image = await _controller!.takePicture();

        if (mounted) {
          // Set captured image to freeze the camera preview
          setState(() {
            _capturedImage = image;
          });

          // Add small delay for better UX
          await Future.delayed(const Duration(milliseconds: 1500));

          // Process image with AI
          final result = await ImageRecognitionService.identifyWaste(
            File(image.path),
          );

          if (mounted) {
            if (result != null) {
              setState(() {
                _identificationResult = result;
                _isProcessing = false;
              });
            } else {
              // Use fallback data for demo purposes
              setState(() {
                _identificationResult =
                    ImageRecognitionService.getFallbackResult();
                _isProcessing = false;
              });
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Terjadi kesalahan. Silakan coba lagi.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isProcessing = false;
            _capturedImage = null; // Reset captured image on error
            _showFlash = false;
          });
        }
      }
    }
  }

  void _closeResult() {
    setState(() {
      _identificationResult = null;
      _capturedImage = null; // Reset captured image when closing result
      _showFlash = false;
    });
  }

  void _scanAgain() {
    setState(() {
      _capturedImage = null; // Reset captured image to resume live camera
      _showFlash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            if (_capturedImage != null)
              // Show captured image when processing
              Positioned.fill(
                child: Image.file(
                  File(_capturedImage!.path),
                  fit: BoxFit.cover,
                ),
              )
            else if (_isInitialized && _controller != null)
              // Show live camera preview
              Positioned.fill(child: CameraPreview(_controller!))
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Identifikasi Sampahmu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Camera capture button - With gradient
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _isProcessing ? null : _takePicture,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF123524),
                          Color(0xFF3E7B27),
                          Color(0xFF85A947),
                        ],
                      ),
                      border: Border.all(color: Colors.white, width: 6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: 140,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isProcessing
                      ? 'Sedang menganalisis gambar...'
                      : 'Arahkan kamera ke sampah yang ingin diidentifikasi',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // Loading overlay
            if (_isProcessing)
              Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          strokeWidth: 4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Menganalisis...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Mohon tunggu sebentar',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),

            // Flash effect overlay
            if (_showFlash)
              Positioned.fill(
                child: Container(
                  color: Colors.white,
                ),
              ),

            // Result overlay
            if (_identificationResult != null)
              WasteIdentificationResult(
                result: _identificationResult!,
                onClose: _closeResult,
                onScanAgain: _scanAgain,
              ),
          ],
        ),
      ),
    );
  }
}
