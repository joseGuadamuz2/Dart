import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/app_strings.dart';
import '../../core/errors/app_error.dart';
import '../../core/models/company.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/validators/validators.dart';
import '../../shared/widgets/app_button.dart';
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
  late final TextEditingController _nameController;
  late final TextEditingController _whatsappController;
  bool _isLoading = false;
  String? _error;

  bool get _isEditing => widget.company != null;

  @override
  void initState() {
    super.initState();
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final service = CompanyService(context.read<ApiClient>());
    try {
      if (_isEditing) {
        await service.update(
          widget.company!.id,
          name: _nameController.text.trim(),
          whatsappNumber: _whatsappController.text.trim(),
        );
      } else {
        await service.create(
          _nameController.text.trim(),
          _whatsappController.text.trim(),
        );
      }
      if (mounted) context.pop();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? AppStrings.editCompany : AppStrings.newCompany,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                controller: _nameController,
                label: AppStrings.nameLabel,
                validator: requiredValidator,
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
                const Text(
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
            ],
          ),
        ),
      ),
    );
  }
}