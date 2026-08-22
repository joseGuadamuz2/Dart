import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';
import '../errors/app_error.dart';

class ApiClient {
  static String get baseUrl => dotenv.env['API_URL'] ?? "http://localhost:3000";

  static String get publicCatalogBaseUrl =>
      dotenv.env['PUBLIC_CATALOG_URL'] ?? baseUrl;

  static String catalogUrl(String companyId) =>
      "$publicCatalogBaseUrl/#/public-catalog/$companyId";

  static String productUrl(String companyId, String productId) =>
      "$publicCatalogBaseUrl/#/public-catalog/$companyId/products/$productId";

  static List<dynamic> extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data["data"] is List) return data["data"] as List;
    return const [];
  }

  final Dio dio;
  final _storage = const FlutterSecureStorage();

  void Function()? onUnauthorized;
  void Function(DioException error, String message)? onError;

  Future<String>? _refreshFuture;

  ApiClient() : dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 90),
          sendTimeout: const Duration(seconds: 120),
        ),
      ) {
    dio.interceptors.add(_RetryInterceptor(dio));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: StorageKeys.token);
          if (token != null) {
            options.headers["Authorization"] = "Bearer $token";
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          final status = error.response?.statusCode;
          final path = error.requestOptions.path;
          final isAuthEndpoint =
              path == "/auth/login" || path == "/auth/refresh";
          if (status != 401 || isAuthEndpoint) {
            _reportError(error);
            return handler.next(error);
          }
          if (error.requestOptions.extra['_retried'] == true) {
            _reportError(error);
            onUnauthorized?.call();
            return handler.next(error);
          }
          try {
            await refreshSession();
          } catch (_) {
            _reportError(error);
            onUnauthorized?.call();
            return handler.next(error);
          }
          try {
            final opts = error.requestOptions;
            opts.extra['_retried'] = true;
            final retry = await dio.fetch(opts);
            return handler.resolve(retry);
          } on DioException catch (retryError) {
            if (retryError.response?.statusCode == 401) {
              onUnauthorized?.call();
            }
            _reportError(retryError);
            return handler.next(retryError);
          }
        },
      ),
    );
  }

  void _reportError(DioException error) {
    final message = AppError.from(error).message;
    if (kDebugMode) {
      debugPrint(
        "[API] ${error.requestOptions.method} ${error.requestOptions.uri} "
        "-> ${error.response?.statusCode ?? error.type.name}",
      );
    }
    onError?.call(error, message);
  }

  Future<String> refreshSession() {
    return _refreshFuture ??=
        _doRefresh().whenComplete(() => _refreshFuture = null);
  }

  Future<String> _doRefresh() async {
    final refreshToken = await _storage.read(key: StorageKeys.refreshToken);
    if (refreshToken == null) {
      throw DioException(
        requestOptions: RequestOptions(path: "/auth/refresh"),
        message: "No hay refresh token",
      );
    }
    final response = await dio.post(
      "/auth/refresh",
      data: {"refreshToken": refreshToken},
    );
    final accessToken = response.data["accessToken"] as String;
    final newRefreshToken = response.data["refreshToken"] as String;
    await _storage.write(key: StorageKeys.token, value: accessToken);
    await _storage.write(
      key: StorageKeys.refreshToken,
      value: newRefreshToken,
    );
    final user = response.data["user"];
    if (user is Map) {
      await _storage.write(key: StorageKeys.user, value: jsonEncode(user));
    }
    return accessToken;
  }
}

class _RetryInterceptor extends Interceptor {
  _RetryInterceptor(this._dio);

  final Dio _dio;

  static const _maxAttempts = 2;
  static const _delay = Duration(seconds: 2);

  bool _isRetryable(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return error.requestOptions.method.toUpperCase() == "GET";
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode ?? 0;
        return status == 502 || status == 503 || status == 504;
      default:
        return false;
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final attempt = options.extra["_retryCount"] as int? ?? 0;
    if (options.method.toUpperCase() != "GET" ||
        attempt >= _maxAttempts ||
        !_isRetryable(err)) {
      return handler.next(err);
    }
    options.extra["_retryCount"] = attempt + 1;
    await Future<void>.delayed(_delay);
    try {
      final response = await _dio.fetch(options);
      return handler.resolve(response);
    } on DioException catch (retryError) {
      return handler.next(retryError);
    }
  }
}