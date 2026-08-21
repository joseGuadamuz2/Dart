abstract final class StorageKeys {
  static const String token = "jwt_token";
  static const String refreshToken = "jwt_refresh_token";
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
  static final RegExp whatsappLocal = RegExp(r"^\d{8}$");
  static final RegExp email = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$");
}

abstract final class Currency {
  static const String symbol = "₡";

  static String format(double value) {
    final parts = value.toStringAsFixed(2).split(".");
    final grouped = _groupThousands(parts[0]);
    final hasCents = parts[1] != "00";
    return hasCents ? "$symbol$grouped.${parts[1]}" : "$symbol$grouped";
  }

  static String _groupThousands(String digits) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      final remaining = digits.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) buffer.write(" ");
    }
    return buffer.toString();
  }
}

abstract final class PaginationDefaults {
  static const int pageSize = 50;
}