import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/constants/app_strings.dart';
import '../../core/errors/app_error.dart';
import '../../core/theme/app_colors.dart';
import '../companies/company_provider.dart';
import '../categories/category_provider.dart';
import '../../shared/widgets/app_dialog.dart';
import '../../shared/widgets/app_empty_state.dart';
import '../../shared/widgets/app_error_view.dart';
import '../../shared/widgets/app_loading.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key, this.initialCompanyId});

  final String? initialCompanyId;

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  String? _companyId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final companyProvider = context.read<CompanyProvider>();
    if (companyProvider.companies.isEmpty && !companyProvider.isLoading) {
      await companyProvider.load();
    }
    if (!mounted) return;
    final companies = companyProvider.companies;
    if (companies.isNotEmpty) {
      final id = widget.initialCompanyId != null &&
              companies.any((c) => c.id == widget.initialCompanyId)
          ? widget.initialCompanyId
          : companies.first.id;
      _selectCompany(id);
    }
  }

  void _selectCompany(String? id) {
    setState(() => _companyId = id);
    if (id != null) {
      context.read<CategoryProvider>().loadForCompany(id);
    }
  }

  Future<void> _deleteCategory(String id) async {
    final provider = context.read<CategoryProvider>();
    final confirmed = await confirmAction(
      context,
      title: AppStrings.deleteCategoryTitle,
      message: AppStrings.deleteCategoryMessage,
    );
    if (!confirmed) return;
    try {
      await provider.delete(id);
      if (mounted) {
        showAppSnackBar(context, AppStrings.deletedSuccessfully);
      }
    } catch (e) {
      if (mounted) showAppSnackBar(context, AppError.from(e).message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyProvider = context.watch<CompanyProvider>();
    final companies = companyProvider.companies;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.categoriesTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: AppStrings.logout,
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (companies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: DropdownButtonFormField<String>(
                initialValue: _companyId,
                decoration: const InputDecoration(
                  labelText: AppStrings.companyLabel,
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
                items: companies
                    .map((c) =>
                        DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: _selectCompany,
              ),
            ),
          Expanded(child: _buildBody(companyProvider)),
        ],
      ),
      floatingActionButton: _companyId == null
          ? null
          : FloatingActionButton(
              onPressed: () async {
                final provider = context.read<CategoryProvider>();
                await context.push("/categories/new", extra: _companyId);
                if (context.mounted) provider.refresh();
              },
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildBody(CompanyProvider companyProvider) {
    if (companyProvider.isLoading && companyProvider.companies.isEmpty) {
      return const AppLoading();
    }
    if (companyProvider.companies.isEmpty) {
      if (companyProvider.error != null) {
        return AppErrorView(message: companyProvider.error!, onRetry: _init);
      }
      return const AppEmptyState(
        icon: Icons.store,
        title: AppStrings.noCompanies,
      );
    }
    if (_companyId == null) {
      return const AppEmptyState(
        icon: Icons.category,
        title: AppStrings.selectCompany,
      );
    }

    final categoryProvider = context.watch<CategoryProvider>();
    if (categoryProvider.isLoading && categoryProvider.categories.isEmpty) {
      return const AppLoading();
    }
    if (categoryProvider.error != null &&
        categoryProvider.categories.isEmpty) {
      return AppErrorView(
        message: categoryProvider.error!,
        onRetry: () => _selectCompany(_companyId),
      );
    }
    final categories = categoryProvider.categories;
    if (categories.isEmpty) {
      return const AppEmptyState(
        icon: Icons.category,
        title: AppStrings.noCategories,
        message: AppStrings.noCategoriesHint,
      );
    }
    return RefreshIndicator(
      onRefresh: () => context.read<CategoryProvider>().refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final c = categories[index];
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.category,
                    color: AppColors.primary, size: 22),
              ),
              title: Text(
                c.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == "edit") {
                    final provider = context.read<CategoryProvider>();
                    await context.push("/categories/${c.id}/edit", extra: c);
                    if (context.mounted) provider.refresh();
                  } else if (value == "delete") {
                    await _deleteCategory(c.id);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: "edit",
                    child: Text(AppStrings.edit),
                  ),
                  PopupMenuItem(
                    value: "delete",
                    child: Text(AppStrings.delete),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}