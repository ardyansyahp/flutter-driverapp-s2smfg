import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/shipping_controller.dart';
import '../../models/shipping_model.dart';
import '../../routes/app_routes.dart';

class PlanListScreen extends StatelessWidget {
  const PlanListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ShippingController ctrl = Get.find<ShippingController>();
    final AuthController authCtrl = Get.find<AuthController>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1d4ed8),
          foregroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pengiriman', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Obx(() => Text(authCtrl.user.value?.nama ?? '',
                  style: const TextStyle(fontSize: 12, color: Colors.white70))),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: () {
              ctrl.fetchPlans();
              ctrl.fetchActiveTrip();
            }),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => Get.dialog(AlertDialog(
                title: const Text('Logout'),
                content: const Text('Yakin ingin keluar?'),
                actions: [
                  TextButton(onPressed: Get.back, child: const Text('Batal')),
                  ElevatedButton(onPressed: authCtrl.logout, child: const Text('Logout')),
                ],
              )),
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Plan Hari Ini'),
              Tab(text: 'Trip Aktif'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _PlanTab(ctrl: ctrl, authCtrl: authCtrl),
            _ActiveTripTab(ctrl: ctrl),
          ],
        ),
        floatingActionButton: Obx(() {
          if (ctrl.activeTrip.value != null) return const SizedBox();
          return FloatingActionButton.extended(
            onPressed: () => Get.toNamed(AppRoutes.scanTruckNew),
            backgroundColor: const Color(0xFF1d4ed8),
            icon: const Icon(Icons.add_road, color: Colors.white),
            label: const Text('Trip Tanpa Plan', style: TextStyle(color: Colors.white)),
          );
        }),
      ),
    );
  }
}

// ==================== TAB 1: Plan hari ini ====================
class _PlanTab extends StatelessWidget {
  final ShippingController ctrl;
  final AuthController authCtrl;
  const _PlanTab({required this.ctrl, required this.authCtrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      return RefreshIndicator(
        onRefresh: ctrl.fetchPlans,
        child: ctrl.plans.isEmpty
            ? _emptyPlans()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: ctrl.plans.length,
                itemBuilder: (_, i) => _PlanCard(
                  plan: ctrl.plans[i],
                  ctrl: ctrl,
                  authCtrl: authCtrl,
                ),
              ),
      );
    });
  }

  Widget _emptyPlans() {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 60),
        Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Text('Tidak ada plan hari ini',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final ShippingPlanModel plan;
  final ShippingController ctrl;
  final AuthController authCtrl;
  const _PlanCard({required this.plan, required this.ctrl, required this.authCtrl});

  @override
  Widget build(BuildContext context) {
    final myManpowerId = authCtrl.user.value?.manpowerId;
    final isMyPlan = plan.assignedDriver != null &&
        myManpowerId != null &&
        plan.assignedDriver!.id == myManpowerId;
    final isInProgress = plan.isInProgress;
    final activeByDriver = plan.activeTrip?.driver;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                _statusBadge(plan.status),
                const SizedBox(width: 8),
                if (isMyPlan)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Penugasan Saya',
                        style: TextStyle(fontSize: 11, color: Color(0xFF1d4ed8))),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Assignment info
            _infoRow(Icons.person, 'Driver: ${plan.assignedDriver?.nama ?? "Tidak ditentukan"}'),
            _infoRow(Icons.local_shipping,
                'Truck: ${plan.assignedTruck?.nopol ?? "Tidak ditentukan"}'),
            if (plan.notes != null && plan.notes!.isNotEmpty)
              _infoRow(Icons.note, plan.notes!),

            const SizedBox(height: 8),
            // Stops summary
            if (plan.stops.isNotEmpty) ...[
              Text('${plan.stops.length} Tujuan:',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 4),
              ...plan.stops.take(3).map((s) => _stopRow(s)),
              if (plan.stops.length > 3)
                Text('+${plan.stops.length - 3} lainnya',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ],

            const SizedBox(height: 10),

            // Action button
            SizedBox(
              width: double.infinity,
              child: isInProgress
                  ? OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.lock_clock, size: 16),
                      label: Text('Sedang Berjalan${activeByDriver != null ? " - $activeByDriver" : ""}'),
                    )
                  : plan.isDone
                      ? OutlinedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.check_circle, size: 16),
                          label: const Text('Selesai'),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.green),
                        )
                      : ElevatedButton.icon(
                          onPressed: () => Get.toNamed(AppRoutes.scanTruckNew,
                              arguments: {'plan_id': plan.id}),
                          icon: const Icon(Icons.qr_code_scanner, size: 18),
                          label: Text(isMyPlan ? 'Mulai (Scan Truck)' : 'Ambil & Scan Truck'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isMyPlan
                                ? const Color(0xFF1d4ed8)
                                : Colors.orange.shade700,
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

  Widget _statusBadge(String status) {
    final Map<String, ({Color bg, Color text, String label})> map = {
      'open': (bg: Colors.blue.shade50, text: Colors.blue.shade700, label: 'OPEN'),
      'in_progress': (bg: Colors.orange.shade50, text: Colors.orange.shade800, label: 'BERJALAN'),
      'partial': (bg: Colors.amber.shade50, text: Colors.amber.shade800, label: 'PARTIAL'),
      'completed': (bg: Colors.green.shade50, text: Colors.green.shade700, label: 'SELESAI'),
    };
    final s = map[status] ?? (bg: Colors.grey.shade100, text: Colors.grey.shade700, label: status.toUpperCase());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(12)),
      child: Text(s.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: s.text)),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: TextStyle(color: Colors.grey.shade700, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _stopRow(PlanStopModel stop) {
    final icon = switch (stop.status) {
      'visited' => Icons.check_circle,
      'skipped' => Icons.cancel,
      'in_progress' => Icons.radio_button_checked,
      _ => Icons.radio_button_unchecked,
    };
    final color = switch (stop.status) {
      'visited' => Colors.green,
      'skipped' => Colors.red,
      'in_progress' => Colors.orange,
      _ => Colors.grey,
    };
    final dest = stop.customer != null
        ? '${stop.customer!.nama}${stop.gate != null ? " (${stop.gate!.nama})" : ""}'
        : '-';
    return Row(
      children: [
        Text('${stop.sequence}.', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        const SizedBox(width: 4),
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Expanded(child: Text(dest, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

// ==================== TAB 2: Trip Aktif ====================
class _ActiveTripTab extends StatelessWidget {
  final ShippingController ctrl;
  const _ActiveTripTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final trip = ctrl.activeTrip.value;
      if (trip == null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.local_shipping_outlined, size: 56, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 16),
              Text('Tidak ada trip aktif',
                  style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('Pilih plan atau buat trip baru dari tab Plan',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
            ],
          ),
        );
      }

      final total = trip.stops.length;
      final visited = trip.visitedCount;
      final skipped = trip.skippedCount;
      final pending = trip.pendingCount;
      final progress = total > 0 ? visited / total : 0.0;
      final sorted = [...trip.stops]..sort((a, b) => a.sequence.compareTo(b.sequence));

      return RefreshIndicator(
        onRefresh: ctrl.refreshTrip,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            // ── Hero card ─────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1d4ed8), Color(0xFF4f46e5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1d4ed8).withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // badges row
                    Row(
                      children: [
                        _heroChip('TRIP AKTIF', Colors.white.withValues(alpha: 0.25), Colors.white),
                        if (trip.hasDeviation) ...[
                          const SizedBox(width: 8),
                          _heroChip('⚠ DEVIASI',
                              Colors.red.shade400.withValues(alpha: 0.3), Colors.red.shade100),
                        ],
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Trip #${trip.id}',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Truck + Driver
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.local_shipping_rounded,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(trip.actualTruck?.nopol ?? '-',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1)),
                            if (trip.actualDriver != null)
                              Row(
                                children: [
                                  const Icon(Icons.person_outline,
                                      color: Colors.white60, size: 13),
                                  const SizedBox(width: 4),
                                  Text(trip.actualDriver!.nama,
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 13)),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Progress bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Progress Tujuan',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                        Text('$visited / $total',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 7,
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Stats row
                    Row(
                      children: [
                        _statBadge('$visited', 'Selesai', const Color(0xFF4ade80)),
                        const SizedBox(width: 8),
                        _statBadge('$skipped', 'Skip', const Color(0xFFf87171)),
                        const SizedBox(width: 8),
                        _statBadge('$pending', 'Pending', const Color(0xFFfbbf24)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Daftar Stop ───────────────────────────────────
            if (sorted.isNotEmpty) ...[
              const Text('Daftar Tujuan',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1e293b))),
              const SizedBox(height: 10),
              ...sorted.map((stop) => _StopItem(stop: stop)),
              const SizedBox(height: 16),
            ],

            // ── Kelola Trip button ────────────────────────────
            ElevatedButton.icon(
              onPressed: () => Get.toNamed(AppRoutes.tripActive),
              icon: const Icon(Icons.open_in_new_rounded, size: 20),
              label: const Text('Kelola Trip', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1d4ed8),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
                shadowColor: const Color(0xFF1d4ed8).withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _heroChip(String label, Color bg, Color textColor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: textColor)),
      );

  Widget _statBadge(String value, String label, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: color, height: 1)),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      fontSize: 10, color: color.withValues(alpha: 0.9), fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}

class _StopItem extends StatelessWidget {
  final TripStopModel stop;
  const _StopItem({required this.stop});

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final Color statusBg;
    final String statusLabel;
    final IconData statusIcon;

    switch (stop.status) {
      case 'visited':
        statusColor = const Color(0xFF16a34a);
        statusBg = const Color(0xFFdcfce7);
        statusLabel = 'Selesai';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'skipped':
        statusColor = const Color(0xFFdc2626);
        statusBg = const Color(0xFFfee2e2);
        statusLabel = 'Skip';
        statusIcon = Icons.cancel_rounded;
        break;
      case 'in_progress':
        statusColor = const Color(0xFFd97706);
        statusBg = const Color(0xFFfef3c7);
        statusLabel = 'Aktif';
        statusIcon = Icons.radio_button_checked_rounded;
        break;
      default:
        statusColor = const Color(0xFF6366f1);
        statusBg = const Color(0xFFede9fe);
        statusLabel = 'Menunggu';
        statusIcon = Icons.radio_button_unchecked_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: statusColor, width: 3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(color: statusBg, shape: BoxShape.circle),
              child: Center(
                child: Text('${stop.sequence}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: statusColor)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stop.destinationText,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1e293b)),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(statusLabel,
                          style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
                      if (stop.arrivedAt != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.access_time_rounded, size: 11, color: Colors.grey.shade400),
                        const SizedBox(width: 2),
                        Text(stop.arrivedAt!.length >= 16 ? stop.arrivedAt!.substring(11, 16) : stop.arrivedAt!,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      ],
                      if (stop.suratJalans.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.description_outlined, size: 11, color: Colors.blue.shade400),
                        const SizedBox(width: 2),
                        Text('${stop.suratJalans.length} SJ',
                            style: TextStyle(fontSize: 11, color: Colors.blue.shade600, fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
