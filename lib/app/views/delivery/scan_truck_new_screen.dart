import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../controllers/shipping_controller.dart';
import '../../routes/app_routes.dart';

/// Scan truck screen for the new flexible shipping system.
/// Accepts optional arguments: { 'plan_id': int } when coming from a plan.
class ScanTruckNewScreen extends StatefulWidget {
  const ScanTruckNewScreen({super.key});

  @override
  State<ScanTruckNewScreen> createState() => _ScanTruckNewScreenState();
}

class _ScanTruckNewScreenState extends State<ScanTruckNewScreen> {
  final ShippingController _ctrl = Get.find<ShippingController>();
  late final MobileScannerController _scannerCtrl;
  final TextEditingController _manualCtrl = TextEditingController();
  bool _scanned = false;
  bool _torchOn = false;
  bool _showManual = false;

  int? get _planId {
    final args = Get.arguments;
    if (args is Map) return args['plan_id'] as int?;
    return null;
  }

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
    final result = await _ctrl.startTrip(
      nopol.trim().toUpperCase(),
      planId: _planId,
    );
    if (!mounted) return;
    if (result['success'] == true) {
      if (!mounted) return;
      Get.offAllNamed(AppRoutes.tripActive);
      Get.snackbar(
        'Trip Dimulai',
        result['message'] ?? 'Berhasil!',
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
        title: Text(_planId != null ? 'Scan Truck (Plan #$_planId)' : 'Scan Truck'),
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
          final boxSize = (screenW * 0.8).clamp(240.0, 360.0);
          final left = (screenW - boxSize) / 2;
          final top = (screenH - boxSize) / 2;
          final scanWindow = Rect.fromLTWH(left, top, boxSize, boxSize);

          return Stack(
            children: [
              if (_planId != null)
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Container(
                    color: Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Text(
                      'Plan #$_planId — Scan truck untuk memulai',
                      style: const TextStyle(color: Colors.orange, fontSize: 13),
                    ),
                  ),
                ),
              MobileScanner(
                controller: _scannerCtrl,
                onDetect: _onDetect,
                scanWindow: scanWindow,
              ),
              CustomPaint(
                painter: _ScanOverlayPainter(scanWindow: scanWindow),
                child: const SizedBox.expand(),
              ),
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
              Positioned(
                top: top + boxSize + 16, left: 0, right: 0,
                child: const Text(
                  'Arahkan ke QR / barcode nopol truck',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              if (_showManual)
                Positioned(
                  bottom: 0, left: 0, right: 0,
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
                              hintStyle: const TextStyle(color: Colors.white54),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Colors.white30),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Colors.blue),
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
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          ),
                          child: const Text('OK', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
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
                        Text('Memulai trip...', style: TextStyle(color: Colors.white)),
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
  bool shouldRepaint(_CornerPainter old) => false;
}
