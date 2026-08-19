import 'package:flutter/foundation.dart';

import '../../core/errors/app_error.dart';
import 'product_model.dart';
import 'product_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _service;

  String? _companyId;
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;

  ProductProvider(this._service);

  String? get companyId => _companyId;
  List<Product> get products => List.unmodifiable(_products);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadForCompany(
    String companyId, {
    bool forceRefresh = false,
  }) async {
    if (_isLoading) return;
    if (_companyId == companyId &&
        _products.isNotEmpty &&
        !forceRefresh) {
      return;
    }
    _companyId = companyId;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final all = await _service.getProducts(companyId);
      _products = all.where((p) => p.companyId == companyId).toList();
    } catch (e) {
      _error = AppError.from(e).message;
    }
    _isLoading = false;
    notifyListeners();
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