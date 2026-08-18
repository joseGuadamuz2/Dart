import 'package:flutter/foundation.dart';

import '../../core/cache/cache_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_error.dart';
import '../../core/models/company.dart';
import 'company_service.dart';

class CompanyProvider extends ChangeNotifier {
  final CompanyService _service;
  final CacheService _cache;

  List<Company> _companies = [];
  bool _isLoading = false;
  String? _error;

  CompanyProvider(this._service, this._cache);

  List<Company> get companies => List.unmodifiable(_companies);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load({bool forceRefresh = false}) async {
    if (_isLoading) return;
    if (_companies.isNotEmpty && !forceRefresh) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _companies = await _service.findMyCompanies();
      await _cache.putJsonList(
        CacheKeys.companies,
        _companies.map((c) => c.toJson()).toList(),
      );
    } catch (e) {
      _error = AppError.from(e).message;
      _restoreFromCache();
    }
    _isLoading = false;
    notifyListeners();
  }

  void _restoreFromCache() {
    final cached = _cache.getJsonList(CacheKeys.companies);
    if (cached == null) return;
    _companies = cached
        .map((e) => Company.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> refresh() => load(forceRefresh: true);

  Future<void> delete(String id) async {
    await _service.delete(id);
    await refresh();
  }
}