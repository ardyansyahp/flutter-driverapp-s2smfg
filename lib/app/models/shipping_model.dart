class ShippingPlanModel {
  final int id;
  final String planDate;
  final String status;
  final String? notes;
  final DriverInfoModel? assignedDriver;
  final TruckInfoModel? assignedTruck;
  final List<PlanStopModel> stops;
  final ActiveTripRefModel? activeTrip;

  ShippingPlanModel({
    required this.id,
    required this.planDate,
    required this.status,
    this.notes,
    this.assignedDriver,
    this.assignedTruck,
    required this.stops,
    this.activeTrip,
  });

  factory ShippingPlanModel.fromJson(Map<String, dynamic> json) {
    return ShippingPlanModel(
      id: json['id'],
      planDate: json['plan_date'] ?? '',
      status: json['status'] ?? 'open',
      notes: json['notes'],
      assignedDriver: json['assigned_driver'] != null
          ? DriverInfoModel.fromJson(json['assigned_driver'])
          : null,
      assignedTruck: json['assigned_truck'] != null
          ? TruckInfoModel.fromJson(json['assigned_truck'])
          : null,
      stops: (json['stops'] as List? ?? [])
          .map((s) => PlanStopModel.fromJson(s))
          .toList(),
      activeTrip: json['active_trip'] != null
          ? ActiveTripRefModel.fromJson(json['active_trip'])
          : null,
    );
  }

  bool get isOpen => status == 'open';
  bool get isInProgress => status == 'in_progress';
  bool get isDone => status == 'completed' || status == 'partial';
}

class PlanStopModel {
  final int id;
  final int sequence;
  final String status;
  final String? skipReason;
  final CustomerInfoModel? customer;
  final GateInfoModel? gate;

  PlanStopModel({
    required this.id,
    required this.sequence,
    required this.status,
    this.skipReason,
    this.customer,
    this.gate,
  });

  factory PlanStopModel.fromJson(Map<String, dynamic> json) {
    return PlanStopModel(
      id: json['id'],
      sequence: json['sequence'] ?? 1,
      status: json['status'] ?? 'planned',
      skipReason: json['skip_reason'],
      customer: json['customer'] != null
          ? CustomerInfoModel.fromJson(json['customer'])
          : null,
      gate: json['gate'] != null ? GateInfoModel.fromJson(json['gate']) : null,
    );
  }
}

class ShippingTripModel {
  final int id;
  final int? planId;
  final String status;
  final bool isDriverDeviation;
  final bool isTruckDeviation;
  final String? startedAt;
  final String? endedAt;
  final DriverInfoModel? actualDriver;
  final TruckInfoModel? actualTruck;
  final List<TripStopModel> stops;

  ShippingTripModel({
    required this.id,
    this.planId,
    required this.status,
    required this.isDriverDeviation,
    required this.isTruckDeviation,
    this.startedAt,
    this.endedAt,
    this.actualDriver,
    this.actualTruck,
    required this.stops,
  });

  factory ShippingTripModel.fromJson(Map<String, dynamic> json) {
    return ShippingTripModel(
      id: json['id'],
      planId: json['plan_id'],
      status: json['status'] ?? 'in_progress',
      isDriverDeviation: json['is_driver_deviation'] == true,
      isTruckDeviation: json['is_truck_deviation'] == true,
      startedAt: json['started_at'],
      endedAt: json['ended_at'],
      actualDriver: json['actual_driver'] != null
          ? DriverInfoModel.fromJson(json['actual_driver'])
          : null,
      actualTruck: json['actual_truck'] != null
          ? TruckInfoModel.fromJson(json['actual_truck'])
          : null,
      stops: (json['stops'] as List? ?? [])
          .map((s) => TripStopModel.fromJson(s))
          .toList(),
    );
  }

  bool get hasDeviation => isDriverDeviation || isTruckDeviation;
  bool get isActive => status == 'in_progress';

  int get visitedCount => stops.where((s) => s.status == 'visited').length;
  int get skippedCount => stops.where((s) => s.status == 'skipped').length;
  int get pendingCount =>
      stops.where((s) => s.status == 'planned' || s.status == 'in_progress').length;
}

class TripStopModel {
  final int id;
  final int sequence;
  final String status;
  final String? skipReason;
  final String? arrivedAt;
  final String? departedAt;
  final CustomerInfoModel? customer;
  final GateInfoModel? gate;
  final List<SuratJalanModel> suratJalans;

  TripStopModel({
    required this.id,
    required this.sequence,
    required this.status,
    this.skipReason,
    this.arrivedAt,
    this.departedAt,
    this.customer,
    this.gate,
    required this.suratJalans,
  });

  factory TripStopModel.fromJson(Map<String, dynamic> json) {
    return TripStopModel(
      id: json['id'],
      sequence: json['sequence'] ?? 1,
      status: json['status'] ?? 'planned',
      skipReason: json['skip_reason'],
      arrivedAt: json['arrived_at'],
      departedAt: json['departed_at'],
      customer: json['customer'] != null
          ? CustomerInfoModel.fromJson(json['customer'])
          : null,
      gate: json['gate'] != null ? GateInfoModel.fromJson(json['gate']) : null,
      suratJalans: (json['surat_jalans'] as List? ?? [])
          .map((sj) => SuratJalanModel.fromJson(sj))
          .toList(),
    );
  }

  bool get isPlanned => status == 'planned';
  bool get isInProgress => status == 'in_progress';
  bool get isVisited => status == 'visited';
  bool get isSkipped => status == 'skipped';
  bool get canEdit => !isVisited && !isSkipped;

  String get destinationText {
    final cust = customer?.nama ?? '-';
    final g = gate?.nama ?? '';
    return g.isNotEmpty ? '$cust ($g)' : cust;
  }
}

class SuratJalanModel {
  final int id;
  final String nomorSj;
  final String inputMethod;
  final String createdAt;

  SuratJalanModel({
    required this.id,
    required this.nomorSj,
    required this.inputMethod,
    required this.createdAt,
  });

  factory SuratJalanModel.fromJson(Map<String, dynamic> json) {
    return SuratJalanModel(
      id: json['id'],
      nomorSj: json['nomor_sj'] ?? '',
      inputMethod: json['input_method'] ?? 'manual',
      createdAt: json['created_at'] ?? '',
    );
  }
}

// Shared info models
class DriverInfoModel {
  final int id;
  final String nama;
  final String? nik;

  DriverInfoModel({required this.id, required this.nama, this.nik});

  factory DriverInfoModel.fromJson(Map<String, dynamic> json) =>
      DriverInfoModel(
        id: json['id'],
        nama: json['nama'] ?? '',
        nik: json['nik'],
      );
}

class TruckInfoModel {
  final int id;
  final String nopol;
  final String? jenis;

  TruckInfoModel({required this.id, required this.nopol, this.jenis});

  factory TruckInfoModel.fromJson(Map<String, dynamic> json) => TruckInfoModel(
        id: json['id'],
        nopol: json['nopol'] ?? '',
        jenis: json['jenis'],
      );
}

class CustomerInfoModel {
  final int id;
  final String nama;

  CustomerInfoModel({required this.id, required this.nama});

  factory CustomerInfoModel.fromJson(Map<String, dynamic> json) =>
      CustomerInfoModel(id: json['id'], nama: json['nama'] ?? '');
}

class GateInfoModel {
  final int id;
  final String nama;
  final double? latitude;
  final double? longitude;

  GateInfoModel({required this.id, required this.nama, this.latitude, this.longitude});

  factory GateInfoModel.fromJson(Map<String, dynamic> json) => GateInfoModel(
        id: json['id'],
        nama: json['nama'] ?? '',
        latitude: json['latitude'] != null
            ? double.tryParse(json['latitude'].toString())
            : null,
        longitude: json['longitude'] != null
            ? double.tryParse(json['longitude'].toString())
            : null,
      );
}

class ActiveTripRefModel {
  final int id;
  final String? driver;

  ActiveTripRefModel({required this.id, this.driver});

  factory ActiveTripRefModel.fromJson(Map<String, dynamic> json) =>
      ActiveTripRefModel(id: json['id'], driver: json['driver']);
}
