import 'package:image_picker/image_picker.dart';

import '../../core/api/api_client.dart';
import '../../features/products/product_service.dart';

class ImagePickerService {
  final ProductService _productService;

  ImagePickerService() : _productService = ProductService(ApiClient());

  Future<XFile?> pickImage() {
    return ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );
  }

  Future<String> pickAndUpload() async {
    final file = await pickImage();
    if (file == null) throw ImagePickCancelled();

    final bytes = await file.readAsBytes();
    return _productService.uploadImage(bytes, file.name);
  }
}

class ImagePickCancelled implements Exception {
  @override
  String toString() => 'Selección de imagen cancelada';
}