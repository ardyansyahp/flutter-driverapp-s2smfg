import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../routes/app_routes.dart';
import 'shipping_controller.dart';
import 'delivery_controller.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final user = Rxn<UserModel>();

  @override
  void onInit() {
    super.onInit();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    if (await _authService.isLoggedIn()) {
      user.value = await _authService.getUser();
      _goToDashboard();
    }
  }

  void _goToDashboard() {
    final shippingCtrl = Get.find<ShippingController>();
    final deliveryCtrl = Get.find<DeliveryController>();
    
    shippingCtrl.fetchPlans();
    shippingCtrl.fetchActiveTrip();
    deliveryCtrl.fetchDeliveries();
    
    Get.offAllNamed(AppRoutes.planList);
  }

  Future<void> login(String userId, {String? password}) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final result = await _authService.login(userId, password: password);
      if (result['success'] == true) {
        user.value = UserModel.fromJson(result['user']);
        _goToDashboard();
      } else {
        errorMessage.value = result['message'] ?? 'Login gagal.';
      }
    } on DioException catch (e) {
      errorMessage.value = _parseDioError(e);
    } catch (e) {
      errorMessage.value = 'Terjadi kesalahan: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginByQr(String qrCode) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final result = await _authService.loginByQr(qrCode);
      if (result['success'] == true) {
        user.value = UserModel.fromJson(result['user']);
        _goToDashboard();
      } else {
        errorMessage.value = result['message'] ?? 'Login QR gagal.';
      }
    } on DioException catch (e) {
      errorMessage.value = _parseDioError(e);
    } catch (e) {
      errorMessage.value = 'Terjadi kesalahan: $e';
    } finally {
      isLoading.value = false;
    }
  }

  String _parseDioError(DioException e) {
    // Server menjawab dengan error JSON
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      return 'Error ${e.response!.statusCode}: ${e.response!.statusMessage}';
    }
    // Tidak ada respons sama sekali (connection/timeout)
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi timeout. Pastikan HP terhubung ke WiFi yang sama dengan server.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server (${e.message}). Cek IP di api_constants.dart.';
      default:
        return 'Gagal terhubung ke server: ${e.message}';
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    user.value = null;
    Get.offAllNamed(AppRoutes.login);
  }
}
