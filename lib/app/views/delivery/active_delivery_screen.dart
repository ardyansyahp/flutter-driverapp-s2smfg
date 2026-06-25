import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import '../../controllers/delivery_controller.dart';
import '../../models/delivery_model.dart';
import '../../routes/app_routes.dart';
import '../../widgets/status_badge.dart';

class ActiveDeliveryScreen extends StatefulWidget {
  final DeliveryModel delivery;
  const ActiveDeliveryScreen({super.key, required this.delivery});

  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  final DeliveryController ctrl = Get.find<DeliveryController>();
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1d4ed8),
        foregroundColor: Colors.white,
        title: Text('SJ: ${widget.delivery.noSuratJalan ?? '-'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: ctrl.fetchDeliveries,
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Live Map ───────────────────────────────────────────────
          const SizedBox(
            height: 120,
            child: Center(
              child: Text('GPS tracking dinonaktifkan.', style: TextStyle(color: Colors.grey)),
            ),
          ),

          // ─── Info + Aksi ─────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Info Card
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              StatusBadge(status: widget.delivery.status),

                            ],
                          ),
                          const SizedBox(height: 12),
                          _infoRow('Tujuan',
                              widget.delivery.destination ?? '-', Icons.location_on),
                          _infoRow(
                              'Truck',
                              widget.delivery.kendaraan?.nopol ?? '-',
                              Icons.directions_car),
                          if (widget.delivery.waktuBerangkat != null)
                            _infoRow(
                                'Berangkat',
                                _formatDt(widget.delivery.waktuBerangkat!),
                                Icons.schedule),
                          if (widget.delivery.waktuTiba != null)
                            _infoRow('Tiba',
                                _formatDt(widget.delivery.waktuTiba!), Icons.flag),

                          if (widget.delivery.incidentsCount > 0)
                            _infoRow(
                              'Kendala',
                              '${widget.delivery.incidentsCount} laporan',
                              Icons.warning_amber,
                              color: Colors.orange,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Aksi Pengiriman',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Lapor Kendala
                  _ActionButton(
                    icon: Icons.warning_amber_rounded,
                    label: 'Lapor Kendala',
                    subtitle: 'Laporkan masalah di perjalanan',
                    color: Colors.orange,
                    enabled: !widget.delivery.isCompleted,
                    onTap: () => Get.toNamed(AppRoutes.incident,
                        arguments: widget.delivery),
                  ),
                  const SizedBox(height: 10),

                  // Tiba di Tujuan
                  _ActionButton(
                    icon: Icons.flag_rounded,
                    label: 'Tiba di Tujuan',
                    subtitle: 'Laporkan kedatangan + foto bukti',
                    color: Colors.purple,
                    enabled: widget.delivery.canReportArrival,
                    onTap: () => Get.toNamed(AppRoutes.arrival,
                        arguments: widget.delivery),
                  ),
                  const SizedBox(height: 10),

                  // Selesai
                  _ActionButton(
                    icon: Icons.check_circle_rounded,
                    label: 'Selesai (Kembali ke PT)',
                    subtitle: 'Tandai perjalanan selesai',
                    color: Colors.green,
                    enabled: widget.delivery.canFinish,
                    onTap: () => _confirmFinish(ctrl),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmFinish(DeliveryController ctrl) {
    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.home, color: Colors.green),
            SizedBox(width: 8),
            Text('Konfirmasi Selesai'),
          ],
        ),
        content: const Text(
            'Apakah Anda yakin sudah kembali ke PT/Pool?\n\nAksi ini akan menandai perjalanan sebagai SELESAI.'),
        actions: [
          TextButton(
              onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final result = await ctrl.finishTrip(widget.delivery.id);
              if (result['success'] == true) {
                Get.back();
                Get.snackbar(
                  'Selesai',
                  result['message'] ?? 'Trip selesai!',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                );
              } else {
                Get.snackbar(
                    'Gagal', result['message'] ?? 'Terjadi kesalahan.',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                    snackPosition: SnackPosition.BOTTOM);
              }
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Ya, Selesai',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color ?? Colors.grey.shade600),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text('$label:',
                style:
                    TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  color: color ?? Colors.grey.shade800,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDt(String dt) {
    try {
      final t = DateTime.parse(dt).toLocal();
      return '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')} '
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dt;
    }
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: enabled ? 2 : 0,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: enabled
                                  ? Colors.grey.shade800
                                  : Colors.grey)),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color:
                        enabled ? color : Colors.grey.shade300),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
