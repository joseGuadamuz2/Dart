abstract final class StorageKeys {
  static const String token = "jwt_token";
  static const String user = "jwt_user";
}

abstract final class CacheKeys {
  static const String companies = "companies";
  static const String categoryPrefix = "categories_";
  static const String rememberedEmail = "remembered_email";

  static String categoriesFor(String companyId) =>
      "$categoryPrefix$companyId";
}

abstract final class Validators {
  static final RegExp whatsapp = RegExp(r"^506\d{8}$");
}

abstract final class Currency {
  static const String symbol = "₡";

  static String format(double value) => "$symbol${value.toStringAsFixed(2)}";
}

abstract final class PaginationDefaults {
  static const int pageSize = 50;
}