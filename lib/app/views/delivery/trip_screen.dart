import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../controllers/shipping_controller.dart';
import '../../models/shipping_model.dart';
import '../../routes/app_routes.dart';
import 'stop_detail_screen.dart';

class TripScreen extends StatelessWidget {
  const TripScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ShippingController ctrl = Get.find<ShippingController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1d4ed8),
        foregroundColor: Colors.white,
        title: const Text(
          'Trip Aktif',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.offAllNamed(AppRoutes.planList),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: ctrl.refreshTrip,
          ),
        ],
      ),
      body: Obx(() {
        final trip = ctrl.activeTrip.value;
        if (trip == null) {
          return const Center(child: Text('Tidak ada trip aktif.'));
        }
        return RefreshIndicator(
          onRefresh: ctrl.refreshTrip,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _TripHeader(trip: trip, ctrl: ctrl),
              const SizedBox(height: 16),
              _StopsList(trip: trip, ctrl: ctrl),
              const SizedBox(height: 16),
              _AddStopButton(trip: trip, ctrl: ctrl),
              const SizedBox(height: 20),
              const Text(
                'Aksi Perjalanan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _TibaCard(trip: trip, ctrl: ctrl),
              const SizedBox(height: 10),
              _ActionButton(
                icon: Icons.warning_amber_rounded,
                label: 'Lapor Kendala',
                subtitle: 'Laporkan masalah di perjalanan',
                color: Colors.orange,
                enabled: true,
                onTap: () =>
                    Get.toNamed(AppRoutes.tripIncident, arguments: trip),
              ),
              const SizedBox(height: 10),
              _ActionButton(
                icon: Icons.check_circle_rounded,
                label: 'Selesaikan Trip',
                subtitle: 'Tandai trip sebagai selesai',
                color: Colors.green,
                enabled: !ctrl.isSubmitting.value,
                onTap: () => _confirmFinish(context, ctrl, trip),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  void _confirmFinish(
    BuildContext context,
    ShippingController ctrl,
    ShippingTripModel trip,
  ) {
    final pending = trip.pendingCount;
    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green),
            SizedBox(width: 8),
            Text('Konfirmasi Selesai Trip'),
          ],
        ),
        content: Text(
          pending > 0
              ? 'Apakah Anda yakin ingin menyelesaikan trip ini?\n\n$pending tujuan belum dikunjungi. Trip akan ditandai PARTIAL.'
              : 'Apakah Anda yakin ingin menyelesaikan trip ini?\n\nSemua tujuan sudah dikunjungi. Trip akan ditandai COMPLETED.',
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final result = await ctrl.finishTrip(trip.id);
              if (result['success'] == true) {
                Get.offAllNamed(AppRoutes.planList);
                Get.snackbar(
                  'Trip Selesai',
                  result['message'] ?? 'Berhasil.',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
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
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text(
              'Ya, Selesai',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Button (same style as active_delivery_screen) ──────
class _WarningBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final MaterialColor color;
  final String buttonLabel;
  final VoidCallback onTap;

  const _WarningBanner({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: color.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color.shade900,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: color.shade700, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 32),
            ),
            child: Text(buttonLabel, style: const TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
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
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: enabled ? Colors.grey.shade800 : Colors.grey,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: enabled ? color : Colors.grey.shade300,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Trip Header ───────────────────────────────────────────────
class _TripHeader extends StatelessWidget {
  final ShippingTripModel trip;
  final ShippingController ctrl;
  const _TripHeader({required this.trip, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Gradient top bar
          Container(
            height: 4,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                colors: [Color(0xFF3b82f6), Color(0xFF6366f1)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status chips row
                Row(
                  children: [
                    _statusChip(),
                    if (trip.isDriverDeviation) ...[
                      const SizedBox(width: 6),
                      _deviationChip('Driver Beda'),
                    ],
                    if (trip.isTruckDeviation) ...[
                      const SizedBox(width: 6),
                      _deviationChip('Truck Beda'),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                // Truck + Driver info
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFeff6ff),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFbfdbfe)),
                      ),
                      child: const Icon(
                        Icons.local_shipping_rounded,
                        color: Color(0xFF1d4ed8),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.actualTruck?.nopol ?? '-',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            letterSpacing: 0.5,
                            color: Color(0xFF1e293b),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 13,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              trip.actualDriver?.nama ?? '-',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                if (trip.planId != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 13,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Plan #${trip.planId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Divider(height: 1, color: Colors.grey.shade100),
                const SizedBox(height: 14),
                // Progress stats
                Row(
                  children: [
                    _progressStat(
                      'Selesai',
                      trip.visitedCount,
                      const Color(0xFF16a34a),
                      const Color(0xFFdcfce7),
                    ),
                    const SizedBox(width: 8),
                    _progressStat(
                      'Skip',
                      trip.skippedCount,
                      const Color(0xFFdc2626),
                      const Color(0xFFfee2e2),
                    ),
                    const SizedBox(width: 8),
                    _progressStat(
                      'Pending',
                      trip.pendingCount,
                      const Color(0xFFd97706),
                      const Color(0xFFfef3c7),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFfef3c7),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFfde68a)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFFd97706),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        const Text(
          'IN PROGRESS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Color(0xFF92400e),
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  );

  Widget _deviationChip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFfee2e2),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFfecaca)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.warning_amber_rounded, size: 10, color: Colors.red.shade700),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.red.shade700,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );

  Widget _progressStat(
    String label,
    int count,
    Color textColor,
    Color bgColor,
  ) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textColor,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: textColor.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

// ─── Stops List ────────────────────────────────────────────────
class _StopsList extends StatelessWidget {
  final ShippingTripModel trip;
  final ShippingController ctrl;
  const _StopsList({required this.trip, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    if (trip.stops.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'Belum ada tujuan. Tambahkan tujuan di bawah.',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ),
      );
    }

    final sorted = [...trip.stops]
      ..sort((a, b) => a.sequence.compareTo(b.sequence));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tujuan (${trip.stops.length})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        ...sorted.map((stop) => _StopCard(stop: stop, trip: trip, ctrl: ctrl)),
      ],
    );
  }
}

class _StopCard extends StatelessWidget {
  final TripStopModel stop;
  final ShippingTripModel trip;
  final ShippingController ctrl;
  const _StopCard({required this.stop, required this.trip, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final Color statusBg;
    final String statusLabel;

    switch (stop.status) {
      case 'visited':
        statusColor = const Color(0xFF16a34a);
        statusBg = const Color(0xFFdcfce7);
        statusLabel = 'Selesai';
        break;
      case 'skipped':
        statusColor = const Color(0xFFdc2626);
        statusBg = const Color(0xFFfee2e2);
        statusLabel = 'Skip';
        break;
      case 'in_progress':
        statusColor = const Color(0xFFd97706);
        statusBg = const Color(0xFFfef3c7);
        statusLabel = 'Aktif';
        break;
      default:
        statusColor = const Color(0xFF6366f1);
        statusBg = const Color(0xFFede9fe);
        statusLabel = 'Menunggu';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: statusColor, width: 3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: stop.canEdit || stop.isVisited
              ? () => Get.to(() => StopDetailScreen(stop: stop, trip: trip))
              : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Sequence badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: statusBg,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${stop.sequence}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stop.destinationText,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF1e293b),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                          if (stop.arrivedAt != null) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.access_time_rounded,
                              size: 11,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              stop.arrivedAt!.substring(11, 16),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                          if (stop.suratJalans.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.description_outlined,
                              size: 11,
                              color: Colors.blue.shade400,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${stop.suratJalans.length} SJ',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (stop.isSkipped && stop.skipReason != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            'Alasan: ${stop.skipReason}',
                            style: TextStyle(
                              color: Colors.red.shade400,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Action buttons
                if (stop.canEdit)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _actionPill(
                        icon: Icons.document_scanner_rounded,
                        color: const Color(0xFF0891b2),
                        onTap: () => _showSpkSheet(context, stop),
                      ),
                      const SizedBox(width: 4),
                      _actionPill(
                        icon: Icons.skip_next_rounded,
                        color: const Color(0xFFdc2626),
                        onTap: () => _skipDialog(context, stop),
                      ),
                    ],
                  )
                else if (!stop.isSkipped)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.shade300,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionPill({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    ),
  );

  void _showSpkSheet(BuildContext context, TripStopModel stop) {
    Get.bottomSheet(
      _SpkSheet(trip: trip, stop: stop, ctrl: ctrl),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  void _showResult(Map<String, dynamic> result) {
    if (result['success'] != true) {
      Get.snackbar(
        'Gagal',
        result['message'] ?? '',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _skipDialog(BuildContext context, TripStopModel stop) {
    final reasonCtrl = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: Text('Skip ${stop.destinationText}?'),
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
              _showResult(result);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Skip', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── Add Stop Button ───────────────────────────────────────────
class _AddStopButton extends StatelessWidget {
  final ShippingTripModel trip;
  final ShippingController ctrl;
  const _AddStopButton({required this.trip, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final activeCount = trip.stops.where((s) => s.status != 'skipped').length;
    if (activeCount >= 5) {
      return Center(
        child: Text(
          'Maksimal 5 tujuan per trip',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: () => _showAddStopSheet(context),
      icon: const Icon(Icons.add_location_alt),
      label: const Text('Tambah Tujuan'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showAddStopSheet(BuildContext context) {
    Get.bottomSheet(
      _AddStopSheet(trip: trip, ctrl: ctrl),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }
}

class _AddStopSheet extends StatefulWidget {
  final ShippingTripModel trip;
  final ShippingController ctrl;
  const _AddStopSheet({required this.trip, required this.ctrl});

  @override
  State<_AddStopSheet> createState() => _AddStopSheetState();
}

class _AddStopSheetState extends State<_AddStopSheet> {
  CustomerInfoModel? _selectedCustomer;
  GateInfoModel? _selectedGate;
  List<CustomerInfoModel> _customers = [];
  List<GateInfoModel> _gates = [];
  bool _loadingCustomers = false;
  bool _loadingGates = false;
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadCustomers('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers(String q) async {
    setState(() => _loadingCustomers = true);
    _customers = await widget.ctrl.searchCustomers(q);
    if (mounted) setState(() => _loadingCustomers = false);
  }

  Future<void> _loadGates(int customerId) async {
    setState(() => _loadingGates = true);
    _gates = await widget.ctrl.gatesByCustomer(customerId);
    if (mounted) setState(() => _loadingGates = false);
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tambah Tujuan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // Customer search
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                labelText: 'Cari Customer',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(
                  const Duration(milliseconds: 400),
                  () => _loadCustomers(v),
                );
              },
            ),
            const SizedBox(height: 8),
            if (_loadingCustomers)
              const Center(child: CircularProgressIndicator())
            else
              SizedBox(
                height: 150,
                child: ListView.builder(
                  itemCount: _customers.length,
                  itemBuilder: (_, i) {
                    final c = _customers[i];
                    return ListTile(
                      dense: true,
                      title: Text(c.nama),
                      selected: _selectedCustomer?.id == c.id,
                      selectedTileColor: Colors.blue.shade50,
                      onTap: () {
                        setState(() {
                          _selectedCustomer = c;
                          _selectedGate = null;
                          _gates = [];
                        });
                        _loadGates(c.id);
                      },
                    );
                  },
                ),
              ),
            if (_selectedCustomer != null) ...[
              const Divider(),
              Text(
                'Gate untuk ${_selectedCustomer!.nama}:',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              if (_loadingGates)
                const Center(child: CircularProgressIndicator())
              else if (_gates.isEmpty)
                Text(
                  'Tidak ada gate tersedia',
                  style: TextStyle(color: Colors.grey.shade500),
                )
              else
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    itemCount: _gates.length,
                    itemBuilder: (_, i) {
                      final g = _gates[i];
                      return ListTile(
                        dense: true,
                        title: Text(g.nama),
                        selected: _selectedGate?.id == g.id,
                        selectedTileColor: Colors.blue.shade50,
                        onTap: () => setState(() => _selectedGate = g),
                      );
                    },
                  ),
                ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedCustomer == null
                    ? null
                    : () async {
                        Get.back();
                        final result = await widget.ctrl.addStop(
                          tripId: widget.trip.id,
                          customerId: _selectedCustomer?.id,
                          gateId: _selectedGate?.id,
                        );
                        if (result['success'] != true) {
                          Get.snackbar(
                            'Gagal',
                            result['message'] ?? '',
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1d4ed8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Tambahkan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tiba Card ─────────────────────────────────────────────────
// Menampilkan stop aktif/berikutnya dengan tombol Tandai Tiba / Tandai Selesai
class _TibaCard extends StatefulWidget {
  final ShippingTripModel trip;
  final ShippingController ctrl;
  const _TibaCard({required this.trip, required this.ctrl});

  @override
  State<_TibaCard> createState() => _TibaCardState();
}

class _TibaCardState extends State<_TibaCard> {
  TripStopModel? _selectedStop;

  TripStopModel? get _defaultStop {
    final sorted = [...widget.trip.stops]
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    return sorted.firstWhereOrNull((s) => s.isInProgress) ??
        sorted.firstWhereOrNull((s) => s.isPlanned);
  }

  List<TripStopModel> get _pendingStops {
    final sorted = [...widget.trip.stops]
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    return sorted.where((s) => s.isPlanned || s.isInProgress).toList();
  }

  @override
  void initState() {
    super.initState();
    _selectedStop = _defaultStop;
  }

  @override
  void didUpdateWidget(_TibaCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedStop != null) {
      final updated = widget.trip.stops.firstWhereOrNull(
        (s) => s.id == _selectedStop!.id,
      );
      if (updated == null || (!updated.isPlanned && !updated.isInProgress)) {
        _selectedStop = _defaultStop;
      } else {
        _selectedStop = updated;
      }
    } else {
      _selectedStop = _defaultStop;
    }
  }

  void _showStopPicker() {
    final stops = _pendingStops;
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Row(
                children: [
                  Icon(
                    Icons.edit_location_alt_rounded,
                    color: Color(0xFF1d4ed8),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Pilih Tujuan Tiba',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Divider(height: 8),
            ...stops.map((stop) {
              final isSelected = _selectedStop?.id == stop.id;
              final isActive = stop.isInProgress;
              final color = isActive
                  ? Colors.orange.shade700
                  : const Color(0xFF6366f1);
              final bg = isActive
                  ? Colors.orange.shade50
                  : const Color(0xFFede9fe);
              return ListTile(
                leading: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      '${stop.sequence}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: color,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  stop.destinationText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1e293b),
                  ),
                ),
                subtitle: Text(
                  isActive ? 'Sedang Aktif' : 'Menunggu',
                  style: TextStyle(
                    fontSize: 11,
                    color: isActive
                        ? Colors.orange.shade600
                        : Colors.grey.shade500,
                  ),
                ),
                trailing: isSelected
                    ? Icon(
                        Icons.check_circle_rounded,
                        color: Colors.blue.shade600,
                      )
                    : Icon(
                        Icons.radio_button_unchecked,
                        color: Colors.grey.shade300,
                      ),
                onTap: () async {
                  setState(() => _selectedStop = stop);
                  Get.back();
                  if (!stop.isInProgress) {
                    await widget.ctrl.setTargetDestination(
                      widget.trip.id,
                      stop.id,
                    );
                  }
                },
              );
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final stop = _selectedStop;
    if (stop == null) return const SizedBox.shrink();

    final bool isArrived = stop.isInProgress;
    final Color accent = isArrived
        ? Colors.green.shade700
        : const Color(0xFF1d4ed8);
    final bool hasMultiplePending = _pendingStops.length > 1;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isArrived
                        ? Icons.where_to_vote_rounded
                        : Icons.location_on_rounded,
                    color: accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArrived ? 'Tujuan Aktif' : 'Tujuan Berikutnya',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        stop.destinationText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1e293b),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isArrived ? 'ARRIVED' : 'MENUJU',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
            if (isArrived && stop.arrivedAt != null) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 38),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Tiba pukul ${stop.arrivedAt!.length >= 16 ? stop.arrivedAt!.substring(11, 16) : stop.arrivedAt!}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Ganti Tujuan button (only when multiple pending stops and not yet arrived)
            if (hasMultiplePending && !isArrived) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showStopPicker,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.swap_horiz_rounded,
                      size: 14,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Ganti tujuan tiba',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Action button
            Obx(
              () => SizedBox(
                width: double.infinity,
                child: isArrived
                    ? ElevatedButton.icon(
                        onPressed: widget.ctrl.isSubmitting.value
                            ? null
                            : () async {
                                final result = await widget.ctrl.doneAtStop(
                                  widget.trip.id,
                                  stop.id,
                                );
                                if (result['success'] != true) {
                                  Get.snackbar(
                                    'Gagal',
                                    result['message'] ?? '',
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white,
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                }
                              },
                        icon: widget.ctrl.isSubmitting.value
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle_rounded, size: 18),
                        label: const Text(
                          'Tandai Selesai di Stop Ini',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: widget.ctrl.isSubmitting.value
                            ? null
                            : () => _arriveWithPhoto(context, stop),
                        icon: widget.ctrl.isSubmitting.value
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.camera_alt_rounded, size: 18),
                        label: const Text(
                          'Tandai Tiba (Foto)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1d4ed8),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _arriveWithPhoto(
    BuildContext context,
    TripStopModel stop,
  ) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
      maxWidth: 1280,
    );
    if (picked == null) return;

    final result = await widget.ctrl.arriveAtStop(
      widget.trip.id,
      stop.id,
      foto: File(picked.path),
    );
    if (result['success'] != true) {
      Get.snackbar(
        'Gagal',
        result['message'] ?? '',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

// ─── SPK Input Sheet ───────────────────────────────────────────
class _SpkSheet extends StatefulWidget {
  final ShippingTripModel trip;
  final TripStopModel stop;
  final ShippingController ctrl;
  const _SpkSheet({required this.trip, required this.stop, required this.ctrl});

  @override
  State<_SpkSheet> createState() => _SpkSheetState();
}

class _SpkSheetState extends State<_SpkSheet> {
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

  Future<void> _submit(String nomor, String method) async {
    final result = await widget.ctrl.addSuratJalan(
      widget.trip.id,
      widget.stop.id,
      nomor,
      method,
    );
    if (!mounted) return;
    if (result['success'] == true) {
      Get.back();
      Get.snackbar(
        'Berhasil',
        'SPK/SJ ditambahkan.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      setState(() => _scanned = false);
      _scanCtrl.start();
      Get.snackbar(
        'Gagal',
        result['message'] ?? '',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final destination = widget.stop.destinationText;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Input SPK / Surat Jalan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        destination,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Toggle scan/manual
                IconButton(
                  icon: Icon(
                    _showManual ? Icons.qr_code_scanner : Icons.keyboard,
                  ),
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
          ),
          const Divider(height: 16),
          // Body
          Flexible(
            child: _showManual
                ? Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      MediaQuery.of(context).viewInsets.bottom + 16,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _manualCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nomor SPK / Surat Jalan',
                            hintText: 'Contoh: SPK/2026/02/001',
                            prefixIcon: Icon(Icons.description),
                            border: OutlineInputBorder(),
                          ),
                          textCapitalization: TextCapitalization.characters,
                          autofocus: true,
                        ),
                        const SizedBox(height: 12),
                        Obx(
                          () => SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: widget.ctrl.isSubmitting.value
                                  ? null
                                  : () {
                                      final val = _manualCtrl.text.trim();
                                      if (val.isEmpty) return;
                                      _scanned = true;
                                      _submit(val, 'manual');
                                    },
                              icon: widget.ctrl.isSubmitting.value
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.check),
                              label: const Text('Simpan'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1d4ed8),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : SizedBox(
                    height: 260,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(20),
                          ),
                          child: MobileScanner(
                            controller: _scanCtrl,
                            onDetect: _onDetect,
                          ),
                        ),
                        // Scan guide overlay
                        Center(
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        Obx(() {
                          if (!widget.ctrl.isSubmitting.value) {
                            return const SizedBox();
                          }
                          return Container(
                            color: Colors.black45,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
