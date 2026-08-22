import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/errors/app_error.dart';
import '../../core/models/public_catalog.dart';
import '../../core/validators/validators.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_empty_state.dart';
import '../../shared/widgets/app_error_view.dart';
import '../../shared/widgets/skeleton.dart';
import '../../shared/widgets/whatsapp_button.dart';
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
                automaticallyImplyLeading: false,
                floating: true,
                title: Text(widget.companyName ?? AppStrings.catalogTitle),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    tooltip: AppStrings.downloadPdf,
                    onPressed: _openPdf,
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BrandHeader(company: catalog.company),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _searchController,
                        onChanged: (value) =>
                            setState(() => _searchQuery = value.trim()),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search,
                              size: 20, color: AppColors.textMuted),
                          suffixIcon: _searchQuery.isEmpty
                              ? null
                              : IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.close,
                                      size: 18, color: AppColors.textMuted),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = "");
                                  },
                                ),
                          hintText: AppStrings.searchProducts,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        clipBehavior: Clip.none,
                        child: Row(
                          children: [
                            _CategoryChip(
                              label: AppStrings.all,
                              selected: _categoryId == null,
                              onTap: () => _selectCategory(null),
                            ),
                            for (final c in catalog.categories)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: _CategoryChip(
                                  label: c.name,
                                  selected: _categoryId == c.id,
                                  onTap: () => _selectCategory(c.id),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
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
                        icon: Icons.shopping_bag_outlined,
                        title: AppStrings.noProducts,
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 240,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.60,
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

  Future<void> _copyPhone(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: company.whatsappNumber));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(AppStrings.phoneCopied)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.inkGradientTop, AppColors.inkGradientBottom],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildLogo(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    height: 1.15,
                    color: Colors.white,
                  ),
                ),
                if (company.tagline != null &&
                    company.tagline!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    company.tagline!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.3,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                ],
                if (company.whatsappNumber.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () => _copyPhone(context),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.whatsappGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            formatWhatsapp(company.whatsappNumber),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.copy_rounded,
                              size: 11, color: Colors.white.withValues(alpha: 0.5)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    final logoUrl = company.logoUrl;
    return Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: (logoUrl != null && logoUrl.isNotEmpty)
            ? Image.network(
                logoUrl,
                fit: BoxFit.cover,
                width: 54,
                height: 54,
                errorBuilder: (_, _, _) => _buildInitials(),
              )
            : _buildInitials(),
      ),
    );
  }

  Widget _buildInitials() {
    return Text(
      company.name.isNotEmpty ? company.name[0].toUpperCase() : "?",
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.textPrimary : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.textPrimary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check_rounded,
                  size: 14, color: AppColors.whatsappGreen),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
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
        Container(
          height: 110,
          decoration: const BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
        const SizedBox(height: 20),
        const Skeleton(height: 48),
        const SizedBox(height: 14),
        const Row(
          children: [
            Skeleton(width: 64, height: 32),
            SizedBox(width: 8),
            Skeleton(width: 90, height: 32),
            SizedBox(width: 8),
            Skeleton(width: 76, height: 32),
          ],
        ),
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
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.60,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: Skeleton()),
              Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton(height: 14),
                    SizedBox(height: 6),
                    Skeleton(width: 60, height: 9),
                    SizedBox(height: 10),
                    Skeleton(width: 84, height: 18),
                    SizedBox(height: 12),
                    Skeleton(height: 36),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProductCard extends StatefulWidget {
  final String companyId;
  final CatalogProduct product;

  const _ProductCard({required this.companyId, required this.product});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _hovered = false;

  void _share() {
    Share.share(
      AppStrings.shareProductText
          .replaceFirst("{name}", widget.product.name)
          .replaceFirst(
            "{url}",
            ApiClient.productUrl(widget.companyId, widget.product.id),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.02 : 1,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: _hovered
                    ? const Color(0x1F0F172A)
                    : Colors.transparent,
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push(
              "/public-catalog/${widget.companyId}/products/${product.id}",
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildImage(product)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                              height: 1.25,
                              letterSpacing: -0.2,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (product.category != null ||
                              product.code.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              product.category?.name ?? product.code,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PriceRow(product: product),
                          const SizedBox(height: 10),
                          WhatsappButton(
                            link: product.isAvailable
                                ? product.whatsappLink
                                : null,
                            label: product.isAvailable
                                ? AppStrings.consultWhatsApp
                                : AppStrings.productUnavailable,
                            compact: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(CatalogProduct product) {
    final image = product.imageUrl;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: AppColors.surfaceMuted,
          child: image != null
              ? Image.network(
                  image,
                  fit: BoxFit.cover,
                  cacheWidth: 512,
                  errorBuilder: (_, _, _) => const _ImagePlaceholder(),
                )
              : const _ImagePlaceholder(),
        ),
        if (product.discountPercentage > 0)
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.discountBadge,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                "-${product.discountPercentage.round()}%",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        Positioned(
          top: 8,
          right: 8,
          child: _ShareBubble(onTap: _share),
        ),
        if (!product.isAvailable)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.white.withValues(alpha: 0.65),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    AppStrings.outOfStock.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final CatalogProduct product;

  const _PriceRow({required this.product});

  @override
  Widget build(BuildContext context) {
    final hasDiscount = product.discountPercentage > 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: Text(
            Currency.format(product.finalPrice),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.5,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (hasDiscount) ...[
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              Currency.format(product.price),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                decoration: TextDecoration.lineThrough,
                decorationColor: AppColors.textMuted,
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ShareBubble extends StatelessWidget {
  final VoidCallback onTap;

  const _ShareBubble({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 30,
          height: 30,
          child: Icon(
            Icons.ios_share_rounded,
            size: 14,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_outlined, size: 36, color: AppColors.textMuted),
          SizedBox(height: 8),
          Text(
            "Sin foto",
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
