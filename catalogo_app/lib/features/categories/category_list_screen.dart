import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/constants/app_strings.dart';
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
    await provider.delete(id);
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
              padding: const EdgeInsets.all(16),
              child: DropdownButtonFormField<String>(
                initialValue: _companyId,
                decoration: const InputDecoration(
                  labelText: AppStrings.companyLabel,
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
      );
    }
    return RefreshIndicator(
      onRefresh: () => context.read<CategoryProvider>().refresh(),
      child: ListView.separated(
        itemCount: categories.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final c = categories[index];
          return ListTile(
            leading: const Icon(Icons.category),
            title: Text(c.name),
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
          );
        },
      ),
    );
  }
}