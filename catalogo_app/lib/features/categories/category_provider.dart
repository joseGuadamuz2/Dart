import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../../core/cache/cache_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_error.dart';
import '../../core/models/category.dart';
import 'category_service.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryService _service;
  final CacheService _cache;

  String? _companyId;
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  CategoryProvider(this._service, this._cache);

  String? get companyId => _companyId;
  List<Category> get categories => List.unmodifiable(_categories);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadForCompany(
    String companyId, {
    bool forceRefresh = false,
  }) async {
    if (_isLoading) return;
    if (_companyId == companyId &&
        _categories.isNotEmpty &&
        !forceRefresh) {
      return;
    }
    _companyId = companyId;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _categories = await _service.findByCompany(companyId);
      await _cache.putJsonList(
        CacheKeys.categoriesFor(companyId),
        _categories.map((c) => c.toJson()).toList(),
      );
    } catch (e) {
      _error = AppError.from(e).message;
      _restoreFromCache(companyId);
    }
    _isLoading = false;
    notifyListeners();
  }

  void _restoreFromCache(String companyId) {
    final cached = _cache.getJsonList(CacheKeys.categoriesFor(companyId));
    if (cached == null) return;
    _categories = cached
        .map((e) => Category.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> refresh() {
    final id = _companyId;
    if (id == null) return Future.value();
    return loadForCompany(id, forceRefresh: true);
  }

  Future<void> delete(String id) async {
    await _service.delete(id);
    await refresh();
  }
}