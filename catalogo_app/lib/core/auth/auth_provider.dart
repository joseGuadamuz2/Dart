import 'package:flutter/foundation.dart';

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

  Future<void> checkAuth() async {
    _isAuthenticated = await _authService.isLoggedIn();
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