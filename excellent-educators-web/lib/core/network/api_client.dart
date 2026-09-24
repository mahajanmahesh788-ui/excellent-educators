import 'package:dio/dio.dart';
import 'package:excellent_educators_web/core/network/api_exception.dart';
import 'package:excellent_educators_web/core/platform/platform_info.dart';
import 'package:excellent_educators_web/core/storage/token_store.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:flutter/foundation.dart';

class ApiEnvelope {
  const ApiEnvelope({this.data, this.meta = const {}});

  final dynamic data;
  final Map<String, dynamic> meta;
}

class PagedResult {
  const PagedResult({required this.items, required this.meta});

  final List<dynamic> items;
  final Map<String, dynamic> meta;

  int get page => (meta['page'] as num?)?.toInt() ?? 1;
  int get perPage => (meta['per_page'] as num?)?.toInt() ?? 15;
  int get total => (meta['total'] as num?)?.toInt() ?? items.length;
}

class ApiClient {
  ApiClient({
    required this.tokenStore,
    this.onAccountInactive,
    Dio? dio,
    String? baseUrl,
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ??
                    const String.fromEnvironment(
                      'API_BASE_URL',
                      defaultValue: 'http://127.0.0.1:8000',
                    ),
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 20),
                headers: const {
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                },
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenStore.read();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['X-App-Platform'] = PlatformInfo.name;
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );
  }

  final TokenStore tokenStore;
  final VoidCallback? onAccountInactive;
  final Dio _dio;

  Future<Map<String, dynamic>?> post(
    String path, {
    Map<String, dynamic>? data,
  }) {
    return _map(() => _envelope('POST', path, data: data));
  }

  Future<Map<String, dynamic>?> get(
    String path, {
    Map<String, dynamic>? query,
  }) {
    return _map(() => _envelope('GET', path, query: query));
  }

  Future<Map<String, dynamic>?> put(
    String path, {
    Map<String, dynamic>? data,
  }) {
    return _map(() => _envelope('PUT', path, data: data));
  }

  Future<Map<String, dynamic>?> patch(
    String path, {
    Map<String, dynamic>? data,
  }) {
    return _map(() => _envelope('PATCH', path, data: data));
  }

  Future<Map<String, dynamic>?> delete(String path) {
    return _map(() => _envelope('DELETE', path));
  }

  Future<List<dynamic>> getList(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final envelope = await _envelope('GET', path, query: query);
    if (envelope.data == null) {
      return const [];
    }
    if (envelope.data is List) {
      return envelope.data as List<dynamic>;
    }
    throw ApiException(message: AppStrings.expectedAListResponse, code: 'SERVER_ERROR');
  }

  Future<PagedResult> getPage(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final envelope = await _envelope('GET', path, query: query);
    final items = envelope.data is List ? envelope.data as List<dynamic> : const <dynamic>[];
    return PagedResult(items: items, meta: envelope.meta);
  }

  Future<Map<String, dynamic>?> _map(Future<ApiEnvelope> Function() request) async {
    final envelope = await request();
    final data = envelope.data;
    if (data == null) {
      return null;
    }
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {'value': data};
  }

  Future<ApiEnvelope> _envelope(
    String method,
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _dio.request<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: query,
        options: Options(method: method),
      );
      final body = response.data;
      if (body == null) {
        return const ApiEnvelope();
      }
      if (body['success'] == false) {
        throw _fromEnvelope(body, response.statusCode);
      }
      final meta = body['meta'];
      return ApiEnvelope(
        data: body['data'],
        meta: meta is Map<String, dynamic>
            ? meta
            : meta is Map
                ? Map<String, dynamic>.from(meta)
                : const {},
      );
    } on DioException catch (error) {
      throw _fromDio(error);
    }
  }

  ApiException _fromDio(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      return _fromEnvelope(data, error.response?.statusCode);
    }
    if (data is Map) {
      return _fromEnvelope(Map<String, dynamic>.from(data), error.response?.statusCode);
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.unknown) {
      final origin = _dio.options.baseUrl;
      return ApiException(
        message:
            'Cannot reach the API at $origin. Start the Laravel server (`php artisan serve`) and confirm CORS allows this web origin.',
        statusCode: error.response?.statusCode,
        code: 'NETWORK_ERROR',
      );
    }
    return ApiException(
      message: error.message ?? AppStrings.networkError,
      statusCode: error.response?.statusCode,
      code: 'SERVER_ERROR',
    );
  }

  ApiException _fromEnvelope(Map<String, dynamic> body, int? statusCode) {
    final error = body['error'];
    final code = error is Map<String, dynamic> ? error['code'] as String? : null;
    if (code == 'ACCOUNT_INACTIVE') {
      onAccountInactive?.call();
    }
    return ApiException(
      message: body['message'] as String? ?? AppStrings.requestFailed,
      code: code,
      details: error is Map<String, dynamic> ? error['details'] : null,
      statusCode: statusCode,
    );
  }

  void close() => _dio.close();
}
