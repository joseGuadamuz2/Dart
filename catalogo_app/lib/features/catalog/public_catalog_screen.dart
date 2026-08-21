import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/errors/app_error.dart';
import '../../core/models/public_catalog.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_empty_state.dart';
import '../../shared/widgets/app_error_view.dart';
import '../../shared/widgets/skeleton.dart';
import 'catalog_service.dart';

class PublicCatalogScreen extends StatefulWidget {
  final String companyId;
  final String? companyName;

  const PublicCatalogScreen({
    super.key,
    required this.companyId,
    this.companyName,
  });

  @override
  State<PublicCatalogScreen> createState() => _PublicCatalogScreenState();
}

class _PublicCatalogScreenState extends State<PublicCatalogScreen> {
  late Future<PublicCatalog> _future;
  String? _categoryId;
  late Future<List<CatalogProduct>> _productsFuture;
  final _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    final service = CatalogService(context.read<ApiClient>());
    _future = service.getCompanyCatalog(widget.companyId);
    _productsFuture = service.getProducts(widget.companyId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectCategory(String? categoryId) {
    setState(() {
      _categoryId = categoryId;
      _productsFuture = CatalogService(context.read<ApiClient>())
          .getProducts(widget.companyId, categoryId: categoryId);
    });
  }

  Future<void> _openPdf() async {
    final uri =
        Uri.parse("${ApiClient.baseUrl}/catalog/${widget.companyId}/pdf");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo abrir el PDF")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<PublicCatalog>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _CatalogSkeleton();
          }
          if (snapshot.hasError) {
            return AppErrorView(
              message: AppError.from(snapshot.error!).message,
            );
          }
          final catalog = snapshot.data!;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                title: Text(widget.companyName ?? "Catálogo"),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf),
                    tooltip: AppStrings.downloadPdf,
                    onPressed: _openPdf,
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BrandHeader(company: catalog.company),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _searchController,
                        onChanged: (value) =>
                            setState(() => _searchQuery = value.trim()),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: AppStrings.searchProducts,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: const Text(AppStrings.all),
                              selected: _categoryId == null,
                              onSelected: (_) => _selectCategory(null),
                            ),
                            for (final c in catalog.categories)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: ChoiceChip(
                                  label: Text(c.name),
                                  selected: _categoryId == c.id,
                                  onSelected: (_) => _selectCategory(c.id),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              FutureBuilder<List<CatalogProduct>>(
                future: _productsFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(child: _ProductsSkeleton());
                  }
                  if (snap.hasError) {
                    return SliverToBoxAdapter(
                      child: AppErrorView(
                        message: AppError.from(snap.error!).message,
                      ),
                    );
                  }
                  var products = snap.data ?? [];
                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    products = products
                        .where((p) => p.name.toLowerCase().contains(q))
                        .toList();
                  }
                  if (products.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: AppEmptyState(
                        icon: Icons.shopping_bag,
                        title: AppStrings.noProducts,
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 240,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.62,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _ProductCard(
                          companyId: widget.companyId,
                          product: products[index],
                        ),
                        childCount: products.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  final PublicCompany company;

  const _BrandHeader({required this.company});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryGradientTop, AppColors.primaryGradientBottom],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: (company.logoUrl != null && company.logoUrl!.isNotEmpty)
                  ? Image.network(
                      company.logoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(Icons.storefront,
                          size: 30, color: Colors.white),
                    )
                  : const Icon(Icons.storefront,
                      size: 30, color: Colors.white),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (company.whatsappNumber.isNotEmpty)
                  Text(
                    "WhatsApp: ${company.whatsappNumber}",
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogSkeleton extends StatelessWidget {
  const _CatalogSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Row(
          children: [
            Skeleton(
              width: 60,
              height: 60,
              borderRadius: BorderRadius.all(Radius.circular(30)),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton(width: 160, height: 20),
                  SizedBox(height: 8),
                  Skeleton(width: 120, height: 14),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Skeleton(height: 48),
        const SizedBox(height: 16),
        const _ProductsSkeleton(),
      ],
    );
  }
}

class _ProductsSkeleton extends StatelessWidget {
  const _ProductsSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Skeleton(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
            SizedBox(height: 8),
            Skeleton(height: 14),
            SizedBox(height: 6),
            Skeleton(width: 90, height: 12),
            SizedBox(height: 8),
            Skeleton(width: 70, height: 16),
          ],
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String companyId;
  final CatalogProduct product;

  const _ProductCard({required this.companyId, required this.product});

  Future<void> _openWhatsApp(BuildContext context, String link) async {
    final uri = Uri.parse(link);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo abrir el enlace")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDiscount = product.discountPercentage > 0;
    final image = product.imageUrl;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(
          "/public-catalog/$companyId/products/${product.id}",
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (image != null)
                    Image.network(
                      image,
                      fit: BoxFit.cover,
                      cacheWidth: 512,
                      errorBuilder: (_, _, _) =>
                          const _ImagePlaceholder(icon: Icons.broken_image),
                    )
                  else
                    const _ImagePlaceholder(icon: Icons.shopping_bag),
                  if (hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "-${product.discountPercentage.round()}%",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  if (!product.isAvailable)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black54,
                        child: const Center(
                          child: Text(
                            AppStrings.outOfStock,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (product.code.isNotEmpty)
                    Text(
                      product.code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                    ),
                  if (product.category != null)
                    Text(
                      product.category!.name,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          Currency.format(product.finalPrice),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: hasDiscount
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            Currency.format(product.price),
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (product.whatsappLink.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          visualDensity: VisualDensity.compact,
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                        onPressed: () =>
                            _openWhatsApp(context, product.whatsappLink),
                        icon: const Icon(Icons.chat, size: 18),
                        label: const Text(AppStrings.consultWhatsApp),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          visualDensity: VisualDensity.compact,
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                        onPressed: () {
                          Share.share(
                            AppStrings.shareProductText
                                .replaceFirst("{name}", product.name)
                                .replaceFirst(
                                  "{url}",
                                  ApiClient.productUrl(
                                    companyId,
                                    product.id,
                                  ),
                                ),
                          );
                        },
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text(AppStrings.share),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final IconData icon;

  const _ImagePlaceholder({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceMuted,
      child: Center(
        child: Icon(icon, size: 48, color: AppColors.textMuted),
      ),
    );
  }
}