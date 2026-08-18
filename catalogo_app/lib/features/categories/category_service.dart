import '../../core/api/api_client.dart';
import '../../core/models/category.dart';

class CategoryService {
  final ApiClient _apiClient;

  CategoryService(this._apiClient);

  Future<List<Category>> findByCompany(String companyId) async {
    final response = await _apiClient.dio.get(
      "/owner/categories",
      queryParameters: {"companyId": companyId},
    );
    final List data = response.data;
    return data.map((json) => Category.fromJson(json)).toList();
  }

  Future<Category> create(String name, String companyId) async {
    final response = await _apiClient.dio.post(
      "/owner/categories",
      data: {"name": name, "companyId": companyId},
    );
    return Category.fromJson(response.data);
  }

  Future<Category> update(String id, String name) async {
    final response = await _apiClient.dio.patch(
      "/owner/categories/$id",
      data: {"name": name},
    );
    return Category.fromJson(response.data);
  }

  Future<void> delete(String id) async {
    await _apiClient.dio.delete("/owner/categories/$id");
  }
}