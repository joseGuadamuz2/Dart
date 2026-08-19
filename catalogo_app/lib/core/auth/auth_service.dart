import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/api_client.dart';
import '../constants/app_constants.dart';
import '../models/auth_user.dart';

class AuthService {
  final ApiClient _apiClient;
  final _storage = const FlutterSecureStorage();

  AuthService(this._apiClient);

  Future<AuthUser?> login(String email, String password) async {
    final response = await _apiClient.dio.post(
      "/auth/login",
      data: {"email": email, "password": password},
    );

    final token = response.data["accessToken"];
    final refreshToken = response.data["refreshToken"];
    final user = AuthUser.fromJson(response.data["user"]);

    await _storage.write(key: StorageKeys.token, value: token);
    if (refreshToken != null) {
      await _storage.write(key: StorageKeys.refreshToken, value: refreshToken);
    }
    await _storage.write(
      key: StorageKeys.user,
      value: jsonEncode(user.toJson()),
    );
    return user;
  }

  Future<String?> getStoredToken() => _storage.read(key: StorageKeys.token);

  Future<bool> refreshSession() async {
    try {
      await _apiClient.refreshSession();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<AuthUser?> getStoredUser() async {
    final raw = await _storage.read(key: StorageKeys.user);
    if (raw == null) return null;
    try {
      return AuthUser.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: StorageKeys.token);
    await _storage.delete(key: StorageKeys.refreshToken);
    await _storage.delete(key: StorageKeys.user);
  }
}