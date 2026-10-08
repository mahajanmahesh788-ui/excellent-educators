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
    this.onSessionExpired,
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
                sendTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 20),
                headers: const {
                  'Accept': 'application/json',
                  // Do not set Content-Type globally — multipart uploads must
                  // set their own boundary. JSON requests set it per-call.
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
  final VoidCallback? onSessionExpired;
  final Dio _dio;
  var _sessionExpiredNotified = false;

  Future<Map<String, dynamic>?> post(
    String path, {
    Object? data,
  }) {
    return _map(() => _envelope('POST', path, data: data));
  }

  Future<Map<String, dynamic>?> get(
    String path, {
    Map<String, dynamic>? query,
  }) {
    return _map(() => _envelope('GET', path, query: query));
  }

  Future<ApiEnvelope> getRaw(
    String path, {
    Map<String, dynamic>? query,
  }) {
    return _envelope('GET', path, query: query);
  }

  Future<Map<String, dynamic>?> put(
    String path, {
    Object? data,
  }) {
    return _map(() => _envelope('PUT', path, data: data));
  }

  Future<Map<String, dynamic>?> patch(
    String path, {
    Object? data,
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

  Future<List<dynamic>> putList(
    String path, {
    Object? data,
  }) async {
    final envelope = await _envelope('PUT', path, data: data);
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
    Object? data,
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _dio.request<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: query,
        options: Options(
          method: method,
          contentType: data is FormData
              ? null
              : Headers.jsonContentType,
          // Photo / receipt uploads can exceed the default 20s on slower links.
          sendTimeout: data is FormData
              ? const Duration(seconds: 90)
              : const Duration(seconds: 20),
          receiveTimeout: data is FormData
              ? const Duration(seconds: 90)
              : const Duration(seconds: 20),
          headers: data is FormData
              ? <String, dynamic>{Headers.contentTypeHeader: null}
              : null,
        ),
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
    final hadBearer = _requestHadBearer(error.requestOptions);
    if (data is Map<String, dynamic>) {
      return _fromEnvelope(data, error.response?.statusCode, hadBearer: hadBearer);
    }
    if (data is Map) {
      return _fromEnvelope(
        Map<String, dynamic>.from(data),
        error.response?.statusCode,
        hadBearer: hadBearer,
      );
    }
    if (error.response?.statusCode == 401 && hadBearer) {
      _notifySessionExpired();
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.unknown) {
      return ApiException(
        message: AppStrings.networkError,
        statusCode: error.response?.statusCode,
        code: 'NETWORK_ERROR',
      );
    }
    if (error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      final isUpload = error.requestOptions.data is FormData;
      return ApiException(
        message: isUpload ? AppStrings.uploadTimeout : AppStrings.networkTimeout,
        statusCode: error.response?.statusCode,
        code: 'TIMEOUT',
      );
    }
    if (error.type == DioExceptionType.badResponse) {
      return ApiException(
        message: AppStrings.requestFailed,
        statusCode: error.response?.statusCode,
        code: 'SERVER_ERROR',
      );
    }
    return ApiException(
      message: AppStrings.networkError,
      statusCode: error.response?.statusCode,
      code: 'NETWORK_ERROR',
    );
  }

  ApiException _fromEnvelope(
    Map<String, dynamic> body,
    int? statusCode, {
    bool hadBearer = false,
  }) {
    final error = body['error'];
    final code = error is Map<String, dynamic> ? error['code'] as String? : null;
    if (code == 'ACCOUNT_INACTIVE') {
      onAccountInactive?.call();
    } else if (statusCode == 401 &&
        hadBearer &&
        code != 'INVALID_CREDENTIALS') {
      _notifySessionExpired();
    }
    return ApiException(
      message: body['message'] as String? ?? AppStrings.requestFailed,
      code: code,
      details: error is Map<String, dynamic> ? error['details'] : null,
      statusCode: statusCode,
    );
  }

  bool _requestHadBearer(RequestOptions? options) {
    if (options == null) {
      return false;
    }
    final header = options.headers['Authorization']?.toString() ?? '';
    return header.startsWith('Bearer ') && header.length > 7;
  }

  void _notifySessionExpired() {
    if (_sessionExpiredNotified) {
      return;
    }
    _sessionExpiredNotified = true;
    onSessionExpired?.call();
  }

  /// Call after a successful login so a later displace can notify again.
  void resetSessionExpiredGuard() {
    _sessionExpiredNotified = false;
  }

  void close() => _dio.close();
}
