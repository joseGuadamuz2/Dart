import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/category.dart';
import '../../../../core/models/company.dart';

class ProductCategorySelector extends StatelessWidget {
  final List<Company> companies;
  final List<Category> categories;
  final String? companyId;
  final String? categoryId;
  final ValueChanged<String?> onCompanyChanged;
  final ValueChanged<String?> onCategoryChanged;

  const ProductCategorySelector({
    super.key,
    required this.companies,
    required this.categories,
    required this.companyId,
    required this.categoryId,
    required this.onCompanyChanged,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: companyId,
          decoration:
              const InputDecoration(labelText: AppStrings.companyLabel),
          items: companies
              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
              .toList(),
          onChanged: onCompanyChanged,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: categoryId,
          decoration:
              const InputDecoration(labelText: AppStrings.categoryLabel),
          items: categories
              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
              .toList(),
          onChanged: onCategoryChanged,
        ),
      ],
    );
  }
}