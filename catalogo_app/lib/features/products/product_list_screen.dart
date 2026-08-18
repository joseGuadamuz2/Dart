import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/constants/app_strings.dart';
import '../companies/company_provider.dart';
import '../products/product_model.dart';
import '../products/product_provider.dart';
import '../../shared/widgets/app_dialog.dart';
import '../../shared/widgets/app_empty_state.dart';
import '../../shared/widgets/app_error_view.dart';
import '../../shared/widgets/app_loading.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key, this.initialCompanyId});

  final String? initialCompanyId;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
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
      context.read<ProductProvider>().loadForCompany(id);
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final provider = context.read<ProductProvider>();
    final confirmed = await confirmAction(
      context,
      title: AppStrings.deleteProductTitle,
      message: AppStrings.deleteProductMessage,
    );
    if (!confirmed) return;
    await provider.delete(product.id);
  }

  @override
  Widget build(BuildContext context) {
    final companyProvider = context.watch<CompanyProvider>();
    final companies = companyProvider.companies;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.productsTitle),
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
                final provider = context.read<ProductProvider>();
                await context.push("/products/new", extra: _companyId);
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
        icon: Icons.shopping_bag,
        title: AppStrings.selectCompany,
      );
    }

    final productProvider = context.watch<ProductProvider>();
    if (productProvider.isLoading && productProvider.products.isEmpty) {
      return const AppLoading();
    }
    if (productProvider.error != null && productProvider.products.isEmpty) {
      return AppErrorView(
        message: productProvider.error!,
        onRetry: () => _selectCompany(_companyId),
      );
    }
    final products = productProvider.products;
    if (products.isEmpty) {
      return const AppEmptyState(
        icon: Icons.shopping_bag,
        title: AppStrings.noProducts,
      );
    }
    return RefreshIndicator(
      onRefresh: () => context.read<ProductProvider>().refresh(),
      child: ListView.separated(
        itemCount: products.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final p = products[index];
          return ListTile(
            leading: const Icon(Icons.shopping_bag),
            title: Text(p.name),
            subtitle: Text(
              "\$${p.finalPrice.toStringAsFixed(2)}"
              "${p.discountPercentage > 0 ? " (${p.discountPercentage}% off)" : ""}",
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == "edit") {
                  final provider = context.read<ProductProvider>();
                  await context.push("/products/${p.id}/edit", extra: p);
                  if (context.mounted) provider.refresh();
                } else if (value == "delete") {
                  await _deleteProduct(p);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: "edit",
                  child: Text(AppStrings.edit),
                ),
                const PopupMenuItem(
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