import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static String get baseUrl => dotenv.env['API_URL'] ?? "http://localhost:3000";

  static String get publicCatalogBaseUrl =>
      dotenv.env['PUBLIC_CATALOG_URL'] ?? baseUrl;

  static String catalogUrl(String companyId) =>
      "$publicCatalogBaseUrl/#/public-catalog/$companyId";

  static String productUrl(String companyId, String productId) =>
      "$publicCatalogBaseUrl/#/public-catalog/$companyId/products/$productId";

  final Dio dio;
  final _storage = const FlutterSecureStorage();

  ApiClient() : dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: "jwt_token");
          if (token != null) {
            options.headers["Authorization"] = "Bearer $token";
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            // Token expirado o inválido: aquí podrías forzar logout
          }
          return handler.next(error);
        },
      ),
    );
  }
}