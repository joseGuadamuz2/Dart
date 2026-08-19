import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_dialog.dart';
import 'product_model.dart';
import 'product_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Product _product;
  int _selectedImage = 0;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
  }

  Future<void> _edit() async {
    final provider = context.read<ProductProvider>();
    await context.push("/products/${_product.id}/edit", extra: _product);
    if (!mounted) return;
    await provider.refresh();
    if (!mounted) return;
    Product? updated;
    for (final p in provider.products) {
      if (p.id == _product.id) {
        updated = p;
        break;
      }
    }
    if (updated != null) {
      setState(() {
        _product = updated!;
        _selectedImage = 0;
      });
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _delete() async {
    final provider = context.read<ProductProvider>();
    final confirmed = await confirmAction(
      context,
      title: AppStrings.deleteProductTitle,
      message: AppStrings.deleteProductMessage,
    );
    if (!confirmed) return;
    await provider.delete(_product.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final hasDiscount = _product.discountPercentage > 0;
    final hasDescription = _product.description != null &&
        _product.description!.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: AppStrings.edit,
            onPressed: _edit,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGallery(),
                const SizedBox(height: 16),
                Text(_product.name, style: AppTextStyles.title),
                if (_product.code != null && _product.code!.isNotEmpty)
                  Text(
                    "${AppStrings.codeLabel}: ${_product.code}",
                    style: AppTextStyles.caption,
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      Currency.format(_product.finalPrice),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: hasDiscount ? AppColors.success : AppColors.primary,
                      ),
                    ),
                    if (hasDiscount) ...[
                      const SizedBox(width: 8),
                      Text(
                        Currency.format(_product.price),
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _statusChip(
                      _product.isAvailable,
                      AppStrings.availableLabel,
                      Icons.check_circle,
                      Colors.green,
                    ),
                    if (_product.isFeatured)
                      _statusChip(
                        true,
                        AppStrings.featuredLabel,
                        Icons.star,
                        Colors.amber,
                      ),
                  ],
                ),
                if (hasDescription) ...[
                  const SizedBox(height: 16),
                  const Text(
                    AppStrings.descriptionLabel,
                    style: AppTextStyles.section,
                  ),
                  const SizedBox(height: 4),
                  Text(_product.description!),
                ],
                const SizedBox(height: 32),
                AppButton(
                  label: AppStrings.edit,
                  icon: Icons.edit,
                  onPressed: _edit,
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: AppStrings.delete,
                  icon: Icons.delete,
                  variant: AppButtonVariant.danger,
                  onPressed: _delete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusChip(
    bool active,
    String label,
    IconData icon,
    Color color,
  ) {
    if (!active) {
      return const Chip(
        avatar: Icon(Icons.block, color: Colors.red, size: 18),
        label: Text(AppStrings.outOfStock),
      );
    }
    return Chip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(label),
    );
  }

  Widget _buildGallery() {
    final urls = _product.images.isNotEmpty
        ? _product.images.map((i) => i.url).toList()
        : [if (_product.mainImageUrl != null) _product.mainImageUrl!];

    if (urls.isEmpty) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              color: Colors.grey.shade200,
              child: const Center(
                child: Icon(Icons.shopping_bag, size: 80, color: Colors.grey),
              ),
            ),
          ),
        ),
      );
    }

    final index = _selectedImage.clamp(0, urls.length - 1);
    return Column(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  urls[index],
                  fit: BoxFit.cover,
                  cacheWidth: 1000,
                  errorBuilder: (_, _, _) => Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 64),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (urls.length > 1) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: urls.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final selected = i == _selectedImage;
                return GestureDetector(
                  onTap: () => setState(() => _selectedImage = i),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          urls[i],
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          cacheWidth: 128,
                          errorBuilder: (_, _, _) => Container(
                            width: 64,
                            height: 64,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image, size: 24),
                          ),
                        ),
                      ),
                      if (selected)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                    ],
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