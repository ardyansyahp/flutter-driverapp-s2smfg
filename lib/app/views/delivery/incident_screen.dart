import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:image_picker/image_picker.dart';
import '../../controllers/delivery_controller.dart';
import '../../models/delivery_model.dart';

class IncidentScreen extends StatefulWidget {
  final DeliveryModel delivery;
  const IncidentScreen({super.key, required this.delivery});

  @override
  State<IncidentScreen> createState() => _IncidentScreenState();
}

class _IncidentScreenState extends State<IncidentScreen> {
  static const List<String> _kendalaOptions = [
    'Ban Bocor',
    'Mogok / Mesin Rusak',
    'Kecelakaan',
    'Kemacetan Parah',
    'Cuaca Buruk',
    'Keterlambatan Muat/Bongkar',
    'Lainnya',
  ];

  String? _selectedKendala;
  final _customController = TextEditingController();
  File? _foto;
  bool _submitting = false;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
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
    if (_selectedKendala == null) {
      Get.snackbar(
        'Pilih Kendala',
        'Silakan pilih jenis kendala terlebih dahulu.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_selectedKendala == 'Lainnya' && _customController.text.trim().isEmpty) {
      Get.snackbar(
        'Keterangan Diperlukan',
        'Isi keterangan kendala lainnya.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _submitting = true);
    final ctrl = Get.find<DeliveryController>();
    final result = await ctrl.reportIncident(
      deliveryId: widget.delivery.id,
      keterangan: _selectedKendala!,
      customKeterangan: _selectedKendala == 'Lainnya'
          ? _customController.text.trim()
          : null,
      foto: _foto,
      lat: null,
      lng: null,
    );
    setState(() => _submitting = false);

    if (result['success'] == true) {
      Get.back();
      Get.snackbar(
        'Laporan Terkirim',
        result['message'] ?? 'Kendala berhasil dilaporkan.',
        backgroundColor: Colors.orange,
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
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        title: const Text('Lapor Kendala'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info pengiriman
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
                        Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Info Pengiriman',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const Divider(height: 20),
                    _infoRow('SJ', widget.delivery.noSuratJalan ?? '-'),
                    _infoRow('Tujuan', widget.delivery.destination ?? '-'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Pilih Kendala
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
                        Icon(Icons.list_alt, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Jenis Kendala',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    RadioGroup<String>(
                      groupValue: _selectedKendala,
                      onChanged: (val) =>
                          setState(() => _selectedKendala = val),
                      child: Column(
                        children: _kendalaOptions
                            .map((option) => RadioListTile<String>(
                                  value: option,
                                  title: Text(option,
                                      style: const TextStyle(fontSize: 14)),
                                  activeColor: Colors.orange,
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                ))
                            .toList(),
                      ),
                    ),

                    // Field untuk "Lainnya"
                    if (_selectedKendala == 'Lainnya') ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _customController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Jelaskan kendala yang terjadi...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.orange),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),



            // Foto (opsional)
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
                        Icon(Icons.photo_camera, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Foto Kendala',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        SizedBox(width: 6),
                        Text('(Opsional)',
                            style:
                                TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_foto != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          _foto!,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            onPressed: _ambilFoto,
                            icon: const Icon(Icons.camera_alt, size: 16),
                            label: const Text('Ambil Ulang'),
                          ),
                          TextButton.icon(
                            onPressed: () => setState(() => _foto = null),
                            icon: const Icon(Icons.delete_outline,
                                size: 16, color: Colors.red),
                            label: const Text('Hapus',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ] else ...[
                      OutlinedButton.icon(
                        onPressed: _ambilFoto,
                        icon: const Icon(Icons.add_a_photo),
                        label: const Text('Ambil Foto'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit
            ElevatedButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded),
              label: Text(_submitting ? 'Mengirim...' : 'Kirim Laporan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
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
                style:
                    TextStyle(color: Colors.grey.shade600, fontSize: 13)),
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
