import '../constants/app_constants.dart';
import '../constants/app_strings.dart';

String? requiredValidator(String? value) =>
    value == null || value.trim().isEmpty ? AppStrings.requiredField : null;

String? numberValidator(String? value) {
  if (value == null || value.trim().isEmpty) return AppStrings.requiredField;
  if (double.tryParse(value.trim()) == null) return AppStrings.invalidValue;
  return null;
}

String? whatsappValidator(String? value) {
  if (value == null || value.trim().isEmpty) return AppStrings.requiredField;
  if (!Validators.whatsapp.hasMatch(value.trim())) {
    return AppStrings.whatsappInvalid;
  }
  return null;
}