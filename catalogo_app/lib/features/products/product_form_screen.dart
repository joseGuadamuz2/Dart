import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/models/category.dart';
import '../../core/models/company.dart';
import '../../shared/services/image_picker_service.dart';
import '../categories/category_service.dart';
import '../companies/company_service.dart';
import 'product_model.dart';
import 'product_service.dart';

class ProductFormScreen extends StatefulWidget {
  final String? companyId;
  final Product? product;

  const ProductFormScreen({super.key, this.companyId, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _discountController;
  late final TextEditingController _codeController;
  late final TextEditingController _descriptionController;

  String? _companyId;
  String? _categoryId;
  List<Company> _companies = [];
  List<Category> _categories = [];
  bool _isAvailable = true;
  bool _isFeatured = false;
  bool _isLoading = false;
  bool _uploadingImage = false;
  String? _error;

  List<ProductImage> _images = [];
  final List<String> _pendingImageUrls = [];

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? "");
    _priceController = TextEditingController(
      text: p != null ? p.price.toStringAsFixed(2) : "",
    );
    _discountController = TextEditingController(
      text: p != null && p.discountPercentage > 0
          ? p.discountPercentage.toString()
          : "",
    );
    _codeController = TextEditingController(text: p?.code ?? "");
    _descriptionController = TextEditingController(text: p?.description ?? "");
    _companyId = widget.companyId ?? p?.companyId;
    _categoryId = p?.categoryId;
    _isAvailable = p?.isAvailable ?? true;
    _isFeatured = p?.isFeatured ?? false;
    _images = List.of(p?.images ?? []);
    _loadCompanies();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanies() async {
    final companies = await CompanyService(ApiClient()).findMyCompanies();
    setState(() {
      _companies = companies;
      if (_companyId == null && companies.isNotEmpty) {
        _companyId = companies.first.id;
      }
    });
    if (_companyId != null) _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories =
        await CategoryService(ApiClient()).findByCompany(_companyId!);
    setState(() {
      _categories = categories;
      if (widget.product == null) _categoryId = null;
    });
  }

  Future<void> _pickAndUpload() async {
    setState(() {
      _uploadingImage = true;
      _error = null;
    });
    try {
      final url = await ImagePickerService().pickAndUpload();
      if (_isEditing) {
        final updated =
            await ProductService(ApiClient()).addImage(widget.product!.id, url);
        setState(() => _images = List.of(updated.images));
      } else {
        setState(() => _pendingImageUrls.add(url));
      }
    } on ImagePickCancelled {
      // sin acción
    } catch (e) {
      setState(() => _error = "Error al subir imagen: $e");
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _setMainImage(ProductImage image) async {
    final updated = await ProductService(ApiClient())
        .setMainImage(widget.product!.id, image.id);
    setState(() => _images = List.of(updated.images));
  }

  Future<void> _deleteImage(ProductImage image) async {
    final updated = await ProductService(ApiClient())
        .removeImage(widget.product!.id, image.id);
    setState(() => _images = List.of(updated.images));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final data = {
      "name": _nameController.text.trim(),
      "companyId": _companyId,
      "price": double.parse(_priceController.text.trim()),
      "isAvailable": _isAvailable,
      "isFeatured": _isFeatured,
      if (_discountController.text.trim().isNotEmpty)
        "discountPercentage": double.parse(_discountController.text.trim()),
      if (_codeController.text.trim().isNotEmpty)
        "code": _codeController.text.trim(),
      if (_descriptionController.text.trim().isNotEmpty)
        "description": _descriptionController.text.trim(),
      if (_categoryId != null) "categoryId": _categoryId,
      if (_pendingImageUrls.isNotEmpty) "imageUrls": _pendingImageUrls,
    };
    final service = ProductService(ApiClient());
    try {
      if (_isEditing) {
        await service.update(widget.product!.id, data);
      } else {
        await service.create(data);
      }
      if (mounted) context.pop();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? "Editar producto" : "Nuevo producto"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _companyId,
                decoration: const InputDecoration(labelText: "Empresa"),
                items: _companies
                    .map((c) =>
                        DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (value) {
                  setState(() => _companyId = value);
                  _loadCategories();
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Nombre"),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? "Requerido" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: "Precio"),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Requerido";
                  if (double.tryParse(v.trim()) == null) return "Inválido";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _discountController,
                decoration: const InputDecoration(labelText: "Descuento (%)"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: "Código"),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: "Descripción"),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: "Categoría"),
                items: _categories
                    .map((c) =>
                        DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (value) => setState(() => _categoryId = value),
              ),
              SwitchListTile(
                title: const Text("Disponible"),
                value: _isAvailable,
                onChanged: (v) => setState(() => _isAvailable = v),
              ),
              SwitchListTile(
                title: const Text("Destacado"),
                value: _isFeatured,
                onChanged: (v) => setState(() => _isFeatured = v),
              ),
              const SizedBox(height: 8),
              _buildImagesSection(),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(_isEditing ? "Guardar" : "Crear"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagesSection() {
    final items = <Widget>[];

    if (_isEditing) {
      for (var i = 0; i < _images.length; i++) {
        items.add(_buildImageTile(
          url: _images[i].url,
          isMain: _images[i].isMain,
          mainEnabled: !_images[i].isMain,
          onSetMain: () => _setMainImage(_images[i]),
          onDelete: () => _deleteImage(_images[i]),
        ));
      }
    } else {
      for (final url in _pendingImageUrls) {
        items.add(_buildImageTile(
          url: url,
          isMain: false,
          onDelete: () => setState(() => _pendingImageUrls.remove(url)),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Fotos", style: TextStyle(fontWeight: FontWeight.bold)),
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
          onPressed: _uploadingImage ? null : _pickAndUpload,
          icon: _uploadingImage
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_photo_alternate),
          label: const Text("Subir foto"),
        ),
      ],
    );
  }

  Widget _buildImageTile({
    required String url,
    required bool isMain,
    bool mainEnabled = false,
    VoidCallback? onSetMain,
    required VoidCallback onDelete,
  }) {
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