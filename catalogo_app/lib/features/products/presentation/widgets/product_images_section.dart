import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../product_model.dart';

class ProductImagesSection extends StatelessWidget {
  final bool isEditing;
  final bool isUploading;
  final List<ProductImage> images;
  final List<String> pendingImageUrls;
  final VoidCallback onUpload;
  final void Function(ProductImage image) onSetMain;
  final void Function(ProductImage image) onDeleteImage;
  final void Function(String url) onDeletePending;

  const ProductImagesSection({
    super.key,
    required this.isEditing,
    required this.isUploading,
    required this.images,
    required this.pendingImageUrls,
    required this.onUpload,
    required this.onSetMain,
    required this.onDeleteImage,
    required this.onDeletePending,
  });

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];

    if (isEditing) {
      for (var i = 0; i < images.length; i++) {
        items.add(_ImageTile(
          url: images[i].url,
          isMain: images[i].isMain,
          mainEnabled: !images[i].isMain,
          onSetMain: () => onSetMain(images[i]),
          onDelete: () => onDeleteImage(images[i]),
        ));
      }
    } else {
      for (final url in pendingImageUrls) {
        items.add(_ImageTile(
          url: url,
          isMain: false,
          onDelete: () => onDeletePending(url),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.photosTitle, style: AppTextStyles.section),
        const SizedBox(height: 8),
        if (items.isNotEmpty)
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) => items[index],
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: isUploading ? null : onUpload,
          icon: isUploading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_photo_alternate),
          label: const Text(AppStrings.uploadPhoto),
        ),
      ],
    );
  }
}

class _ImageTile extends StatelessWidget {
  final String url;
  final bool isMain;
  final bool mainEnabled;
  final VoidCallback? onSetMain;
  final VoidCallback onDelete;

  const _ImageTile({
    required this.url,
    required this.isMain,
    this.mainEnabled = false,
    this.onSetMain,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 100,
              height: 100,
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image),
            ),
          ),
        ),
        if (onSetMain != null)
          Positioned(
            top: 4,
            left: 4,
            child: IconButton(
              icon: Icon(
                isMain ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 22,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: mainEnabled ? onSetMain : null,
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 22,
            onPressed: onDelete,
          ),
        ),
      ],
    );
  }
}