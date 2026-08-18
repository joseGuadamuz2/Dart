import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import '../models/auth_user.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  bool _isAuthenticated = false;
  AuthUser? _user;

  AuthProvider(this._authService);

  bool get isAuthenticated => _isAuthenticated;
  AuthUser? get user => _user;

  Future<void> checkAuth() async {
    _isAuthenticated = await _authService.isLoggedIn();
    _user = await _authService.getStoredUser();
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    final user = await _authService.login(email, password);
    _isAuthenticated = user != null;
    _user = user;
    notifyListeners();
    return _isAuthenticated;
  }

  Future<void> logout() async {
    await _authService.logout();
    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  }
}