import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../categories/category_provider.dart';
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
  final _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    _searchController.clear();
    setState(() => _searchQuery = "");
    if (id != null) {
      context.read<ProductProvider>().loadForCompany(id);
      context.read<CategoryProvider>().loadForCompany(id);
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
          if (companies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) =>
                    setState(() => _searchQuery = value.trim().toLowerCase()),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: AppStrings.searchByKeyword,
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = "");
                          },
                        ),
                ),
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
    final filtered = _applySearch(products);
    if (filtered.isEmpty) {
      return const AppEmptyState(
        icon: Icons.search_off,
        title: AppStrings.noSearchResults,
      );
    }
    return RefreshIndicator(
      onRefresh: () => context.read<ProductProvider>().refresh(),
      child: ListView.separated(
        itemCount: filtered.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final p = filtered[index];
          return ListTile(
            leading: _buildThumbnail(p),
            title: Text(p.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p.code != null && p.code!.isNotEmpty)
                  Text(p.code!, style: Theme.of(context).textTheme.bodySmall),
                Text(
                  "${Currency.format(p.finalPrice)}"
                  "${p.discountPercentage > 0 ? " (${p.discountPercentage}% off)" : ""}",
                ),
              ],
            ),
            onTap: () async {
              final provider = context.read<ProductProvider>();
              await context.push("/products/${p.id}", extra: p);
              if (context.mounted) provider.refresh();
            },
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

  Widget _buildThumbnail(Product product) {
    final url = product.mainImageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 48,
        height: 48,
        child: url != null
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _imagePlaceholder(),
              )
            : _imagePlaceholder(),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: const Icon(Icons.shopping_bag, color: Colors.grey),
    );
  }

  List<Product> _applySearch(List<Product> products) {
    if (_searchQuery.isEmpty) return products;
    final categoryNames = {
      for (final c in context.read<CategoryProvider>().categories)
        c.id: c.name.toLowerCase(),
    };
    final query = _searchQuery;
    return products.where((p) {
      final categoryName =
          p.categoryId != null ? categoryNames[p.categoryId] : null;
      return p.name.toLowerCase().contains(query) ||
          (p.code != null && p.code!.toLowerCase().contains(query)) ||
          (categoryName != null && categoryName.contains(query));
    }).toList();
  }
}