import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ApiService _api = ApiService();

  /// Login dengan user_id + password (opsional untuk non-admin)
  Future<Map<String, dynamic>> login(String userId, {String? password}) async {
    final response = await _api.post(ApiConstants.login, data: {
      'user_id': userId,
      if (password != null && password.isNotEmpty) 'password': password,
    });
    final data = response.data;
    if (data['success'] == true) {
      await _saveSession(data['token'], data['user']);
    }
    return data;
  }

  /// Login via QR Code scan
  Future<Map<String, dynamic>> loginByQr(String qrCode) async {
    final response = await _api.post(ApiConstants.loginQr, data: {
      'qr_code': qrCode,
    });
    final data = response.data;
    if (data['success'] == true) {
      await _saveSession(data['token'], data['user']);
    }
    return data;
  }

  /// Logout - hapus token
  Future<void> logout() async {
    try {
      await _api.post(ApiConstants.logout);
    } catch (_) {}
    await _clearSession();
  }

  /// Simpan token dan user info ke secure storage
  Future<void> _saveSession(String token, Map<String, dynamic> userJson) async {
    await _storage.write(key: ApiConstants.tokenKey, value: token);
    await _storage.write(
        key: ApiConstants.userKey, value: jsonEncode(userJson));
  }

  /// Hapus session
  Future<void> _clearSession() async {
    await _storage.delete(key: ApiConstants.tokenKey);
    await _storage.delete(key: ApiConstants.userKey);
    await _storage.delete(key: ApiConstants.activeDeliveryKey);
  }

  /// Cek apakah sudah login
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: ApiConstants.tokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Get current user dari storage
  Future<UserModel?> getUser() async {
    final userJson = await _storage.read(key: ApiConstants.userKey);
    if (userJson == null) return null;
    return UserModel.fromJson(jsonDecode(userJson));
  }

  /// Get token
  Future<String?> getToken() async {
    return await _storage.read(key: ApiConstants.tokenKey);
  }

  /// Simpan active delivery ID untuk background GPS
  Future<void> saveActiveDeliveryId(int id) async {
    await _storage.write(
        key: ApiConstants.activeDeliveryKey, value: id.toString());
  }

  /// Hapus active delivery ID
  Future<void> clearActiveDeliveryId() async {
    await _storage.delete(key: ApiConstants.activeDeliveryKey);
  }

  /// Get active delivery ID
  Future<int?> getActiveDeliveryId() async {
    final val = await _storage.read(key: ApiConstants.activeDeliveryKey);
    if (val == null) return null;
    return int.tryParse(val);
  }
}
