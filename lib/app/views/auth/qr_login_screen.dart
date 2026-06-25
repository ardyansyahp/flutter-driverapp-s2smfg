import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../controllers/auth_controller.dart';

class QrLoginScreen extends StatefulWidget {
  const QrLoginScreen({super.key});

  @override
  State<QrLoginScreen> createState() => _QrLoginScreenState();
}

class _QrLoginScreenState extends State<QrLoginScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final MobileScannerController _scannerCtrl = MobileScannerController(
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  bool _scanned = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _scannerCtrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned || _authController.isLoading.value) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    _scanned = true;
    _scannerCtrl.stop();
    _authController.loginByQr(barcode!.rawValue!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Scan QR Karyawan'),
        actions: [
          IconButton(
            icon: Icon(_torchOn ? Icons.flashlight_off : Icons.flashlight_on),
            onPressed: () {
              _scannerCtrl.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera scanner
          MobileScanner(
            controller: _scannerCtrl,
            onDetect: _onDetect,
          ),

          // Overlay: kotak scanning
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Panduan teks
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: const Text(
              'Arahkan kamera ke QR Code ID Karyawan',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),

          // Loading overlay
          Obx(() {
            if (!_authController.isLoading.value) return const SizedBox();
            return Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Memverifikasi...',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            );
          }),

          // Error message
          Obx(() {
            if (_authController.errorMessage.value.isEmpty) {
              return const SizedBox();
            }
            return Positioned(
              bottom: 60,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade800,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _authController.errorMessage.value,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: () {
                        _authController.errorMessage.value = '';
                        _scanned = false;
                        _scannerCtrl.start();
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
