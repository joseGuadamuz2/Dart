class CatalogProduct {
  final String id;
  final String code;
  final String name;
  final String? description;
  final String? imageUrl;
  final List<ProductImage> images;
  final double price;
  final double discountPercentage;
  final double finalPrice;
  final bool isFeatured;
  final bool isAvailable;
  final CategoryInfo? category;
  final String whatsappLink;

  CatalogProduct({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.imageUrl,
    this.images = const [],
    required this.price,
    required this.discountPercentage,
    required this.finalPrice,
    required this.isFeatured,
    this.isAvailable = true,
    this.category,
    required this.whatsappLink,
  });

  factory CatalogProduct.fromJson(Map<String, dynamic> json) {
    return CatalogProduct(
      id: json["id"],
      code: json["code"] ?? "",
      name: json["name"] ?? "",
      description: json["description"],
      imageUrl: json["imageUrl"],
      images: (json["images"] as List? ?? [])
          .map((e) => ProductImage.fromJson(e))
          .toList(),
      price: (json["price"] as num).toDouble(),
      discountPercentage:
          (json["discountPercentage"] as num?)?.toDouble() ?? 0,
      finalPrice: (json["finalPrice"] as num?)?.toDouble() ?? 0,
      isFeatured: json["isFeatured"] ?? false,
      isAvailable: json["isAvailable"] ?? true,
      category: json["category"] != null
          ? CategoryInfo.fromJson(json["category"])
          : null,
      whatsappLink: json["whatsappLink"] ?? "",
    );
  }
}

class ProductImage {
  final String id;
  final String url;
  final bool isMain;

  ProductImage({required this.id, required this.url, required this.isMain});

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json["id"],
      url: json["url"] ?? "",
      isMain: json["isMain"] ?? false,
    );
  }
}

class CategoryInfo {
  final String id;
  final String name;

  CategoryInfo({required this.id, required this.name});

  factory CategoryInfo.fromJson(Map<String, dynamic> json) {
    return CategoryInfo(
      id: json["id"],
      name: json["name"] ?? "",
    );
  }
}

class PublicCatalog {
  final PublicCompany company;
  final List<CatalogProduct> featured;
  final List<CategoryInfo> categories;

  PublicCatalog({
    required this.company,
    required this.featured,
    required this.categories,
  });

  factory PublicCatalog.fromJson(Map<String, dynamic> json) {
    return PublicCatalog(
      company: PublicCompany.fromJson(json["company"]),
      featured: (json["featured"] as List? ?? [])
          .map((e) => CatalogProduct.fromJson(e))
          .toList(),
      categories: (json["categories"] as List? ?? [])
          .map((e) => CategoryInfo.fromJson(e))
          .toList(),
    );
  }
}

class PublicCompany {
  final String id;
  final String name;
  final String whatsappNumber;
  final String? logoUrl;

  PublicCompany({
    required this.id,
    required this.name,
    required this.whatsappNumber,
    this.logoUrl,
  });

  factory PublicCompany.fromJson(Map<String, dynamic> json) {
    return PublicCompany(
      id: json["id"],
      name: json["name"] ?? "",
      whatsappNumber: json["whatsappNumber"] ?? "",
      logoUrl: json["logoUrl"],
    );
  }
}