import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/models/public_catalog.dart';
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
    _future = CatalogService(ApiClient()).getCompanyCatalog(widget.companyId);
    _productsFuture =
        CatalogService(ApiClient()).getProducts(widget.companyId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectCategory(String? categoryId) {
    setState(() {
      _categoryId = categoryId;
      _productsFuture = CatalogService(ApiClient())
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
      appBar: AppBar(
        title: Text(widget.companyName ?? "Catálogo"),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: "Descargar PDF",
            onPressed: _openPdf,
          ),
        ],
      ),
      body: FutureBuilder<PublicCatalog>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _CatalogSkeleton();
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final catalog = snapshot.data!;
          return Column(
            children: [
              Padding(
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
                        hintText: "Buscar productos",
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text("Todos"),
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
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<CatalogProduct>>(
                  future: _productsFuture,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const _ProductsSkeleton();
                    }
                    if (snap.hasError) {
                      return Center(child: Text("Error: ${snap.error}"));
                    }
                    var products = snap.data ?? [];
                    if (_searchQuery.isNotEmpty) {
                      final q = _searchQuery.toLowerCase();
                      products = products
                          .where((p) => p.name.toLowerCase().contains(q))
                          .toList();
                    }
                    if (products.isEmpty) {
                      return const Center(child: Text("Sin productos"));
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 240,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.62,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) => _ProductCard(
                        companyId: widget.companyId,
                        product: products[index],
                      ),
                    );
                  },
                ),
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
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.storefront,
            size: 32,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                company.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (company.whatsappNumber.isNotEmpty)
                Text(
                  "WhatsApp: ${company.whatsappNumber}",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
            ],
          ),
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    final hasDiscount = product.discountPercentage > 0;
    final image = product.imageUrl;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
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
                          color: Colors.red,
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
                            "Agotado",
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
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (product.category != null)
                    Text(
                      product.category!.name,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          "\$${product.finalPrice.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: hasDiscount ? Colors.green : null,
                          ),
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            "\$${product.price.toStringAsFixed(2)}",
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (product.whatsappLink.isNotEmpty)
                    Row(
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.chat, size: 20),
                          tooltip: "Copiar enlace de WhatsApp",
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: product.whatsappLink),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Enlace copiado")),
                            );
                          },
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.share, size: 20),
                          tooltip: "Compartir producto",
                          onPressed: () {
                            Share.share(
                              "Mira ${product.name}: ${ApiClient.productUrl(companyId, product.id)}",
                            );
                          },
                        ),
                      ],
                    ),
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
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(icon, size: 48, color: Colors.grey.shade500),
      ),
    );
  }
}