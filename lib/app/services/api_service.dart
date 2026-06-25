import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    // Interceptor: inject token ke setiap request
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: ApiConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (DioException error, handler) {
        handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;

  // Helper: GET request
  Future<Response> get(String path, {Map<String, dynamic>? params}) async {
    return await _dio.get(path, queryParameters: params);
  }

  // Helper: POST JSON
  Future<Response> post(String path, {Map<String, dynamic>? data}) async {
    return await _dio.post(path, data: data);
  }

  // Helper: DELETE request
  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }

  // Helper: POST multipart (untuk upload foto)
  Future<Response> postMultipart(
    String path,
    FormData formData,
  ) async {
    return await _dio.post(
      path,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }
}
