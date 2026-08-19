import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/app_strings.dart';
import '../../core/errors/app_error.dart';
import '../../core/models/category.dart';
import '../../core/models/company.dart';
import '../../shared/services/image_picker_service.dart';
import '../../shared/widgets/app_dialog.dart';
import '../categories/category_service.dart';
import '../companies/company_service.dart';
import 'presentation/widgets/product_basic_info.dart';
import 'presentation/widgets/product_category_selector.dart';
import 'presentation/widgets/product_images_section.dart';
import 'presentation/widgets/product_price_section.dart';
import 'presentation/widgets/product_submit_button.dart';
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
  final List<PendingImage> _pendingImages = [];

  late final ApiClient _apiClient;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _apiClient = context.read<ApiClient>();
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
    try {
      final companies = await CompanyService(_apiClient).findMyCompanies();
      if (!mounted) return;
      setState(() {
        _companies = companies;
        if (_companyId == null && companies.isNotEmpty) {
          _companyId = companies.first.id;
        }
      });
      if (_companyId != null) _loadCategories();
    } catch (e) {
      if (mounted) setState(() => _error = AppError.from(e).message);
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories =
          await CategoryService(_apiClient).findByCompany(_companyId!);
      if (!mounted) return;
      setState(() {
        _categories = categories;
        if (widget.product == null) _categoryId = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = AppError.from(e).message);
    }
  }

  Future<void> _pickAndUpload() async {
    setState(() {
      _uploadingImage = true;
      _error = null;
    });
    try {
      final url = await ImagePickerService(_apiClient).pickAndUpload();
      if (!mounted) return;
      final updated =
          await ProductService(_apiClient).addImage(widget.product!.id, url);
      if (mounted) setState(() => _images = List.of(updated.images));
    } on ImagePickCancelled {
      // sin acción
    } catch (e) {
      if (mounted) {
        setState(() =>
            _error = "${AppStrings.imageUploadError}: ${AppError.from(e).message}");
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _pickImages() async {
    try {
      final files = await ImagePickerService(_apiClient).pickImages();
      if (files.isEmpty || !mounted) return;
      setState(() {
        for (final file in files) {
          _pendingImages.add(PendingImage(file, isMain: _pendingImages.isEmpty));
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = AppError.from(e).message);
    }
  }

  void _setMainPending(PendingImage image) {
    setState(() {
      for (final pending in _pendingImages) {
        pending.isMain = identical(pending, image);
      }
    });
  }

  void _deletePending(PendingImage image) {
    setState(() {
      _pendingImages.remove(image);
      if (_pendingImages.isNotEmpty && !_pendingImages.any((p) => p.isMain)) {
        _pendingImages.first.isMain = true;
      }
    });
  }

  Future<void> _setMainImage(ProductImage image) async {
    try {
      final updated = await ProductService(_apiClient)
          .setMainImage(widget.product!.id, image.id);
      if (mounted) setState(() => _images = List.of(updated.images));
    } catch (e) {
      if (mounted) setState(() => _error = AppError.from(e).message);
    }
  }

  Future<void> _deleteImage(ProductImage image) async {
    try {
      final updated = await ProductService(_apiClient)
          .removeImage(widget.product!.id, image.id);
      if (mounted) setState(() => _images = List.of(updated.images));
    } catch (e) {
      if (mounted) setState(() => _error = AppError.from(e).message);
    }
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
    };
    final service = ProductService(_apiClient);
    try {
      if (_isEditing) {
        await service.update(widget.product!.id, data);
      } else {
        if (_pendingImages.isNotEmpty) {
          setState(() => _uploadingImage = true);
          final ordered = <PendingImage>[
            ..._pendingImages.where((p) => p.isMain),
            ..._pendingImages.where((p) => !p.isMain),
          ];
          final urls = <String>[];
          for (final pending in ordered) {
            final bytes = await pending.file.readAsBytes();
            urls.add(await service.uploadImage(bytes, pending.file.name));
          }
          data["imageUrls"] = urls;
        }
        await service.create(data);
      }
      if (mounted) {
        showAppSnackBar(context, AppStrings.savedSuccessfully);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _uploadingImage = false;
          _error = _pendingImages.isNotEmpty && !_isEditing
              ? "${AppStrings.imageUploadError}: ${AppError.from(e).message}"
              : AppError.from(e).message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? AppStrings.editProduct : AppStrings.newProduct),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductCategorySelector(
                companies: _companies,
                categories: _categories,
                companyId: _companyId,
                categoryId: _categoryId,
                onCompanyChanged: (value) {
                  setState(() => _companyId = value);
                  _loadCategories();
                },
                onCategoryChanged: (value) => setState(() => _categoryId = value),
              ),
              const SizedBox(height: 16),
              ProductBasicInfo(
                nameController: _nameController,
                codeController: _codeController,
                descriptionController: _descriptionController,
              ),
              const SizedBox(height: 16),
              ProductPriceSection(
                priceController: _priceController,
                discountController: _discountController,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text(AppStrings.availableLabel),
                value: _isAvailable,
                onChanged: (v) => setState(() => _isAvailable = v),
              ),
              SwitchListTile(
                title: const Text(AppStrings.featuredLabel),
                value: _isFeatured,
                onChanged: (v) => setState(() => _isFeatured = v),
              ),
              const SizedBox(height: 8),
              ProductImagesSection(
                isEditing: _isEditing,
                isUploading: _uploadingImage,
                images: _images,
                pendingImages: _pendingImages,
                onPick: _isEditing ? _pickAndUpload : _pickImages,
                onSetMain: _setMainImage,
                onDeleteImage: _deleteImage,
                onSetMainPending: _setMainPending,
                onDeletePending: _deletePending,
              ),
              const SizedBox(height: 24),
              ProductSubmitButton(
                isEditing: _isEditing,
                isLoading: _isLoading,
                error: _error,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}