class UserModel {
  final String userId;
  final int role;
  final String nama;
  final String departemen;
  final String bagian;
  final int? manpowerId;

  UserModel({
    required this.userId,
    required this.role,
    required this.nama,
    required this.departemen,
    required this.bagian,
    this.manpowerId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] ?? '',
      role: json['role'] ?? 0,
      nama: json['nama'] ?? '-',
      departemen: json['departemen'] ?? '-',
      bagian: json['bagian'] ?? '-',
      manpowerId: json['manpower_id'],
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'role': role,
        'nama': nama,
        'departemen': departemen,
        'bagian': bagian,
        'manpower_id': manpowerId,
      };
}
