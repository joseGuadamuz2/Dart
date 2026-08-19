import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/constants/app_strings.dart';
import '../../core/errors/app_error.dart';
import '../../core/theme/app_colors.dart';
import '../../core/validators/validators.dart';
import '../../shared/widgets/app_dialog.dart';
import '../../shared/widgets/app_empty_state.dart';
import '../../shared/widgets/app_error_view.dart';
import '../../shared/widgets/app_loading.dart';
import 'admin_service.dart';

class AdminLicensesScreen extends StatefulWidget {
  const AdminLicensesScreen({super.key});

  @override
  State<AdminLicensesScreen> createState() => _AdminLicensesScreenState();
}

class _AdminLicensesScreenState extends State<AdminLicensesScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = AdminService(context.read<ApiClient>()).listLicenses();
  }

  Future<void> _reload() async {
    setState(() {
      _future = AdminService(context.read<ApiClient>()).listLicenses();
    });
    await _future;
  }

  Future<void> _createLicense() async {
    final apiClient = context.read<ApiClient>();
    final result = await showDialog<LicenseFormData>(
      context: context,
      builder: (_) => const _LicenseFormDialog(),
    );
    if (result == null) return;
    try {
      await AdminService(apiClient).createLicense(result.toCreateJson());
      if (mounted) {
        showAppSnackBar(context, AppStrings.savedSuccessfully);
        _reload();
      }
    } catch (e) {
      if (mounted) showAppSnackBar(context, AppError.from(e).message);
    }
  }

  Future<void> _editLicense(Map<String, dynamic> license) async {
    final apiClient = context.read<ApiClient>();
    final result = await showDialog<LicenseFormData>(
      context: context,
      builder: (_) => _LicenseFormDialog(license: license),
    );
    if (result == null) return;
    try {
      await AdminService(apiClient)
          .updateLicense(license["id"].toString(), result.toUpdateJson());
      if (mounted) {
        showAppSnackBar(context, AppStrings.savedSuccessfully);
        _reload();
      }
    } catch (e) {
      if (mounted) showAppSnackBar(context, AppError.from(e).message);
    }
  }

  Future<void> _toggleLicense(Map<String, dynamic> license) async {
    final apiClient = context.read<ApiClient>();
    try {
      await AdminService(apiClient).updateLicense(
        license["id"].toString(),
        {"isEnabled": license["isEnabled"] != true},
      );
      if (mounted) {
        showAppSnackBar(context, AppStrings.savedSuccessfully);
        _reload();
      }
    } catch (e) {
      if (mounted) showAppSnackBar(context, AppError.from(e).message);
    }
  }

  Future<void> _deleteLicense(Map<String, dynamic> license) async {
    final apiClient = context.read<ApiClient>();
    final confirmed = await confirmAction(
      context,
      title: AppStrings.deleteLicenseTitle,
      message: AppStrings.deleteLicenseMessage,
    );
    if (!confirmed) return;
    try {
      await AdminService(apiClient).deleteLicense(license["id"].toString());
      if (mounted) {
        showAppSnackBar(context, AppStrings.deletedSuccessfully);
        _reload();
      }
    } catch (e) {
      if (mounted) showAppSnackBar(context, AppError.from(e).message);
    }
  }

  void _onLicenseMenu(Map<String, dynamic> license, String value) {
    switch (value) {
      case "edit":
        _editLicense(license);
      case "toggle":
        _toggleLicense(license);
      case "delete":
        _deleteLicense(license);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.adminLicenses),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: AppStrings.logout,
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createLicense,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
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
          final licenses = snapshot.data ?? [];
          if (licenses.isEmpty) {
            return const AppEmptyState(
              icon: Icons.verified_user,
              title: AppStrings.adminLicenses,
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: licenses.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final l = licenses[index];
                return _LicenseCard(
                  license: l,
                  onMenu: (value) => _onLicenseMenu(l, value),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _LicenseCard extends StatelessWidget {
  final Map<String, dynamic> license;
  final void Function(String value) onMenu;

  const _LicenseCard({
    required this.license,
    required this.onMenu,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return AppStrings.noExpiration;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return "${date.year}-$month-$day";
  }

  @override
  Widget build(BuildContext context) {
    final name = license["name"]?.toString() ?? "";
    final maxCompanies = license["maxCompanies"]?.toString() ?? "0";
    final maxProducts = license["maxProducts"]?.toString() ?? "0";
    final expiresAt = DateTime.tryParse(license["expiresAt"]?.toString() ?? "");
    final enabled = license["isEnabled"] != false;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            enabled ? Icons.verified_user : Icons.verified_user_outlined,
            color: AppColors.primary,
            size: 22,
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                name,
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: enabled
                    ? AppColors.successContainer
                    : AppColors.dangerContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                enabled ? AppStrings.activeLabel : AppStrings.inactiveLabel,
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
        subtitle: Text(
          "${AppStrings.maxCompaniesLabel}: $maxCompanies · "
          "${AppStrings.maxProductsLabel}: $maxProducts\n"
          "${AppStrings.expiresAtLabel}: ${_formatDate(expiresAt)}",
          style: const TextStyle(fontSize: 12),
        ),
        trailing: PopupMenuButton<String>(
          tooltip: "Opciones",
          onSelected: onMenu,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: "edit",
              child: Text(AppStrings.editLicense),
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
    );
  }
}

class LicenseFormData {
  final String? id;
  final String name;
  final int maxCompanies;
  final int maxProducts;
  final DateTime? expiresAt;
  final bool isEnabled;

  LicenseFormData({
    this.id,
    required this.name,
    required this.maxCompanies,
    required this.maxProducts,
    this.expiresAt,
    required this.isEnabled,
  });

  bool get isEdit => id != null;

  Map<String, dynamic> toCreateJson() => {
        "name": name,
        "maxCompanies": maxCompanies,
        "maxProducts": maxProducts,
        if (expiresAt != null) "expiresAt": expiresAt!.toIso8601String(),
      };

  Map<String, dynamic> toUpdateJson() => {
        "name": name,
        "maxCompanies": maxCompanies,
        "maxProducts": maxProducts,
        if (expiresAt != null) "expiresAt": expiresAt!.toIso8601String(),
        "isEnabled": isEnabled,
      };
}

class _LicenseFormDialog extends StatefulWidget {
  final Map<String, dynamic>? license;

  const _LicenseFormDialog({this.license});

  @override
  State<_LicenseFormDialog> createState() => _LicenseFormDialogState();
}

class _LicenseFormDialogState extends State<_LicenseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final bool _isEdit;
  late final TextEditingController _name;
  late final TextEditingController _maxCompanies;
  late final TextEditingController _maxProducts;
  late DateTime? _expiresAt;
  late bool _isEnabled;

  @override
  void initState() {
    super.initState();
    final license = widget.license;
    _isEdit = license != null;
    _name = TextEditingController(text: license?["name"]?.toString() ?? "");
    _maxCompanies = TextEditingController(
      text: license?["maxCompanies"]?.toString() ?? "",
    );
    _maxProducts = TextEditingController(
      text: license?["maxProducts"]?.toString() ?? "",
    );
    _expiresAt =
        DateTime.tryParse(license?["expiresAt"]?.toString() ?? "");
    _isEnabled = license?["isEnabled"] != false;
  }

  @override
  void dispose() {
    _name.dispose();
    _maxCompanies.dispose();
    _maxProducts.dispose();
    super.dispose();
  }

  Future<void> _pickExpiresAt() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? DateTime(now.year + 1, now.month, now.day),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _expiresAt = picked);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return AppStrings.noExpiration;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return "${date.year}-$month-$day";
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? AppStrings.editLicense : AppStrings.createLicense),
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
                validator: requiredValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _maxCompanies,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: AppStrings.maxCompaniesLabel,
                ),
                validator: (v) {
                  final error = requiredValidator(v);
                  if (error != null) return error;
                  if (int.tryParse(v!.trim()) == null ||
                      int.parse(v.trim()) < 1) {
                    return AppStrings.pricePositive;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _maxProducts,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: AppStrings.maxProductsLabel,
                ),
                validator: (v) {
                  final error = requiredValidator(v);
                  if (error != null) return error;
                  if (int.tryParse(v!.trim()) == null ||
                      int.parse(v.trim()) < 1) {
                    return AppStrings.pricePositive;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickExpiresAt,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: AppStrings.expiresAtLabel,
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _formatDate(_expiresAt),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
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
            Navigator.pop(
              context,
              LicenseFormData(
                id: _isEdit ? widget.license!["id"].toString() : null,
                name: _name.text.trim(),
                maxCompanies: int.parse(_maxCompanies.text.trim()),
                maxProducts: int.parse(_maxProducts.text.trim()),
                expiresAt: _expiresAt,
                isEnabled: _isEnabled,
              ),
            );
          },
          child: Text(_isEdit ? AppStrings.save : AppStrings.create),
        ),
      ],
    );
  }
}