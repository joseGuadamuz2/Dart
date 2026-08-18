class Category {
  final String id;
  final String name;
  final String companyId;

  Category({
    required this.id,
    required this.name,
    required this.companyId,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json["id"],
      name: json["name"] ?? "",
      companyId: json["companyId"] ?? "",
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "companyId": companyId,
      };
}