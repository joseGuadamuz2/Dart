import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/validators/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';

class ProductBasicInfo extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController codeController;
  final TextEditingController descriptionController;

  const ProductBasicInfo({
    super.key,
    required this.nameController,
    required this.codeController,
    required this.descriptionController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: nameController,
          label: AppStrings.nameLabel,
          validator: requiredMaxLengthValidator(100),
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: codeController,
          label: AppStrings.codeLabel,
          validator: (v) => maxLengthValidator(50, v),
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: descriptionController,
          label: AppStrings.descriptionLabel,
          maxLines: 3,
          validator: (v) => maxLengthValidator(500, v),
        ),
      ],
    );
  }
}