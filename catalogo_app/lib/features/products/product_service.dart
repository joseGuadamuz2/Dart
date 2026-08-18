import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/models/category.dart';
import 'product_model.dart';

class ProductService {
  final ApiClient _apiClient;

  ProductService(this._apiClient);

  Future<List<Product>> getProducts(String companyId) async {
    final response = await _apiClient.dio.get(
      "/owner/products",
      queryParameters: {"companyId": companyId},
    );
    final List data = response.data;
    return data.map((json) => Product.fromJson(json)).toList();
  }

  Future<Product> getProduct(String id) async {
    final response = await _apiClient.dio.get("/owner/products/$id");
    return Product.fromJson(response.data);
  }

  Future<Product> create(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post("/owner/products", data: data);
    return Product.fromJson(response.data);
  }

  Future<Product> update(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.patch("/owner/products/$id", data: data);
    return Product.fromJson(response.data);
  }

  Future<void> delete(String id) async {
    await _apiClient.dio.delete("/owner/products/$id");
  }

  Future<Product> addImage(String productId, String url) async {
    await _apiClient.dio.post(
      "/owner/products/$productId/images",
      data: {"url": url},
    );
    return getProduct(productId);
  }

  Future<Product> setMainImage(String productId, String imageId) async {
    await _apiClient.dio.patch(
      "/owner/products/$productId/images/$imageId/main",
    );
    return getProduct(productId);
  }

  Future<Product> removeImage(String productId, String imageId) async {
    await _apiClient.dio.delete(
      "/owner/products/$productId/images/$imageId",
    );
    return getProduct(productId);
  }

  Future<List<Category>> getCategories(String companyId) async {
    final response = await _apiClient.dio.get(
      "/owner/categories",
      queryParameters: {"companyId": companyId},
    );
    final List data = response.data;
    return data.map((json) => Category.fromJson(json)).toList();
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