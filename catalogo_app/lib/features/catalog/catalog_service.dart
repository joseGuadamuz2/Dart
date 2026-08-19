import '../../core/api/api_client.dart';
import '../../core/models/public_catalog.dart';

class _CatalogCacheEntry {
  final Object value;
  final DateTime at;

  _CatalogCacheEntry(this.value, this.at);
}

class CatalogService {
  static const Duration _cacheTtl = Duration(seconds: 30);
  static final Map<String, _CatalogCacheEntry> _cache = {};

  final ApiClient _apiClient;

  CatalogService(this._apiClient);

  Future<PublicCatalog> getCompanyCatalog(String companyId) async {
    final key = "catalog:$companyId";
    final cached = _cache[key];
    if (cached != null &&
        DateTime.now().difference(cached.at) < _cacheTtl) {
      return cached.value as PublicCatalog;
    }
    final response = await _apiClient.dio.get("/catalog/$companyId");
    final catalog = PublicCatalog.fromJson(response.data);
    _cache[key] = _CatalogCacheEntry(catalog, DateTime.now());
    return catalog;
  }

  Future<List<CatalogProduct>> getProducts(
    String companyId, {
    String? categoryId,
    int? page,
    int? pageSize,
  }) async {
    final key = "products:$companyId:${categoryId ?? ""}";
    final cached = _cache[key];
    if (cached != null &&
        DateTime.now().difference(cached.at) < _cacheTtl) {
      return cached.value as List<CatalogProduct>;
    }
    final response = await _apiClient.dio.get(
      "/catalog/$companyId/products",
      queryParameters: {
        "categoryId": ?categoryId,
        "page": ?page,
        "pageSize": ?pageSize,
      },
    );
    final data = ApiClient.extractList(response.data)
        .map((json) => CatalogProduct.fromJson(json))
        .toList();
    _cache[key] = _CatalogCacheEntry(data, DateTime.now());
    return data;
  }

  Future<CatalogProduct> getProduct(String companyId, String productId) async {
    final response =
        await _apiClient.dio.get("/catalog/$companyId/products/$productId");
    return CatalogProduct.fromJson(response.data);
  }
}