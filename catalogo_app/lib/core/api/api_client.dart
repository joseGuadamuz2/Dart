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
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
        ),
      ) {
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