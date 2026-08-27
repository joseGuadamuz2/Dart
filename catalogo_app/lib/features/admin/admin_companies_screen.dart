import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/constants/app_strings.dart';
import '../../core/errors/app_error.dart';
import '../../core/models/company.dart';
import '../../core/theme/app_colors.dart';
import '../../core/validators/validators.dart';
import '../../shared/widgets/app_dialog.dart';
import '../../shared/widgets/app_empty_state.dart';
import '../../shared/widgets/app_error_view.dart';
import '../../shared/widgets/app_loading.dart';
import 'admin_service.dart';

class AdminCompaniesScreen extends StatefulWidget {
  const AdminCompaniesScreen({super.key});

  @override
  State<AdminCompaniesScreen> createState() => _AdminCompaniesScreenState();
}

class _AdminCompaniesScreenState extends State<AdminCompaniesScreen> {
  late Future<
      (List<Company>, List<Map<String, dynamic>>, List<Map<String, dynamic>>)>
      _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<
      (List<Company>, List<Map<String, dynamic>>, List<Map<String, dynamic>>)>
      _load() async {
    final service = AdminService(context.read<ApiClient>());
    final users = await service.listUsers();
    final results = await Future.wait<dynamic>([
      service.listCompanies(),
      service.listLicenses(),
    ]);
    return (
      results[0] as List<Company>,
      users,
      results[1] as List<Map<String, dynamic>>,
    );
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _createCompany(
    List<Map<String, dynamic>> users,
    List<Map<String, dynamic>> licenses,
  ) async {
    final apiClient = context.read<ApiClient>();
    final result = await showDialog<CompanyFormData>(
      context: context,
      builder: (_) => _CompanyFormDialog(users: users, licenses: licenses),
    );
    if (result == null) return;
    try {
      await AdminService(apiClient).createCompany(
        name: result.name,
        whatsappNumber: normalizeWhatsapp(result.whatsappNumber),
        ownerId: result.ownerId!,
        tenantId: result.tenantId!,
        licenseId: result.licenseId,
      );
      if (mounted) {
        showAppSnackBar(context, AppStrings.savedSuccessfully);
        _reload();
      }
    } catch (e) {
      if (mounted) showAppSnackBar(context, AppError.from(e).message);
    }
  }

  Future<void> _editCompany(
    Company company,
    List<Map<String, dynamic>> licenses,
  ) async {
    final apiClient = context.read<ApiClient>();
    final result = await showDialog<CompanyFormData>(
      context: context,
      builder: (_) => _CompanyFormDialog(company: company, licenses: licenses),
    );
    if (result == null) return;
    try {
      await AdminService(apiClient).updateCompany(
        company.id,
        name: result.name,
        whatsappNumber: result.whatsappNumber,
        licenseId: result.licenseId,
        isEnabled: result.isEnabled,
      );
      if (mounted) {
        showAppSnackBar(context, AppStrings.savedSuccessfully);
        _reload();
      }
    } catch (e) {
      if (mounted) showAppSnackBar(context, AppError.from(e).message);
    }
  }

  Future<void> _toggleCompany(Company company) async {
    final apiClient = context.read<ApiClient>();
    try {
      await AdminService(apiClient).updateCompany(
        company.id,
        isEnabled: !company.isEnabled,
      );
      if (mounted) {
        showAppSnackBar(context, AppStrings.savedSuccessfully);
        _reload();
      }
    } catch (e) {
      if (mounted) showAppSnackBar(context, AppError.from(e).message);
    }
  }

  Future<void> _deleteCompany(Company company) async {
    final apiClient = context.read<ApiClient>();
    final confirmed = await confirmAction(
      context,
      title: AppStrings.deleteCompanyAdminTitle,
      message: AppStrings.deleteCompanyAdminMessage,
    );
    if (!confirmed) return;
    try {
      await AdminService(apiClient).deleteCompany(company.id);
      if (mounted) {
        showAppSnackBar(context, AppStrings.deletedSuccessfully);
        _reload();
      }
    } catch (e) {
      if (mounted) showAppSnackBar(context, AppError.from(e).message);
    }
  }

  void _viewCatalog(Company company) {
    context.push("/public-catalog/${company.id}", extra: company.name);
  }

  void _onCompanyMenu(Company company, String value,
      List<Map<String, dynamic>> licenses) {
    switch (value) {
      case "view":
        _viewCatalog(company);
      case "edit":
        _editCompany(company, licenses);
      case "toggle":
        _toggleCompany(company);
      case "delete":
        _deleteCompany(company);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.adminCompanies),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: AppStrings.logout,
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      floatingActionButton: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          final users = snapshot.data?.$2 ?? const [];
          final licenses = snapshot.data?.$3 ?? const [];
          return FloatingActionButton(
            onPressed: () => _createCompany(users, licenses),
            child: const Icon(Icons.add),
          );
        },
      ),
      body: FutureBuilder<
          (
            List<Company>,
            List<Map<String, dynamic>>,
            List<Map<String, dynamic>>
          )>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoading();
          }
          if (snapshot.hasError) {
            return AppErrorView(
              message: AppError.from(snapshot.error!).message,
              onRetry: _reload,
            );
          }
          final companies = snapshot.data?.$1 ?? [];
          final users = snapshot.data?.$2 ?? const [];
          final licenses = snapshot.data?.$3 ?? const [];
          if (companies.isEmpty) {
            return const AppEmptyState(
              icon: Icons.business,
              title: AppStrings.adminCompanies,
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: companies.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final c = companies[index];
                return _CompanyCard(
                  company: c,
                  ownerName: _ownerName(c.ownerId, users),
                  licenseName: _licenseName(c.licenseId, licenses),
                  onTap: () => _viewCatalog(c),
                  onMenu: (value) => _onCompanyMenu(c, value, licenses),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _ownerName(dynamic ownerId, List<Map<String, dynamic>> users) {
    final id = ownerId?.toString();
    if (id == null || id.isEmpty) return AppStrings.noLicense;
    for (final u in users) {
      if (u["id"]?.toString() == id) {
        final first = u["firstName"]?.toString() ?? "";
        final last = u["lastName"]?.toString() ?? "";
        final name = "$first $last".trim();
        return name.isNotEmpty ? name : (u["email"]?.toString() ?? id);
      }
    }
    return AppStrings.noLicense;
  }

  String _licenseName(dynamic licenseId, List<Map<String, dynamic>> licenses) {
    final id = licenseId?.toString();
    if (id == null || id.isEmpty) return AppStrings.noLicense;
    for (final l in licenses) {
      if (l["id"]?.toString() == id) return l["name"]?.toString() ?? id;
    }
    return AppStrings.noLicense;
  }
}

class _CompanyCard extends StatelessWidget {
  final Company company;
  final String ownerName;
  final String licenseName;
  final VoidCallback onTap;
  final void Function(String value) onMenu;

  const _CompanyCard({
    required this.company,
    required this.ownerName,
    required this.licenseName,
    required this.onTap,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = company.isEnabled;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  enabled ? Icons.business : Icons.business_center,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              title: Row(
                children: [
                  Flexible(
                    child: Text(
                      company.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: enabled
                          ? AppColors.successContainer
                          : AppColors.dangerContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      enabled
                          ? AppStrings.activeLabel
                          : AppStrings.inactiveLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: enabled
                            ? AppColors.onSuccessContainer
                            : AppColors.onDangerContainer,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    "${AppStrings.ownerLabel}: $ownerName",
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    "${AppStrings.licenseLabel}: $licenseName",
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    "${AppStrings.whatsAppPrefix}${displayWhatsapp(company.whatsappNumber)}",
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                tooltip: "Opciones",
                onSelected: onMenu,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: "view",
                    child: Text(AppStrings.viewCatalog),
                  ),
                  const PopupMenuItem(
                    value: "edit",
                    child: Text(AppStrings.editCompany),
                  ),
                  PopupMenuItem(
                    value: "toggle",
                    child: Text(
                      enabled ? AppStrings.deactivate : AppStrings.activate,
                    ),
                  ),
                  const PopupMenuItem(
                    value: "delete",
                    child: Text(AppStrings.delete),
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

class CompanyFormData {
  final String? id;
  final String name;
  final String whatsappNumber;
  final String? ownerId;
  final String? tenantId;
  final String? licenseId;
  final bool isEnabled;

  CompanyFormData({
    this.id,
    required this.name,
    required this.whatsappNumber,
    this.ownerId,
    this.tenantId,
    this.licenseId,
    required this.isEnabled,
  });

  bool get isEdit => id != null;
}

class _CompanyFormDialog extends StatefulWidget {
  final Company? company;
  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> licenses;

  const _CompanyFormDialog({
    this.company,
    this.users = const [],
    required this.licenses,
  });

  @override
  State<_CompanyFormDialog> createState() => _CompanyFormDialogState();
}

class _CompanyFormDialogState extends State<_CompanyFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final bool _isEdit;
  late final TextEditingController _name;
  late final TextEditingController _whatsapp;
  late String? _ownerId;
  late String? _tenantId;
  String? _licenseId;
  late bool _isEnabled;

  @override
  void initState() {
    super.initState();
    final company = widget.company;
    _isEdit = company != null;
    _name = TextEditingController(text: company?.name ?? "");
    _whatsapp = TextEditingController(
      text: company != null
          ? displayWhatsapp(company.whatsappNumber)
          : "",
    );
    _ownerId = company?.ownerId;
    _tenantId = _tenantFor(company?.ownerId);
    _licenseId = company?.licenseId;
    _isEnabled = company?.isEnabled ?? true;
  }

  String? _tenantFor(String? ownerId) {
    if (ownerId == null) return null;
    for (final u in widget.users) {
      if (u["id"]?.toString() == ownerId) {
        return u["tenantId"]?.toString();
      }
    }
    return null;
  }

  List<Map<String, dynamic>> get _owners => widget.users
      .where((u) => (u["role"]?.toString() ?? "") == "OWNER")
      .toList();

  @override
  void dispose() {
    _name.dispose();
    _whatsapp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? AppStrings.editCompany : AppStrings.newCompany),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: AppStrings.nameLabel,
                ),
                validator: requiredMaxLengthValidator(100),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _whatsapp,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: AppStrings.whatsappLabel,
                ),
                validator: whatsappValidator,
              ),
              const SizedBox(height: 12),
              if (_isEdit)
                const Text(
                  AppStrings.assignCompanyOwner,
                  style: TextStyle(fontSize: 14),
                )
              else
                DropdownButtonFormField<String?>(
                  initialValue: _ownerId,
                  decoration: InputDecoration(
                    labelText: AppStrings.selectOwner,
                  ),
                  items: [
                    for (final u in _owners)
                      DropdownMenuItem<String?>(
                        value: u["id"]?.toString(),
                        child: Text(_userLabel(u)),
                      ),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _ownerId = v;
                      _tenantId = v == null
                          ? null
                          : _tenantFor(v);
                    });
                  },
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _licenseId,
                decoration: const InputDecoration(
                  labelText: AppStrings.licenseLabel,
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text(AppStrings.noLicense),
                  ),
                  for (final l in widget.licenses)
                    DropdownMenuItem<String?>(
                      value: l["id"]?.toString(),
                      child: Text(l["name"]?.toString() ?? ""),
                    ),
                ],
                onChanged: (v) => setState(() => _licenseId = v),
              ),
              if (_isEdit) ...[
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    AppStrings.isEnabledLabel,
                    style: TextStyle(fontSize: 14),
                  ),
                  value: _isEnabled,
                  onChanged: (v) => setState(() => _isEnabled = v),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            if (!_isEdit && (_ownerId == null || _tenantId == null)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(AppStrings.requiredField)),
              );
              return;
            }
            Navigator.pop(
              context,
              CompanyFormData(
                id: _isEdit ? widget.company!.id : null,
                name: _name.text.trim(),
                whatsappNumber: _whatsapp.text.trim(),
                ownerId: _ownerId,
                tenantId: _tenantId,
                licenseId: _licenseId,
                isEnabled: _isEnabled,
              ),
            );
          },
          child: Text(_isEdit ? AppStrings.save : AppStrings.create),
        ),
      ],
    );
  }

  String _userLabel(Map<String, dynamic> u) {
    final first = u["firstName"]?.toString() ?? "";
    final last = u["lastName"]?.toString() ?? "";
    final name = "$first $last".trim();
    final email = u["email"]?.toString() ?? "";
    return name.isNotEmpty ? "$name ($email)" : email;
  }
}
