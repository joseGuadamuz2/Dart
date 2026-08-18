import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/models/public_catalog.dart';
import '../../shared/widgets/skeleton.dart';
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
    _future = CatalogService(ApiClient())
        .getProduct(widget.companyId, widget.productId);
  }

  Future<void> _openWhatsApp(CatalogProduct product) async {
    if (product.whatsappLink.isEmpty) return;
    final uri = Uri.parse(product.whatsappLink);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo abrir el enlace")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.companyName ?? "Detalle")),
      body: FutureBuilder<CatalogProduct>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _DetailSkeleton();
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final product = snapshot.data!;
          final images = product.images.isNotEmpty
              ? product.images
              : [if (product.imageUrl != null) _fakeImage(product.imageUrl!)];
          final hasDiscount = product.discountPercentage > 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGallery(images),
                const SizedBox(height: 16),
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (product.category != null)
                  Text(
                    product.category!.name,
                    style: const TextStyle(color: Colors.grey),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      "\$${product.finalPrice.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: hasDiscount ? Colors.green : null,
                      ),
                    ),
                    if (hasDiscount) ...[
                      const SizedBox(width: 8),
                      Text(
                        "\$${product.price.toStringAsFixed(2)}",
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
                if (product.description != null &&
                    product.description!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    "Descripción",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(product.description!),
                ],
                if (product.whatsappLink.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _openWhatsApp(product),
                      icon: const Icon(Icons.chat),
                      label: const Text("Consultar por WhatsApp"),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Share.share(
                        "Mira ${product.name}: ${ApiClient.productUrl(widget.companyId, widget.productId)}",
                      );
                    },
                    icon: const Icon(Icons.share),
                    label: const Text("Compartir producto"),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGallery(List<ProductImage> images) {
    if (images.isEmpty) {
      return Container(
        height: 260,
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.shopping_bag, size: 80, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            images[_selectedImage.clamp(0, images.length - 1)].url,
            height: 260,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              height: 260,
              color: Colors.grey.shade200,
              child: const Center(child: Icon(Icons.broken_image, size: 64)),
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final selected = index == _selectedImage;
                return GestureDetector(
                  onTap: () => setState(() => _selectedImage = index),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          images[index].url,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
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

  ProductImage _fakeImage(String url) =>
      ProductImage(id: "main", url: url, isMain: true);
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Skeleton(
          height: 260,
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        SizedBox(height: 16),
        Skeleton(width: 200, height: 22),
        SizedBox(height: 8),
        Skeleton(width: 120, height: 14),
        SizedBox(height: 12),
        Skeleton(width: 140, height: 18),
        SizedBox(height: 16),
        Skeleton(height: 14),
        SizedBox(height: 8),
        Skeleton(height: 14),
        SizedBox(height: 8),
        Skeleton(width: 220, height: 14),
        SizedBox(height: 32),
        Skeleton(height: 48),
        SizedBox(height: 12),
        Skeleton(height: 48),
      ],
    );
  }
}