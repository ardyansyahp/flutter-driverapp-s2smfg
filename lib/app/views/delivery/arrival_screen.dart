import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:image_picker/image_picker.dart';
import '../../controllers/delivery_controller.dart';
import '../../models/delivery_model.dart';

class ArrivalScreen extends StatefulWidget {
  final DeliveryModel delivery;
  const ArrivalScreen({super.key, required this.delivery});

  @override
  State<ArrivalScreen> createState() => _ArrivalScreenState();
}

class _ArrivalScreenState extends State<ArrivalScreen> {
  final DeliveryController _deliveryController = Get.find();
  
  File? _foto;
  bool _submitting = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _ambilFoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1280,
    );
    if (picked != null) {
      setState(() => _foto = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (_foto == null) {
      Get.snackbar(
        'Foto Diperlukan',
        'Ambil foto bukti kedatangan terlebih dahulu.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _submitting = true);
    final ctrl = Get.find<DeliveryController>();
    final result = await ctrl.reportArrival(
      widget.delivery.id,
      _foto!,
      null,
      null,
    );
    setState(() => _submitting = false);

    if (result['success'] == true) {
      Get.back();
      Get.back();
      Get.snackbar(
        'Tiba!',
        result['message'] ?? 'Kedatangan berhasil dilaporkan.',
        backgroundColor: Colors.purple,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } else {
      Get.snackbar(
        'Gagal',
        result['message'] ?? 'Terjadi kesalahan.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        title: const Text('Lapor Tiba di Tujuan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info tujuan
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.flag_rounded, color: Colors.purple),
                        SizedBox(width: 8),
                        Text('Info Pengiriman',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const Divider(height: 20),
                    _infoRow('SJ', widget.delivery.noSuratJalan ?? '-'),
                    _infoRow('Tujuan', widget.delivery.destination ?? '-'),
                    if (widget.delivery.kendaraan != null)
                      _infoRow('Truck', widget.delivery.kendaraan!.nopol),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Foto
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.photo_camera, color: Colors.purple),
                        SizedBox(width: 8),
                        Text('Foto Bukti Tiba',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_foto != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          _foto!,
                          height: 220,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: _ambilFoto,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Ambil Ulang'),
                      ),
                    ] else ...[
                      GestureDetector(
                        onTap: _ambilFoto,
                        child: Container(
                          height: 160,
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.purple.withValues(alpha: 0.3),
                                width: 2,
                                style: BorderStyle.solid),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo,
                                  size: 48, color: Colors.purple),
                              SizedBox(height: 8),
                              Text('Tap untuk ambil foto',
                                  style: TextStyle(color: Colors.purple)),
                              Text('(Wajib diisi)',
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            ElevatedButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded),
              label: Text(_submitting ? 'Mengirim...' : 'Laporkan Tiba'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text('$label:',
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
