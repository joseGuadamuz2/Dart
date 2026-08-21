import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/validators/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';

class ProductPriceSection extends StatelessWidget {
  final TextEditingController priceController;
  final TextEditingController discountController;

  const ProductPriceSection({
    super.key,
    required this.priceController,
    required this.discountController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: priceController,
          label: AppStrings.priceLabel,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: positiveNumberValidator,
          prefixIcon: const SizedBox(
            width: 48,
            child: Center(
              child: Text(
                Currency.symbol,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: discountController,
          label: AppStrings.discountLabel,
          keyboardType: TextInputType.number,
          validator: rangeNumberValidator(0, 100),
        ),
      ],
    );
  }
}