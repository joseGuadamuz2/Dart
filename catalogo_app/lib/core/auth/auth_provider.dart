import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../errors/app_error.dart';
import '../models/auth_user.dart';
import 'auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  bool _isAuthenticated = false;
  AuthUser? _user;
  String? _error;

  AuthProvider(this._authService);

  bool get isAuthenticated => _isAuthenticated;
  AuthUser? get user => _user;
  String? get error => _error;

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  bool _isExpired(String token) {
    try {
      return JwtDecoder.isExpired(token);
    } catch (_) {
      return true;
    }
  }

  Future<void> checkAuth() async {
    final token = await _authService.getStoredToken();
    if (token == null || _isExpired(token)) {
      if (token == null || !await _authService.refreshSession()) {
        await _authService.logout();
        _isAuthenticated = false;
        _user = null;
        notifyListeners();
        return;
      }
    }
    _isAuthenticated = true;
    _user = await _authService.getStoredUser();
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _error = null;
    try {
      final user = await _authService.login(email, password);
      _isAuthenticated = user != null;
      _user = user;
    } on AppError catch (e) {
      _error = e.message;
    } catch (e) {
      _error = AppError.from(e).message;
    }
    notifyListeners();
    return _isAuthenticated;
  }

  Future<void> logout() async {
    await _authService.logout();
    _isAuthenticated = false;
    _user = null;
    _error = null;
    notifyListeners();
  }
}