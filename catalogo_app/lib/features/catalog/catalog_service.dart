import '../../core/api/api_client.dart';
import '../../core/models/public_catalog.dart';

class CatalogService {
  final ApiClient _apiClient;

  CatalogService(this._apiClient);

  Future<PublicCatalog> getCompanyCatalog(String companyId) async {
    final response = await _apiClient.dio.get("/catalog/$companyId");
    return PublicCatalog.fromJson(response.data);
  }

  Future<List<CatalogProduct>> getProducts(
    String companyId, {
    String? categoryId,
  }) async {
    final response = await _apiClient.dio.get(
      "/catalog/$companyId/products",
      queryParameters: {"categoryId": ?categoryId},
    );
    final List data = response.data;
    return data.map((json) => CatalogProduct.fromJson(json)).toList();
  }

  Future<CatalogProduct> getProduct(String companyId, String productId) async {
    final response =
        await _apiClient.dio.get("/catalog/$companyId/products/$productId");
    return CatalogProduct.fromJson(response.data);
  }
}