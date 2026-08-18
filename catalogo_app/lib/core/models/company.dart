class Company {
  final String id;
  final String name;
  final String whatsappNumber;
  final String? ownerId;
  final String? licenseId;
  final License? license;
  final bool isEnabled;

  Company({
    required this.id,
    required this.name,
    required this.whatsappNumber,
    this.ownerId,
    this.licenseId,
    this.license,
    this.isEnabled = true,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json["id"],
      name: json["name"] ?? "",
      whatsappNumber: json["whatsappNumber"] ?? "",
      ownerId: json["ownerId"],
      licenseId: json["licenseId"],
      license: json["license"] != null
          ? License.fromJson(json["license"])
          : null,
      isEnabled: json["isEnabled"] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        "name": name,
        "whatsappNumber": whatsappNumber,
      };
}

class License {
  final String id;
  final String name;
  final int maxCompanies;
  final int maxProducts;
  final DateTime? expiresAt;

  License({
    required this.id,
    required this.name,
    required this.maxCompanies,
    required this.maxProducts,
    this.expiresAt,
  });

  factory License.fromJson(Map<String, dynamic> json) {
    return License(
      id: json["id"],
      name: json["name"] ?? "",
      maxCompanies: (json["maxCompanies"] as num?)?.toInt() ?? 0,
      maxProducts: (json["maxProducts"] as num?)?.toInt() ?? 0,
      expiresAt: json["expiresAt"] != null
          ? DateTime.tryParse(json["expiresAt"])
          : null,
    );
  }
}