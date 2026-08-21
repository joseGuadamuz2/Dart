import '../constants/app_constants.dart';
import '../constants/app_strings.dart';

String? requiredValidator(String? value) =>
    value == null || value.trim().isEmpty ? AppStrings.requiredField : null;

String? numberValidator(String? value) {
  if (value == null || value.trim().isEmpty) return AppStrings.requiredField;
  if (double.tryParse(value.trim()) == null) return AppStrings.invalidValue;
  return null;
}

String? emailValidator(String? value) {
  if (value == null || value.trim().isEmpty) return AppStrings.requiredField;
  if (!Validators.email.hasMatch(value.trim())) {
    return AppStrings.emailInvalid;
  }
  return null;
}

String? maxLengthValidator(int maxLength, String? value) {
  if (value == null || value.trim().isEmpty) return null;
  if (value.trim().length > maxLength) {
    return AppStrings.fieldTooLong.replaceFirst("{n}", "$maxLength");
  }
  return null;
}

String? Function(String?) requiredMaxLengthValidator(int maxLength) {
  return (String? value) =>
      requiredValidator(value) ?? maxLengthValidator(maxLength, value);
}

String? positiveNumberValidator(String? value) {
  final number = double.tryParse((value ?? "").trim());
  if (number == null) return AppStrings.requiredField;
  if (number <= 0) return AppStrings.pricePositive;
  return null;
}

String? Function(String?) rangeNumberValidator(num min, num max) {
  return (String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final number = double.tryParse(value.trim());
    if (number == null) return AppStrings.invalidValue;
    if (number < min || number > max) return AppStrings.discountRange;
    return null;
  };
}

String? whatsappValidator(String? value) {
  if (value == null || value.trim().isEmpty) return AppStrings.requiredField;
  final v = value.trim();
  final isValid = Validators.whatsappLocal.hasMatch(v) ||
      Validators.whatsapp.hasMatch(v);
  if (!isValid) {
    return AppStrings.whatsappInvalid;
  }
  return null;
}

String normalizeWhatsapp(String value) {
  final v = value.trim();
  return Validators.whatsappLocal.hasMatch(v) ? "506$v" : v;
}

String displayWhatsapp(String value) {
  final v = value.trim();
  return Validators.whatsapp.hasMatch(v) ? v.substring(3) : v;
}

String formatWhatsapp(String value) {
  final v = value.trim();
  if (!Validators.whatsapp.hasMatch(v)) return v;
  return "+506 ${v.substring(3, 7)}-${v.substring(7)}";
}
