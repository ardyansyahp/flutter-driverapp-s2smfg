class DeliveryModel {
  final int id;
  final String? noSuratJalan;
  final String? destination;
  final String status;
  final String? tanggalBerangkat;
  final String? waktuBerangkat;
  final String? waktuTiba;
  final KendaraanModel? kendaraan;
  final double? currentLatitude;
  final double? currentLongitude;
  final String? lastLocationUpdate;
  final int incidentsCount;
  final String? keterangan;

  DeliveryModel({
    required this.id,
    this.noSuratJalan,
    this.destination,
    required this.status,
    this.tanggalBerangkat,
    this.waktuBerangkat,
    this.waktuTiba,
    this.kendaraan,
    this.currentLatitude,
    this.currentLongitude,
    this.lastLocationUpdate,
    this.incidentsCount = 0,
    this.keterangan,
  });

  factory DeliveryModel.fromJson(Map<String, dynamic> json) {
    return DeliveryModel(
      id: json['id'],
      noSuratJalan: json['no_surat_jalan'],
      destination: json['destination'],
      status: json['status'] ?? 'OPEN',
      tanggalBerangkat: json['tanggal_berangkat'],
      waktuBerangkat: json['waktu_berangkat'],
      waktuTiba: json['waktu_tiba'],
      kendaraan: json['kendaraan'] != null
          ? KendaraanModel.fromJson(json['kendaraan'])
          : null,
      currentLatitude: json['current_latitude'] != null
          ? double.tryParse(json['current_latitude'].toString())
          : null,
      currentLongitude: json['current_longitude'] != null
          ? double.tryParse(json['current_longitude'].toString())
          : null,
      lastLocationUpdate: json['last_location_update'],
      incidentsCount: json['incidents_count'] ?? 0,
      keterangan: json['keterangan'],
    );
  }

  bool get isActive =>
      ['IN_TRANSIT', 'NORMAL', 'ADVANCED', 'DELAY'].contains(status);
  bool get isArrived => status == 'ARRIVED';
  bool get isCompleted => status == 'COMPLETED';
  bool get canSendLocation =>
      ['IN_TRANSIT', 'NORMAL', 'ADVANCED', 'DELAY', 'OPEN'].contains(status);
  bool get canReportArrival =>
      ['IN_TRANSIT', 'NORMAL', 'ADVANCED', 'DELAY'].contains(status);
  bool get canFinish => status == 'ARRIVED';
}

class KendaraanModel {
  final int? id;
  final String nopol;
  final String? jenis;

  KendaraanModel({this.id, required this.nopol, this.jenis});

  factory KendaraanModel.fromJson(Map<String, dynamic> json) {
    return KendaraanModel(
      id: json['id'],
      nopol: json['nopol'] ?? '',
      jenis: json['jenis'],
    );
  }
}

class SpkModel {
  final int id;
  final String? nomorSpk;
  final String? noSuratJalan;
  final String? tanggal;
  final String? jamBerangkatPlan;
  final String? jamDatangPlan;
  final String? nomorPlat;
  final int? cycleNumber;
  final CustomerModel? customer;
  final PlantgateModel? plantgate;

  SpkModel({
    required this.id,
    this.nomorSpk,
    this.noSuratJalan,
    this.tanggal,
    this.jamBerangkatPlan,
    this.jamDatangPlan,
    this.nomorPlat,
    this.cycleNumber,
    this.customer,
    this.plantgate,
  });

  factory SpkModel.fromJson(Map<String, dynamic> json) {
    return SpkModel(
      id: json['id'],
      nomorSpk: json['nomor_spk'],
      noSuratJalan: json['no_surat_jalan'],
      tanggal: json['tanggal'],
      jamBerangkatPlan: json['jam_berangkat_plan'],
      jamDatangPlan: json['jam_datang_plan'],
      nomorPlat: json['nomor_plat'],
      cycleNumber: json['cycle_number'],
      customer:
          json['customer'] != null ? CustomerModel.fromJson(json['customer']) : null,
      plantgate:
          json['plantgate'] != null ? PlantgateModel.fromJson(json['plantgate']) : null,
    );
  }

  String get destinationText {
    final cust = customer?.nama ?? '-';
    final gate = plantgate?.nama ?? '';
    return gate.isNotEmpty ? '$cust ($gate)' : cust;
  }
}

class CustomerModel {
  final String nama;
  CustomerModel({required this.nama});
  factory CustomerModel.fromJson(Map<String, dynamic> json) =>
      CustomerModel(nama: json['nama'] ?? '');
}

class PlantgateModel {
  final String nama;
  final double? latitude;
  final double? longitude;

  PlantgateModel({required this.nama, this.latitude, this.longitude});

  factory PlantgateModel.fromJson(Map<String, dynamic> json) => PlantgateModel(
        nama: json['nama'] ?? '',
        latitude: json['latitude'] != null
            ? double.tryParse(json['latitude'].toString())
            : null,
        longitude: json['longitude'] != null
            ? double.tryParse(json['longitude'].toString())
            : null,
      );
}
