class AuthUser {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String tenantId;

  AuthUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.tenantId,
  });

  String get fullName => "$firstName $lastName";

  bool get isAdmin => role == "ADMIN";
  bool get isOwner => role == "OWNER";

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json["id"],
      email: json["email"] ?? "",
      firstName: json["firstName"] ?? "",
      lastName: json["lastName"] ?? "",
      role: json["role"] ?? "OWNER",
      tenantId: json["tenantId"] ?? "",
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "email": email,
        "firstName": firstName,
        "lastName": lastName,
        "role": role,
        "tenantId": tenantId,
      };
}