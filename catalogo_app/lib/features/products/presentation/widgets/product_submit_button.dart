import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';

class ProductSubmitButton extends StatelessWidget {
  final bool isEditing;
  final bool isLoading;
  final String? error;
  final VoidCallback onPressed;

  const ProductSubmitButton({
    super.key,
    required this.isEditing,
    required this.isLoading,
    required this.error,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(error!, style: AppTextStyles.error),
          ),
        AppButton(
          label: isEditing ? AppStrings.save : AppStrings.create,
          isLoading: isLoading,
          onPressed: onPressed,
        ),
      ],
    );
  }
}