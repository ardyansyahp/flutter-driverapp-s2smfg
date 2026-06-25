import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/delivery_model.dart';
import '../routes/app_routes.dart';
import 'status_badge.dart';

class DeliveryCard extends StatelessWidget {
  final DeliveryModel delivery;
  const DeliveryCard({super.key, required this.delivery});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Get.toNamed(AppRoutes.activeDelivery, arguments: delivery),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StatusBadge(status: delivery.status),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'SJ: ${delivery.noSuratJalan ?? '-'}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 8),
              _infoRow(Icons.location_on, delivery.destination ?? '-'),
              _infoRow(
                Icons.local_shipping,
                delivery.kendaraan?.nopol ?? '-',
              ),
              if (delivery.waktuBerangkat != null)
                _infoRow(Icons.schedule,
                    'Berangkat: ${_formatTime(delivery.waktuBerangkat!)}'),
              if (delivery.incidentsCount > 0)
                _infoRow(
                  Icons.warning_amber,
                  '${delivery.incidentsCount} laporan kendala',
                  color: Colors.orange,
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.touch_app, size: 14, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    'Tap untuk lihat detail & aksi',
                    style: TextStyle(
                        fontSize: 12, color: Colors.blue.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color ?? Colors.grey.shade600),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  color: color ?? Colors.grey.shade700, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String dt) {
    try {
      final t = DateTime.parse(dt);
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dt;
    }
  }
}
