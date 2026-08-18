import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_client.dart';
import '../models/auth_user.dart';

class AuthService {
  final ApiClient _apiClient;
  final _storage = const FlutterSecureStorage();

  AuthService(this._apiClient);

  Future<AuthUser?> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        "/auth/login",
        data: {"email": email, "password": password},
      );

      final token = response.data["accessToken"];
      final user = AuthUser.fromJson(response.data["user"]);

      await _storage.write(key: "jwt_token", value: token);
      await _storage.write(
        key: "jwt_user",
        value: jsonEncode(user.toJson()),
      );
      return user;
    } on DioException catch (_) {
      return null;
    }
  }

  Future<AuthUser?> getStoredUser() async {
    final raw = await _storage.read(key: "jwt_user");
    if (raw == null) return null;
    try {
      return AuthUser.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: "jwt_token");
    await _storage.delete(key: "jwt_user");
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: "jwt_token");
    return token != null;
  }
}