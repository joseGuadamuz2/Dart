import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/app_strings.dart';
import '../../core/errors/app_error.dart';
import '../../core/models/company.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/validators/validators.dart';
import '../../shared/services/image_picker_service.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_dialog.dart';
import '../../shared/widgets/app_text_field.dart';
import 'company_service.dart';

class CompanyFormScreen extends StatefulWidget {
  final Company? company;

  const CompanyFormScreen({super.key, this.company});

  @override
  State<CompanyFormScreen> createState() => _CompanyFormScreenState();
}

class _CompanyFormScreenState extends State<CompanyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ApiClient _apiClient;
  late final TextEditingController _nameController;
  late final TextEditingController _whatsappController;
  bool _isLoading = false;
  bool _isDeleting = false;
  String? _error;
  XFile? _pendingLogo;
  bool _logoRemoved = false;

  bool get _isEditing => widget.company != null;

  @override
  void initState() {
    super.initState();
    _apiClient = context.read<ApiClient>();
    _nameController = TextEditingController(text: widget.company?.name ?? "");
    _whatsappController = TextEditingController(
      text: widget.company?.whatsappNumber ?? "",
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      final file = await ImagePickerService(_apiClient).pickImage();
      if (file == null || !mounted) return;
      setState(() {
        _pendingLogo = file;
        _logoRemoved = false;
      });
    } catch (e) {
      if (mounted) setState(() => _error = AppError.from(e).message);
    }
  }

  void _removeLogo() {
    setState(() {
      _pendingLogo = null;
      _logoRemoved = true;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final service = CompanyService(context.read<ApiClient>());
    try {
      String? logoUrl;
      if (_pendingLogo != null) {
        final bytes = await _pendingLogo!.readAsBytes();
        logoUrl = await service.uploadImage(bytes, _pendingLogo!.name);
      }
      if (_isEditing) {
        await service.update(
          widget.company!.id,
          name: _nameController.text.trim(),
          whatsappNumber: _whatsappController.text.trim(),
          logoUrl: logoUrl,
          removeLogo: _pendingLogo == null && _logoRemoved,
        );
      } else {
        await service.create(
          _nameController.text.trim(),
          _whatsappController.text.trim(),
          logoUrl: logoUrl,
        );
      }
      if (mounted) {
        showAppSnackBar(context, AppStrings.savedSuccessfully);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = AppError.from(e).message;
        });
      }
    }
  }

  Future<void> _copyLink() async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(
      ClipboardData(text: ApiClient.catalogUrl(widget.company!.id)),
    );
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(AppStrings.linkCopied)));
  }

  Future<void> _delete() async {
    final confirmed = await confirmAction(
      context,
      title: AppStrings.deleteCompanyTitle,
      message: AppStrings.deleteCompanyMessage,
    );
    if (!confirmed || !mounted) return;
    setState(() => _isDeleting = true);
    try {
      await CompanyService(context.read<ApiClient>()).delete(widget.company!.id);
      if (mounted) {
        showAppSnackBar(context, AppStrings.deletedSuccessfully);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        showAppSnackBar(context, AppError.from(e).message);
      }
    }
  }

  Widget _buildLogoPicker() {
    final existingUrl =
        _logoRemoved ? null : widget.company?.logoUrl;
    final hasImage = _pendingLogo != null ||
        (existingUrl != null && existingUrl.isNotEmpty);
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          InkWell(
            onTap: _pickLogo,
            borderRadius: BorderRadius.circular(60),
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(60),
                border: Border.all(color: AppColors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: hasImage
                    ? (_pendingLogo != null
                        ? (kIsWeb
                            ? Image.network(_pendingLogo!.path,
                                fit: BoxFit.cover)
                            : Image.file(File(_pendingLogo!.path),
                                fit: BoxFit.cover))
                        : Image.network(
                            existingUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.add_a_photo,
                              size: 32,
                              color: AppColors.textMuted,
                            ),
                          ))
                    : const Icon(
                        Icons.add_a_photo,
                        size: 32,
                        color: AppColors.textMuted,
                      ),
              ),
            ),
          ),
          if (hasImage)
            Positioned(
              top: -4,
              right: -4,
              child: InkWell(
                onTap: _removeLogo,
                customBorder: const CircleBorder(),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? AppStrings.editCompany : AppStrings.newCompany,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLogoPicker(),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        AppStrings.companyLogoLabel,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppTextField(
                    controller: _nameController,
                    label: AppStrings.nameLabel,
                    validator: requiredMaxLengthValidator(100),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _whatsappController,
                    label: AppStrings.whatsappLabel,
                    hint: AppStrings.whatsappHint,
                    keyboardType: TextInputType.phone,
                    validator: whatsappValidator,
                  ),
                  const SizedBox(height: 24),
                  if (_isEditing) ...[
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.yourCatalog,
                      style: AppTextStyles.heading,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.shareCatalogHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: AppStrings.share,
                            icon: Icons.share,
                            variant: AppButtonVariant.secondary,
                            onPressed: () async {
                              await Share.share(
                                AppStrings.shareCatalogText
                                    .replaceFirst(
                                      "{name}",
                                      _nameController.text.trim(),
                                    )
                                    .replaceFirst(
                                      "{url}",
                                      ApiClient.catalogUrl(widget.company!.id),
                                    ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppButton(
                            label: AppStrings.copyLink,
                            icon: Icons.link,
                            variant: AppButtonVariant.secondary,
                            onPressed: _copyLink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(_error!, style: AppTextStyles.error),
                    ),
                  AppButton(
                    label: _isEditing ? AppStrings.save : AppStrings.create,
                    isLoading: _isLoading,
                    onPressed: _save,
                  ),
                  if (_isEditing) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    AppButton(
                      label: AppStrings.delete,
                      icon: Icons.delete_outline,
                      variant: AppButtonVariant.danger,
                      isLoading: _isDeleting,
                      onPressed: _delete,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}