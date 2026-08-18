import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/app_strings.dart';
import '../../core/errors/app_error.dart';
import '../../core/models/category.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/validators/validators.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';
import 'category_service.dart';

class CategoryFormScreen extends StatefulWidget {
  final String? companyId;
  final Category? category;

  const CategoryFormScreen({super.key, this.companyId, this.category});

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
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
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final service = CategoryService(context.read<ApiClient>());
    try {
      if (_isEditing) {
        await service.update(widget.category!.id, _nameController.text.trim());
      } else {
        await service.create(
          _nameController.text.trim(),
          widget.companyId!,
        );
      }
      if (mounted) context.pop();
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? AppStrings.editCategory : AppStrings.newCategory,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                controller: _nameController,
                label: AppStrings.nameLabel,
                validator: requiredValidator,
              ),
              const SizedBox(height: 24),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(_error!, style: AppTextStyles.error),
                ),
              AppButton(
                label: _isEditing ? AppStrings.save : AppStrings.create,
                isLoading: _isLoading,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}