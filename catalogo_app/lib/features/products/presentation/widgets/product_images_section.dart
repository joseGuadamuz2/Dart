import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../product_model.dart';

class PendingImage {
  final XFile file;
  bool isMain;

  PendingImage(this.file, {this.isMain = false});
}

class ProductImagesSection extends StatelessWidget {
  final bool isEditing;
  final bool isUploading;
  final List<ProductImage> images;
  final List<PendingImage> pendingImages;
  final VoidCallback onPick;
  final void Function(ProductImage image) onSetMain;
  final void Function(ProductImage image) onDeleteImage;
  final void Function(PendingImage image) onSetMainPending;
  final void Function(PendingImage image) onDeletePending;

  const ProductImagesSection({
    super.key,
    required this.isEditing,
    required this.isUploading,
    required this.images,
    required this.pendingImages,
    required this.onPick,
    required this.onSetMain,
    required this.onDeleteImage,
    required this.onSetMainPending,
    required this.onDeletePending,
  });

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];

    if (isEditing) {
      for (final image in images) {
        items.add(_ImageTile.network(
          url: image.url,
          isMain: image.isMain,
          onSetMain: image.isMain ? null : () => onSetMain(image),
          onDelete: () => onDeleteImage(image),
        ));
      }
    } else {
      for (final pending in pendingImages) {
        items.add(_ImageTile.file(
          file: pending.file,
          isMain: pending.isMain,
          onSetMain: pending.isMain ? null : () => onSetMainPending(pending),
          onDelete: () => onDeletePending(pending),
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
          onPressed: isUploading ? null : onPick,
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
  final Widget image;
  final bool isMain;
  final VoidCallback? onSetMain;
  final VoidCallback onDelete;

  _ImageTile.file({
    required XFile file,
    required this.isMain,
    this.onSetMain,
    required this.onDelete,
  }) : image = Image.file(
          File(file.path),
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            width: 100,
            height: 100,
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image),
          ),
        );

  _ImageTile.network({
    required String url,
    required this.isMain,
    this.onSetMain,
    required this.onDelete,
  }) : image = Image.network(
          url,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          cacheWidth: 256,
          errorBuilder: (_, _, _) => Container(
            width: 100,
            height: 100,
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image),
          ),
        );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: image,
        ),
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
            onPressed: isMain ? null : onSetMain,
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
