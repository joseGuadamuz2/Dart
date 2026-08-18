class Product {
  final String id;
  final String name;
  final double price;
  final double discountPercentage;
  final bool isFeatured;
  final bool isAvailable;
  final String? description;
  final String? code;
  final String? companyId;
  final String? categoryId;
  final List<ProductImage> images;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.discountPercentage,
    required this.isFeatured,
    required this.isAvailable,
    this.description,
    this.code,
    this.companyId,
    this.categoryId,
    this.images = const [],
  });

  double get finalPrice => price * (1 - discountPercentage / 100);
  String? get mainImageUrl {
    for (final img in images) {
      if (img.isMain) return img.url;
    }
    return images.isNotEmpty ? images.first.url : null;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json["id"],
      name: json["name"] ?? "",
      price: _toDouble(json["price"]),
      discountPercentage: _toDouble(json["discountPercentage"]),
      isFeatured: json["isFeatured"] ?? false,
      isAvailable: json["isAvailable"] ?? true,
      description: json["description"],
      code: json["code"],
      companyId: json["companyId"],
      categoryId: json["categoryId"],
      images: (json["images"] as List? ?? [])
          .map((e) => ProductImage.fromJson(e))
          .toList(),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}

class ProductImage {
  final String id;
  final String url;
  final bool isMain;
  final int sortOrder;

  ProductImage({
    required this.id,
    required this.url,
    required this.isMain,
    this.sortOrder = 0,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json["id"],
      url: json["url"] ?? "",
      isMain: json["isMain"] ?? false,
      sortOrder: (json["sortOrder"] as num?)?.toInt() ?? 0,
    );
  }
}