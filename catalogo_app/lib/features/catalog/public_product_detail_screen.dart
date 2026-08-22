import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/errors/app_error.dart';
import '../../core/models/public_catalog.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_error_view.dart';
import '../../shared/widgets/skeleton.dart';
import '../../shared/widgets/whatsapp_button.dart';
import 'catalog_service.dart';

class PublicProductDetailScreen extends StatefulWidget {
  final String companyId;
  final String productId;
  final String? companyName;

  const PublicProductDetailScreen({
    super.key,
    required this.companyId,
    required this.productId,
    this.companyName,
  });

  @override
  State<PublicProductDetailScreen> createState() =>
      _PublicProductDetailScreenState();
}

class _PublicProductDetailScreenState
    extends State<PublicProductDetailScreen> {
  late Future<CatalogProduct> _future;
  int _selectedImage = 0;

  @override
  void initState() {
    super.initState();
    _future = CatalogService(context.read<ApiClient>())
        .getProduct(widget.companyId, widget.productId);
  }

  void _share(CatalogProduct product) {
    Share.share(
      AppStrings.shareProductText
          .replaceFirst("{name}", product.name)
          .replaceFirst(
            "{url}",
            ApiClient.productUrl(widget.companyId, widget.productId),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                onPressed: () => context.pop(),
              )
            : null,
        title: Text(widget.companyName ?? AppStrings.productDetail),
      ),
      body: FutureBuilder<CatalogProduct>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _DetailSkeleton();
          }
          if (snapshot.hasError) {
            return AppErrorView(
              message: AppError.from(snapshot.error!).message,
            );
          }
          final product = snapshot.data!;
          return Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGallery(product),
                      const SizedBox(height: 20),
                      if (product.category != null) ...[
                        Text(
                          product.category!.name.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          letterSpacing: -0.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (product.code.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          "${AppStrings.codeLabel}: ${product.code}",
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      _PriceSection(product: product),
                      if (!product.isAvailable) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warningContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  size: 16, color: AppColors.warning),
                              SizedBox(width: 8),
                              Text(
                                AppStrings.productUnavailable,
                                style: TextStyle(
                                  color: AppColors.onWarningContainer,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (product.description != null &&
                          product.description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text(
                          "Descripción",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          product.description!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            height: 1.55,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            bottomNavigationBar: _buildBottomBar(product),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar(CatalogProduct product) {
    final canOrder = product.whatsappLink.isNotEmpty && product.isAvailable;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canOrder) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
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
                const Text(
                  AppStrings.fastReplyWhatsapp,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Material(
                color: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: InkWell(
                  onTap: () => _share(product),
                  customBorder: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Tooltip(
                    message: AppStrings.shareProduct,
                    child: SizedBox(
                      width: 52,
                      height: 52,
                      child: Icon(
                        Icons.ios_share_rounded,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: WhatsappButton(
                  link: canOrder ? product.whatsappLink : null,
                  label:
                      canOrder ? AppStrings.consultWhatsApp : AppStrings.outOfStock,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGallery(CatalogProduct product) {
    final images = product.images.isNotEmpty
        ? product.images
        : [if (product.imageUrl != null) ProductImage(id: "main", url: product.imageUrl!, isMain: true)];

    if (images.isEmpty) {
      return AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: Icon(Icons.image_outlined, size: 64, color: AppColors.textMuted),
          ),
        ),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 1,
            child: ColoredBox(
              color: AppColors.surfaceMuted,
              child: Image.network(
                images[_selectedImage.clamp(0, images.length - 1)].url,
                fit: BoxFit.cover,
                cacheWidth: 1000,
                errorBuilder: (_, _, _) => const Center(
                  child: Icon(Icons.broken_image_outlined,
                      size: 56, color: AppColors.textMuted),
                ),
              ),
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final selected = index == _selectedImage;
                return GestureDetector(
                  onTap: () => setState(() => _selectedImage = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppColors.whatsappDark
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9.5),
                      child: ColoredBox(
                        color: AppColors.surfaceMuted,
                        child: Image.network(
                          images[index].url,
                          width: 59,
                          height: 59,
                          fit: BoxFit.cover,
                          cacheWidth: 128,
                          errorBuilder: (_, _, _) => const SizedBox(
                            width: 59,
                            height: 59,
                            child: Icon(Icons.broken_image_outlined,
                                size: 20, color: AppColors.textMuted),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _PriceSection extends StatelessWidget {
  final CatalogProduct product;

  const _PriceSection({required this.product});

  @override
  Widget build(BuildContext context) {
    final hasDiscount = product.discountPercentage > 0;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 6,
      children: [
        Text(
          Currency.format(product.finalPrice),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            height: 1,
            color: AppColors.textPrimary,
          ),
        ),
        if (hasDiscount) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.discountBadge,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              "-${product.discountPercentage.round()}%",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Text(
            Currency.format(product.price),
            style: const TextStyle(
              decoration: TextDecoration.lineThrough,
              decorationColor: AppColors.textMuted,
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: const AspectRatio(
              aspectRatio: 1,
              child: Skeleton(
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Skeleton(width: 80, height: 11),
        const SizedBox(height: 8),
        const Skeleton(width: 220, height: 22),
        const SizedBox(height: 6),
        const Skeleton(width: 120, height: 12),
        const SizedBox(height: 16),
        const Skeleton(width: 150, height: 28),
        const SizedBox(height: 24),
        const Skeleton(width: 110, height: 14),
        const SizedBox(height: 10),
        const Skeleton(height: 14),
        const SizedBox(height: 8),
        const Skeleton(height: 14),
        const SizedBox(height: 8),
        const Skeleton(width: 240, height: 14),
      ],
    );
  }
}
