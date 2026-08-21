import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/app_strings.dart';
import '../../core/errors/app_error.dart';
import '../../core/models/category.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/validators/validators.dart';
import 'category_service.dart';

Future<Category?> showCategoryFormDialog(
  BuildContext context, {
  required ApiClient apiClient,
  required String companyId,
  Category? category,
}) {
  return showDialog<Category>(
    context: context,
    builder: (_) => _CategoryFormDialog(
      apiClient: apiClient,
      companyId: companyId,
      category: category,
    ),
  );
}

class _CategoryFormDialog extends StatefulWidget {
  final ApiClient apiClient;
  final String companyId;
  final Category? category;

  const _CategoryFormDialog({
    required this.apiClient,
    required this.companyId,
    this.category,
  });

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  late final TextEditingController _nameController;
  bool _isLoading = false;
  String? _error;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? "");
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isLoading) return;
    setState(() => _error = null);
    final name = _nameController.text.trim();
    final validationError = requiredMaxLengthValidator(100)(name);
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final service = CategoryService(widget.apiClient);
      final result = _isEditing
          ? await service.update(widget.category!.id, name)
          : await service.create(name, widget.companyId);
      if (mounted) Navigator.of(context).pop(result);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = AppError.from(e).message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? AppStrings.editCategory : AppStrings.newCategory),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: AppStrings.nameLabel),
            autofocus: true,
            onFieldSubmitted: (_) => _save(),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: AppTextStyles.error),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditing ? AppStrings.save : AppStrings.create),
        ),
      ],
    );
  }
}

Future<Category?> showCategoryPickerDialog(
  BuildContext context, {
  required List<Category> categories,
}) {
  return showDialog<Category>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: const Text(AppStrings.editCategory),
      children: [
        for (final category in categories)
          SimpleDialogOption(
            onPressed: () => Navigator.of(dialogContext).pop(category),
            child: Row(
              children: [
                Expanded(child: Text(category.name)),
                const Icon(Icons.edit_outlined, size: 20),
              ],
            ),
          ),
      ],
    ),
  );
}
