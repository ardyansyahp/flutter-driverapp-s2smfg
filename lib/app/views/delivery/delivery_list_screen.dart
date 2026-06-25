import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/delivery_controller.dart';
import '../../models/delivery_model.dart';
import '../../routes/app_routes.dart';
import '../../widgets/delivery_card.dart';
import '../../widgets/status_badge.dart';

class DeliveryListScreen extends StatelessWidget {
  const DeliveryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DeliveryController ctrl = Get.put(DeliveryController());
    final AuthController authCtrl = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1d4ed8),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pengiriman Saya',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Obx(() => Text(
                  authCtrl.user.value?.nama ?? '',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                )),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: ctrl.fetchDeliveries,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Get.dialog(
              AlertDialog(
                title: const Text('Logout'),
                content: const Text('Yakin ingin keluar?'),
                actions: [
                  TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Batal')),
                  ElevatedButton(
                      onPressed: authCtrl.logout,
                      child: const Text('Logout')),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: ctrl.fetchDeliveries,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // === SECTION: SJ Siap Scan ===
              if (ctrl.pendingSjs.isNotEmpty) ...[
                _sectionHeader('Surat Jalan Siap Scan', Icons.qr_code_scanner,
                    Colors.orange),
                const SizedBox(height: 8),
                ...ctrl.pendingSjs.map((spk) => _PendingSpkCard(spk: spk)),
                const SizedBox(height: 20),
              ],

              // === SECTION: Pengiriman Aktif ===
              _sectionHeader(
                  'Pengiriman Aktif', Icons.local_shipping, Colors.blue),
              const SizedBox(height: 8),

              if (ctrl.activeDeliveries.isEmpty)
                _emptyState()
              else
                ...ctrl.activeDeliveries
                    .map((d) => DeliveryCard(delivery: d)),
            ],
          ),
        );
      }),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('Tidak ada pengiriman aktif',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
        ],
      ),
    );
  }
}

class _PendingSpkCard extends StatelessWidget {
  final SpkModel spk;
  const _PendingSpkCard({required this.spk});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusBadge(status: 'READY', color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'SJ: ${spk.noSuratJalan ?? '-'}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _infoRow(Icons.location_on, spk.destinationText),
            _infoRow(Icons.local_shipping,
                'Truck: ${spk.nomorPlat ?? '-'}'),
            if (spk.jamBerangkatPlan != null)
              _infoRow(Icons.schedule, 'Plan: ${spk.jamBerangkatPlan}'),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    Get.toNamed(AppRoutes.scanTruck, arguments: spk),
                icon: const Icon(Icons.qr_code_scanner, size: 18),
                label: const Text('Scan Truck'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1d4ed8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Expanded(
              child: Text(text,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13))),
        ],
      ),
    );
  }
}
