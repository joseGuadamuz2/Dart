import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/models/company.dart';

class CompanyService {
  final ApiClient _apiClient;

  CompanyService(this._apiClient);

  Future<List<Company>> findMyCompanies() async {
    final response = await _apiClient.dio.get("/owner/companies");
    final data = ApiClient.extractList(response.data);
    return data.map((json) => Company.fromJson(json)).toList();
  }

  Future<Company> create(
    String name,
    String whatsappNumber, {
    String? logoUrl,
  }) async {
    final response = await _apiClient.dio.post(
      "/owner/companies",
      data: {
        "name": name,
        "whatsappNumber": whatsappNumber,
        "logoUrl": ?logoUrl,
      },
    );
    return Company.fromJson(response.data);
  }

  Future<Company> update(
    String id, {
    String? name,
    String? whatsappNumber,
    bool? isEnabled,
    String? logoUrl,
    bool removeLogo = false,
  }) async {
    final response = await _apiClient.dio.patch(
      "/owner/companies/$id",
      data: {
        "name": ?name,
        "whatsappNumber": ?whatsappNumber,
        "isEnabled": ?isEnabled,
        if (removeLogo) "logoUrl": null else "logoUrl": ?logoUrl,
      },
    );
    return Company.fromJson(response.data);
  }

  Future<void> delete(String id) async {
    await _apiClient.dio.delete("/owner/companies/$id");
  }

  Future<String> uploadImage(Uint8List bytes, String filename) async {
    final formData = FormData.fromMap({
      "file": MultipartFile.fromBytes(bytes, filename: filename),
    });
    final response = await _apiClient.dio.post(
      "/owner/upload/image",
      data: formData,
    );
    return response.data["url"];
  }
}