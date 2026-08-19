import '../../core/api/api_client.dart';
import '../../core/models/category.dart';
import '../../core/models/company.dart';
import '../../core/models/public_catalog.dart';
import '../categories/category_service.dart';

class AdminService {
  final ApiClient _apiClient;

  AdminService(this._apiClient);

  Future<List<Company>> listCompanies() async {
    final response = await _apiClient.dio.get("/admin/companies");
    final data = ApiClient.extractList(response.data);
    return data.map((json) => Company.fromJson(json)).toList();
  }

  Future<List<Map<String, dynamic>>> listUsers() async {
    final response = await _apiClient.dio.get("/admin/users");
    final data = ApiClient.extractList(response.data);
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post("/admin/users", data: data);
    return Map<String, dynamic>.from(response.data);
  }

  Future<List<Map<String, dynamic>>> listLicenses() async {
    final response = await _apiClient.dio.get("/admin/licenses");
    final data = ApiClient.extractList(response.data);
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> createLicense(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post("/admin/licenses", data: data);
    return Map<String, dynamic>.from(response.data);
  }

  Future<List<Category>> catalogCategories(String companyId) async {
    final service = CategoryService(_apiClient);
    return service.findByCompany(companyId);
  }

  Future<PublicCatalog> catalog(String companyId) async {
    final response = await _apiClient.dio.get("/catalog/$companyId");
    return PublicCatalog.fromJson(response.data);
  }
}