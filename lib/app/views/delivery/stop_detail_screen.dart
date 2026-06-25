import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../controllers/shipping_controller.dart';
import '../../models/shipping_model.dart';

class StopDetailScreen extends StatelessWidget {
  final TripStopModel stop;
  final ShippingTripModel trip;

  const StopDetailScreen({super.key, required this.stop, required this.trip});

  @override
  Widget build(BuildContext context) {
    final ShippingController ctrl = Get.find<ShippingController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1d4ed8),
        foregroundColor: Colors.white,
        title: Text('Tujuan #${stop.sequence}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Obx(() {
        // Get live stop data from active trip
        final liveTrip = ctrl.activeTrip.value;
        final liveStop = liveTrip?.stops.firstWhereOrNull((s) => s.id == stop.id) ?? stop;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StopInfoCard(stop: liveStop),
            const SizedBox(height: 16),
            _SuratJalanSection(stop: liveStop, trip: trip, ctrl: ctrl),
            const SizedBox(height: 16),
            if (liveStop.canEdit) _ActionButtons(stop: liveStop, trip: trip, ctrl: ctrl),
          ],
        );
      }),
    );
  }
}

// ─── Info Card ─────────────────────────────────────────────────
class _StopInfoCard extends StatelessWidget {
  final TripStopModel stop;
  const _StopInfoCard({required this.stop});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (stop.status) {
      'visited' => Colors.green,
      'skipped' => Colors.red,
      'in_progress' => Colors.orange,
      _ => Colors.grey,
    };
    final statusLabel = switch (stop.status) {
      'visited' => 'SELESAI',
      'skipped' => 'SKIP',
      'in_progress' => 'SEDANG DIKUNJUNGI',
      _ => 'BELUM',
    };

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(statusLabel,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
            ),
            const SizedBox(height: 10),
            _row(Icons.business,
                stop.customer?.nama ?? 'Customer tidak ditentukan',
                bold: true),
            _row(Icons.location_on, stop.gate?.nama ?? 'Gate tidak ditentukan'),
            if (stop.arrivedAt != null)
              _row(Icons.access_time, 'Tiba: ${_fmt(stop.arrivedAt!)}'),
            if (stop.departedAt != null)
              _row(Icons.exit_to_app, 'Selesai: ${_fmt(stop.departedAt!)}'),
            if (stop.isSkipped && stop.skipReason != null)
              _row(Icons.info_outline, 'Alasan skip: ${stop.skipReason}',
                  color: Colors.red.shade700),
          ],
        ),
      ),
    );
  }

  String _fmt(String dt) => dt.length >= 16 ? dt.substring(11, 16) : dt;

  Widget _row(IconData icon, String text, {bool bold = false, Color? color}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(icon, size: 15, color: color ?? Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 13,
                      color: color ?? Colors.grey.shade800,
                      fontWeight: bold ? FontWeight.w600 : FontWeight.normal)),
            ),
          ],
        ),
      );
}

// ─── Surat Jalan Section ───────────────────────────────────────
class _SuratJalanSection extends StatelessWidget {
  final TripStopModel stop;
  final ShippingTripModel trip;
  final ShippingController ctrl;
  const _SuratJalanSection(
      {required this.stop, required this.trip, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Surat Jalan (${stop.suratJalans.length})',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            if (!stop.isSkipped)
              TextButton.icon(
                onPressed: () => _showAddSjSheet(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah'),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (stop.suratJalans.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.description_outlined,
                    size: 36, color: Colors.grey.shade400),
                const SizedBox(height: 6),
                Text('Belum ada surat jalan',
                    style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
          )
        else
          ...stop.suratJalans.map((sj) => _SjTile(
              sj: sj,
              canDelete: !stop.isSkipped,
              onDelete: () async {
                final result =
                    await ctrl.deleteSuratJalan(trip.id, stop.id, sj.id);
                if (result['success'] != true) {
                  Get.snackbar('Gagal', result['message'] ?? '',
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                      snackPosition: SnackPosition.BOTTOM);
                }
              })),
      ],
    );
  }

  void _showAddSjSheet(BuildContext context) {
    Get.to(() => _SjScanPage(stop: stop, trip: trip, ctrl: ctrl));
  }
}

class _SjTile extends StatelessWidget {
  final SuratJalanModel sj;
  final bool canDelete;
  final VoidCallback onDelete;
  const _SjTile(
      {required this.sj, required this.canDelete, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 1,
      child: ListTile(
        dense: true,
        leading: Icon(
          sj.inputMethod == 'scan' ? Icons.qr_code_scanner : Icons.edit_note,
          color: sj.inputMethod == 'scan' ? Colors.blue : Colors.orange,
          size: 22,
        ),
        title: Text(sj.nomorSj,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          '${sj.inputMethod == 'scan' ? 'Scan' : 'Manual'} • ${sj.createdAt.length >= 16 ? sj.createdAt.substring(11, 16) : sj.createdAt}',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: canDelete
            ? IconButton(
                icon: Icon(Icons.delete_outline,
                    color: Colors.red.shade400, size: 20),
                onPressed: () => Get.dialog(AlertDialog(
                  title: const Text('Hapus Surat Jalan?'),
                  content: Text('Hapus SJ ${sj.nomorSj}?'),
                  actions: [
                    TextButton(onPressed: Get.back, child: const Text('Batal')),
                    ElevatedButton(
                      onPressed: () {
                        Get.back();
                        onDelete();
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red),
                      child: const Text('Hapus',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                )),
              )
            : null,
      ),
    );
  }
}

// ─── SJ Full-Screen Scan Page ──────────────────────────────────
class _SjScanPage extends StatefulWidget {
  final TripStopModel stop;
  final ShippingTripModel trip;
  final ShippingController ctrl;
  const _SjScanPage(
      {required this.stop, required this.trip, required this.ctrl});

  @override
  State<_SjScanPage> createState() => _SjScanPageState();
}

class _SjScanPageState extends State<_SjScanPage> {
  late final MobileScannerController _scanCtrl;
  final TextEditingController _manualCtrl = TextEditingController();
  bool _scanned = false;
  bool _showManual = false;

  @override
  void initState() {
    super.initState();
    _scanCtrl = MobileScannerController(
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 500,
    );
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    _manualCtrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;
    _scanned = true;
    _scanCtrl.stop();
    _submit(barcode!.rawValue!, 'scan');
  }

  Future<void> _submit(String nomorSj, String method) async {
    final result = await widget.ctrl.addSuratJalan(
      widget.trip.id,
      widget.stop.id,
      nomorSj,
      method,
    );
    if (!mounted) return;
    if (result['success'] == true) {
      Get.back();
    } else {
      setState(() => _scanned = false);
      _scanCtrl.start();
      Get.snackbar('Gagal', result['message'] ?? '',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text('Scan SJ — ${widget.stop.destinationText}',
            style: const TextStyle(fontSize: 14)),
        actions: [
          IconButton(
            icon: Icon(_showManual ? Icons.qr_code_scanner : Icons.keyboard),
            tooltip: _showManual ? 'Mode Scan' : 'Input Manual',
            onPressed: () {
              setState(() {
                _showManual = !_showManual;
                if (_showManual) {
                  _scanCtrl.stop();
                } else {
                  _scanned = false;
                  _scanCtrl.start();
                }
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (!_showManual)
            MobileScanner(
              controller: _scanCtrl,
              onDetect: _onDetect,
            )
          else
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: _manualCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Nomor Surat Jalan',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: 'Contoh: SJ/2026/02/001',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.description,
                          color: Colors.white54),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.blue),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white12,
                    ),
                    textCapitalization: TextCapitalization.characters,
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final val = _manualCtrl.text.trim();
                        if (val.isEmpty) return;
                        _scanned = true;
                        _submit(val, 'manual');
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Simpan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1d4ed8),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Loading overlay
          Obx(() {
            if (!widget.ctrl.isSubmitting.value) return const SizedBox();
            return Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Menyimpan...', style: TextStyle(color: Colors.white)),
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

// ─── Action Buttons ────────────────────────────────────────────
class _ActionButtons extends StatelessWidget {
  final TripStopModel stop;
  final ShippingTripModel trip;
  final ShippingController ctrl;
  const _ActionButtons(
      {required this.stop, required this.trip, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Column(
          children: [
            if (stop.isPlanned)
              _btn(
                label: 'Tandai Tiba',
                icon: Icons.location_on,
                color: Colors.blue.shade700,
                onTap: ctrl.isSubmitting.value
                    ? null
                    : () => _arriveWithPhoto(context),
              ),
            if (stop.isInProgress)
              _btn(
                label: 'Tandai Selesai di Stop Ini',
                icon: Icons.check_circle,
                color: Colors.green.shade700,
                onTap: ctrl.isSubmitting.value
                    ? null
                    : () async {
                        final result =
                            await ctrl.doneAtStop(trip.id, stop.id);
                        _feedback(result);
                        if (result['success'] == true) Get.back();
                      },
              ),
            const SizedBox(height: 8),
            _btn(
              label: 'Skip Tujuan Ini',
              icon: Icons.skip_next,
              color: Colors.red.shade700,
              outlined: true,
              onTap: ctrl.isSubmitting.value
                  ? null
                  : () => _skipDialog(context),
            ),
          ],
        ));
  }

  Widget _btn({
    required String label,
    required IconData icon,
    required Color color,
    bool outlined = false,
    VoidCallback? onTap,
  }) {
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
    if (outlined) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color),
            minimumSize: const Size(double.infinity, 48),
            shape: shape,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: onTap == null
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: shape,
        ),
      ),
    );
  }

  Future<void> _arriveWithPhoto(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
      maxWidth: 1280,
    );
    if (picked == null) return;
    final result = await ctrl.arriveAtStop(trip.id, stop.id, foto: File(picked.path));
    _feedback(result);
  }

  void _feedback(Map<String, dynamic> result) {
    if (result['success'] != true) {
      Get.snackbar('Gagal', result['message'] ?? '',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _skipDialog(BuildContext context) {
    final reasonCtrl = TextEditingController();
    Get.dialog(AlertDialog(
      title: const Text('Skip Tujuan Ini?'),
      content: TextField(
        controller: reasonCtrl,
        decoration: const InputDecoration(
          labelText: 'Alasan (opsional)',
          border: OutlineInputBorder(),
        ),
        maxLines: 2,
      ),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Batal')),
        ElevatedButton(
          onPressed: () async {
            Get.back();
            final result = await ctrl.skipStop(
              trip.id,
              stop.id,
              reason: reasonCtrl.text.trim().isEmpty
                  ? null
                  : reasonCtrl.text.trim(),
            );
            _feedback(result);
            if (result['success'] == true) Get.back();
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Skip', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }
}
