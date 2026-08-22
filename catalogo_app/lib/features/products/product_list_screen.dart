import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/errors/app_error.dart';
import '../../core/models/company.dart';
import '../../core/theme/app_colors.dart';
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
    try {
      await provider.delete(product.id);
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
          if (companies.isNotEmpty) _buildCompanySelector(companies),
          if (companies.isNotEmpty) _buildSearchField(),
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

  Widget _buildCompanySelector(List<Company> companies) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: DropdownButtonFormField<String>(
        initialValue: _companyId,
        decoration: const InputDecoration(
          labelText: AppStrings.companyLabel,
          prefixIcon: Icon(Icons.storefront_outlined),
        ),
        items: companies
            .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
            .toList(),
        onChanged: _selectCompany,
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) =>
            setState(() => _searchQuery = value.trim().toLowerCase()),
        decoration: InputDecoration(
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
        message: AppStrings.noProductsHint,
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
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final p = filtered[index];
          return _ProductCard(
            product: p,
            onTap: () async {
              final provider = context.read<ProductProvider>();
              await context.push("/products/${p.id}", extra: p);
              if (context.mounted) provider.refresh();
            },
            onEdit: () async {
              final provider = context.read<ProductProvider>();
              await context.push("/products/${p.id}/edit", extra: p);
              if (context.mounted) provider.refresh();
            },
            onDelete: () => _deleteProduct(p),
          );
        },
      ),
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

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = product.discountPercentage > 0;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _buildThumbnail(product),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.code != null && product.code!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(product.code!, style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    )),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        Currency.format(product.finalPrice),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 6),
                        Text(
                          Currency.format(product.price),
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.discountBadge,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "-${product.discountPercentage.round()}%",
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                      if (!product.isAvailable) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.dangerContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            AppStrings.outOfStock,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onDangerContainer,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == "edit") {
                  onEdit();
                } else if (value == "delete") {
                  onDelete();
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
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(Product product) {
    final url = product.mainImageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 64,
        height: 64,
        child: url != null
            ? Image.network(
                url,
                fit: BoxFit.cover,
                cacheWidth: 256,
                errorBuilder: (_, _, _) => _imagePlaceholder(),
              )
            : _imagePlaceholder(),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppColors.surfaceMuted,
      child: const Icon(Icons.image_outlined, color: AppColors.textMuted),
    );
  }
}