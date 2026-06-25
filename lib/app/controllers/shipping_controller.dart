import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import '../constants/api_constants.dart';
import '../models/shipping_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class ShippingController extends GetxController {
  final ApiService _api = ApiService();
  final AuthService _authService = AuthService();

  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final plans = <ShippingPlanModel>[].obs;
  final activeTrip = Rxn<ShippingTripModel>();
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPlans();
    fetchActiveTrip();
  }

  @override
  void onClose() {
    super.onClose();
  }

  Future<void> fetchPlans({String? date}) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final query = date != null ? '?date=$date' : '';
      final response = await _api.get('${ApiConstants.plans}$query');
      final data = response.data;
      if (data['success'] == true) {
        plans.value = (data['plans'] as List)
            .map((p) => ShippingPlanModel.fromJson(p))
            .toList();
      }
    } on DioException catch (e) {
      errorMessage.value = e.response?.data?['message'] ?? 'Gagal memuat plan.';
    } catch (e) {
      errorMessage.value = 'Terjadi kesalahan: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchActiveTrip() async {
    try {
      final response = await _api.get(ApiConstants.tripActive);
      final data = response.data;
      if (data['success'] == true && data['trip'] != null) {
        activeTrip.value = ShippingTripModel.fromJson(data['trip']);
        final tripId = activeTrip.value!.id;
        await _authService.saveActiveDeliveryId(tripId);
      } else {
        activeTrip.value = null;
      }
    } catch (_) {}
  }

  /// Mulai trip baru dengan scan truck
  Future<Map<String, dynamic>> startTrip(
    String truckBarcode, {
    int? planId,
  }) async {
    isSubmitting.value = true;
    try {
      final body = <String, dynamic>{'truck_barcode': truckBarcode};
      if (planId != null) body['plan_id'] = planId;
      final response = await _api.post(ApiConstants.trips, data: body);
      final data = response.data;
      if (data['success'] == true) {
        activeTrip.value = ShippingTripModel.fromJson(data['trip']);
        final tripId = activeTrip.value!.id;
        await _authService.saveActiveDeliveryId(tripId);
        await fetchPlans();
      }
      return data;
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Gagal memulai trip.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> refreshTrip() async {
    if (activeTrip.value == null) return;
    try {
      final response = await _api.get(
        ApiConstants.tripDetail(activeTrip.value!.id),
      );
      final data = response.data;
      if (data['success'] == true) {
        activeTrip.value = ShippingTripModel.fromJson(data['trip']);
      }
    } catch (_) {}
  }

  Future<Map<String, dynamic>> addStop({
    required int tripId,
    required int? customerId,
    required int? gateId,
  }) async {
    isSubmitting.value = true;
    try {
      final body = <String, dynamic>{};
      if (customerId != null) body['customer_id'] = customerId;
      if (gateId != null) body['gate_id'] = gateId;
      final response = await _api.post(
        ApiConstants.tripAddStop(tripId),
        data: body,
      );
      final data = response.data;
      if (data['success'] == true) await refreshTrip();
      return data;
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Gagal menambah stop.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<Map<String, dynamic>> arriveAtStop(
    int tripId,
    int stopId, {
    required File foto,
  }) async {
    isSubmitting.value = true;
    try {
      final formData = FormData.fromMap({
        'foto': await MultipartFile.fromFile(foto.path, filename: 'tiba.jpg'),
      });
      final response = await _api.postMultipart(
        ApiConstants.tripStopArrive(tripId, stopId),
        formData,
      );
      final data = response.data;
      if (data['success'] == true) await refreshTrip();
      return data;
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Gagal.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<Map<String, dynamic>> doneAtStop(int tripId, int stopId) async {
    isSubmitting.value = true;
    try {
      final response = await _api.post(
        ApiConstants.tripStopDone(tripId, stopId),
      );
      final data = response.data;
      if (data['success'] == true) await refreshTrip();
      return data;
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Gagal.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<Map<String, dynamic>> setTargetDestination(
    int tripId,
    int stopId,
  ) async {
    isSubmitting.value = true;
    try {
      final response = await _api.post(
        '${ApiConstants.trips}/$tripId/stops/$stopId/set-target',
      );
      final data = response.data;
      if (data['success'] == true) await refreshTrip();
      return data;
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Gagal mengatur tujuan.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<Map<String, dynamic>> skipStop(
    int tripId,
    int stopId, {
    String? reason,
  }) async {
    isSubmitting.value = true;
    try {
      final response = await _api.post(
        ApiConstants.tripStopSkip(tripId, stopId),
        data: {'reason': reason},
      );
      final data = response.data;
      if (data['success'] == true) await refreshTrip();
      return data;
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Gagal.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<Map<String, dynamic>> addSuratJalan(
    int tripId,
    int stopId,
    String nomorSj,
    String method,
  ) async {
    isSubmitting.value = true;
    try {
      final response = await _api.post(
        ApiConstants.tripStopAddSj(tripId, stopId),
        data: {'nomor_sj': nomorSj, 'input_method': method},
      );
      final data = response.data;
      if (data['success'] == true) await refreshTrip();
      return data;
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Gagal.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<Map<String, dynamic>> deleteSuratJalan(
    int tripId,
    int stopId,
    int sjId,
  ) async {
    isSubmitting.value = true;
    try {
      final response = await _api.delete(
        ApiConstants.tripStopDeleteSj(tripId, stopId, sjId),
      );
      final data = response.data;
      if (data['success'] == true) await refreshTrip();
      return data;
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Gagal.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<Map<String, dynamic>> finishTrip(int tripId) async {
    isSubmitting.value = true;
    try {
      final response = await _api.post(ApiConstants.tripFinish(tripId));
      final data = response.data;
      if (data['success'] == true) {
        await _authService.clearActiveDeliveryId();
        activeTrip.value = null;
        await fetchPlans();
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

  Future<Map<String, dynamic>> reportIncident({
    required int tripId,
    required String keterangan,
    String? customKeterangan,
    File? foto,
    double? lat,
    double? lng,
  }) async {
    try {
      final formData = FormData.fromMap({
        'keterangan': keterangan,
        'custom_keterangan': ?customKeterangan,
        'latitude': ?lat,
        'longitude': ?lng,
        if (foto != null)
          'foto': await MultipartFile.fromFile(
            foto.path,
            filename: 'incident.jpg',
          ),
      });
      final response = await _api.postMultipart(
        ApiConstants.tripIncident(tripId),
        formData,
      );
      return response.data;
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Gagal mengirim laporan.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }



  // Search helpers for stop picker
  Future<List<CustomerInfoModel>> searchCustomers(String q) async {
    try {
      final response = await _api.get('${ApiConstants.customers}?q=$q');
      final data = response.data;
      if (data['success'] == true) {
        return (data['customers'] as List)
            .map((c) => CustomerInfoModel.fromJson(c))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<GateInfoModel>> gatesByCustomer(int customerId) async {
    try {
      final response = await _api.get(
        '${ApiConstants.gates}?customer_id=$customerId',
      );
      final data = response.data;
      if (data['success'] == true) {
        return (data['gates'] as List)
            .map((g) => GateInfoModel.fromJson(g))
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
