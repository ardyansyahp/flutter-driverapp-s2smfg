import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import '../constants/api_constants.dart';
import '../models/delivery_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class DeliveryController extends GetxController {
  final ApiService _api = ApiService();
  final AuthService _authService = AuthService();

  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final activeDeliveries = <DeliveryModel>[].obs;
  final pendingSjs = <SpkModel>[].obs;
  final errorMessage = ''.obs;
  final successMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDeliveries();
  }

  Future<void> fetchDeliveries() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await _api.get(ApiConstants.deliveries);
      final data = response.data;
      if (data['success'] == true) {
        activeDeliveries.value = (data['active_deliveries'] as List)
            .map((e) => DeliveryModel.fromJson(e))
            .toList();
        pendingSjs.value = (data['pending_sjs'] as List)
            .map((e) => SpkModel.fromJson(e))
            .toList();
      }
    } on DioException catch (e) {
      errorMessage.value = e.response?.data?['message'] ?? 'Gagal memuat data.';
    } catch (e) {
      errorMessage.value = 'Terjadi kesalahan: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Setelah scan truck berhasil
  Future<Map<String, dynamic>> processScan(int spkId, String nopol) async {
    isSubmitting.value = true;
    try {
      final response = await _api.post(
        ApiConstants.deliveryScan,
        data: {'spk_id': spkId, 'kendaraan_barcode': nopol},
      );
      final data = response.data;
      if (data['success'] == true) {
        // Start background GPS
        final deliveryId = data['delivery']['id'] as int;
        await _authService.saveActiveDeliveryId(deliveryId);
        await fetchDeliveries();
      }
      return data;
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Gagal scan truck.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Laporkan tiba + upload foto
  Future<Map<String, dynamic>> reportArrival(
    int deliveryId,
    File foto,
    double? lat,
    double? lng,
  ) async {
    isSubmitting.value = true;
    try {
      final formData = FormData.fromMap({
        'foto': await MultipartFile.fromFile(
          foto.path,
          filename: 'arrival_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
        'latitude': ?lat,
        'longitude': ?lng,
      });
      final response = await _api.postMultipart(
        ApiConstants.deliveryArrival(deliveryId),
        formData,
      );
      final data = response.data;
      if (data['success'] == true) {
        await fetchDeliveries();
      }
      return data;
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Gagal melaporkan tiba.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Selesai - kembali ke PT
  Future<Map<String, dynamic>> finishTrip(int deliveryId) async {
    isSubmitting.value = true;
    try {
      final response = await _api.post(ApiConstants.deliveryFinish(deliveryId));
      final data = response.data;
      if (data['success'] == true) {
        await _authService.clearActiveDeliveryId();
        await fetchDeliveries();
      }
      return data;
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Gagal menyelesaikan trip.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Laporkan kendala/incident
  Future<Map<String, dynamic>> reportIncident({
    required int deliveryId,
    required String keterangan,
    String? customKeterangan,
    File? foto,
    double? lat,
    double? lng,
  }) async {
    isSubmitting.value = true;
    try {
      final formData = FormData.fromMap({
        'delivery_header_id': deliveryId,
        'keterangan': keterangan,
        'custom_keterangan': ?customKeterangan,
        if (foto != null)
          'foto': await MultipartFile.fromFile(
            foto.path,
            filename: 'incident_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        'latitude': ?lat,
        'longitude': ?lng,
      });
      final response = await _api.postMultipart(
        ApiConstants.incident,
        formData,
      );
      return response.data;
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Gagal menyimpan laporan.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    } finally {
      isSubmitting.value = false;
    }
  }
}
