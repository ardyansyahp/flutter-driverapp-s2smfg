import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../controllers/delivery_controller.dart';
import '../../models/delivery_model.dart';

class ScanTruckScreen extends StatefulWidget {
  final SpkModel spk;
  const ScanTruckScreen({super.key, required this.spk});

  @override
  State<ScanTruckScreen> createState() => _ScanTruckScreenState();
}

class _ScanTruckScreenState extends State<ScanTruckScreen> {
  final DeliveryController _ctrl = Get.find<DeliveryController>();
  late final MobileScannerController _scannerCtrl;
  final TextEditingController _manualCtrl = TextEditingController();
  bool _scanned = false;
  bool _torchOn = false;
  bool _showManual = false;

  @override
  void initState() {
    super.initState();
    _scannerCtrl = MobileScannerController(
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 500,
    );
  }

  @override
  void dispose() {
    _scannerCtrl.dispose();
    _manualCtrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;
    _scanned = true;
    _scannerCtrl.stop();
    _processNopol(barcode!.rawValue!);
  }

  Future<void> _processNopol(String nopol) async {
    final result =
        await _ctrl.processScan(widget.spk.id, nopol.trim().toUpperCase());
    if (!mounted) return;
    if (result['success'] == true) {
      Get.back();
      Get.snackbar(
        'Berhasil',
        result['message'] ?? 'Truck berhasil di-scan!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      setState(() => _scanned = false);
      _scannerCtrl.start();
      Get.snackbar(
        'Gagal',
        result['message'] ?? 'Scan gagal, coba lagi.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Widget sudut kotak scan
  Widget _corner({bool flipX = false, bool flipY = false}) {
    return Transform.scale(
      scaleX: flipX ? -1 : 1,
      scaleY: flipY ? -1 : 1,
      child: SizedBox(
        width: 24,
        height: 24,
        child: CustomPaint(painter: _CornerPainter()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Scan Truck'),
        actions: [
          IconButton(
            icon: Icon(_torchOn ? Icons.flashlight_off : Icons.flashlight_on),
            onPressed: () {
              _scannerCtrl.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
          IconButton(
            icon: const Icon(Icons.keyboard),
            tooltip: 'Input Manual',
            onPressed: () => setState(() => _showManual = !_showManual),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenW = constraints.maxWidth;
          final screenH = constraints.maxHeight;
          // Scan box 80% dari lebar layar agar QR kecil pun terbaca
          final boxSize = (screenW * 0.8).clamp(240.0, 360.0);
          final left = (screenW - boxSize) / 2;
          final top = (screenH - boxSize) / 2;
          final scanWindow = Rect.fromLTWH(left, top, boxSize, boxSize);

          return Stack(
            children: [
              // Info SPK di atas
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black87,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SJ: ${widget.spk.noSuratJalan ?? '-'}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                      Text(
                        'Tujuan: ${widget.spk.destinationText}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        'Truck ditugaskan: ${widget.spk.nomorPlat ?? '-'}',
                        style: const TextStyle(
                            color: Colors.orange, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),

              // Camera scanner — hanya baca dalam area kotak
              MobileScanner(
                controller: _scannerCtrl,
                onDetect: _onDetect,
                scanWindow: scanWindow,
              ),

              // Overlay gelap di luar kotak — pakai CustomPainter agar lubang benar-benar transparan
              CustomPaint(
                painter: _ScanOverlayPainter(scanWindow: scanWindow),
                child: const SizedBox.expand(),
              ),

              // Kotak scan — di-Center sendiri agar tepat sejajar dengan scanWindow
              Center(
                child: Container(
                  width: boxSize,
                  height: boxSize,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.5), width: 1.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Stack(
                    children: [
                      Positioned(top: -1, left: -1, child: _corner()),
                      Positioned(top: -1, right: -1, child: _corner(flipX: true)),
                      Positioned(bottom: -1, left: -1, child: _corner(flipY: true)),
                      Positioned(bottom: -1, right: -1, child: _corner(flipX: true, flipY: true)),
                    ],
                  ),
                ),
              ),
              // Label hint — di bawah kotak, posisi absolut agar tidak geser Center
              Positioned(
                top: top + boxSize + 16,
                left: 0,
                right: 0,
                child: const Text(
                  'Arahkan ke QR / barcode nopol truck',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),

              // Input manual
              if (_showManual)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.black87,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _manualCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Nopol truck (contoh: B 1234 ABC)',
                              hintStyle:
                                  const TextStyle(color: Colors.white54),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: Colors.white30),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    const BorderSide(color: Colors.blue),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white12,
                            ),
                            textCapitalization: TextCapitalization.characters,
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            if (_manualCtrl.text.trim().isEmpty) return;
                            _scanned = true;
                            _scannerCtrl.stop();
                            _processNopol(_manualCtrl.text.trim());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 16),
                          ),
                          child: const Text('OK',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),

              // Loading overlay
              Obx(() {
                if (!_ctrl.isSubmitting.value) return const SizedBox();
                return Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text('Memproses scan...',
                            style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

/// Painter overlay gelap dengan lubang transparan di area scan
class _ScanOverlayPainter extends CustomPainter {
  final Rect scanWindow;
  const _ScanOverlayPainter({required this.scanWindow});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.82);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanWindow, const Radius.circular(14)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ScanOverlayPainter old) => old.scanWindow != scanWindow;
}

/// Painter untuk sudut kotak scan (L-shape)
class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, 0)
      ..lineTo(0, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerPainter oldDelegate) => false;
}
