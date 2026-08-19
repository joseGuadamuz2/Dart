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
  if (!Validators.whatsapp.hasMatch(value.trim())) {
    return AppStrings.whatsappInvalid;
  }
  return null;
}
