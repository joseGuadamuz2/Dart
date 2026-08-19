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

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  late Future<(List<Map<String, dynamic>>, List<Map<String, dynamic>>)>
      _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(List<Map<String, dynamic>>, List<Map<String, dynamic>>)> _load()
      async {
    final service = AdminService(context.read<ApiClient>());
    final results = await Future.wait<List<Map<String, dynamic>>>([
      service.listUsers(),
      service.listLicenses(),
    ]);
    return (results[0], results[1]);
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _createUser(
    List<Map<String, dynamic>> licenses,
    String defaultTenantId,
  ) async {
    final apiClient = context.read<ApiClient>();
    final result = await showDialog<UserFormData>(
      context: context,
      builder: (_) => _UserFormDialog(
        licenses: licenses,
        defaultTenantId: defaultTenantId,
      ),
    );
    if (result == null) return;
    try {
      await AdminService(apiClient).createUser(result.toCreateJson());
      if (mounted) {
        showAppSnackBar(context, AppStrings.savedSuccessfully);
        _reload();
      }
    } catch (e) {
      if (mounted) showAppSnackBar(context, AppError.from(e).message);
    }
  }

  Future<void> _editUser(
    Map<String, dynamic> user,
    List<Map<String, dynamic>> licenses,
  ) async {
    final apiClient = context.read<ApiClient>();
    final result = await showDialog<UserFormData>(
      context: context,
      builder: (_) => _UserFormDialog(user: user, licenses: licenses),
    );
    if (result == null) return;
    try {
      await AdminService(apiClient)
          .updateUser(user["id"].toString(), result.toUpdateJson());
      if (mounted) {
        showAppSnackBar(context, AppStrings.savedSuccessfully);
        _reload();
      }
    } catch (e) {
      if (mounted) showAppSnackBar(context, AppError.from(e).message);
    }
  }

  Future<void> _toggleUser(Map<String, dynamic> user) async {
    final apiClient = context.read<ApiClient>();
    try {
      await AdminService(apiClient).updateUser(
        user["id"].toString(),
        {"isEnabled": user["isEnabled"] != true},
      );
      if (mounted) {
        showAppSnackBar(context, AppStrings.savedSuccessfully);
        _reload();
      }
    } catch (e) {
      if (mounted) showAppSnackBar(context, AppError.from(e).message);
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final apiClient = context.read<ApiClient>();
    final confirmed = await confirmAction(
      context,
      title: AppStrings.deleteUserTitle,
      message: AppStrings.deleteUserMessage,
    );
    if (!confirmed) return;
    try {
      await AdminService(apiClient).deleteUser(user["id"].toString());
      if (mounted) {
        showAppSnackBar(context, AppStrings.deletedSuccessfully);
        _reload();
      }
    } catch (e) {
      if (mounted) showAppSnackBar(context, AppError.from(e).message);
    }
  }

  void _onUserMenu(Map<String, dynamic> user, String value,
      List<Map<String, dynamic>> licenses) {
    switch (value) {
      case "edit":
        _editUser(user, licenses);
      case "toggle":
        _toggleUser(user);
      case "delete":
        _deleteUser(user);
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultTenantId =
        context.read<AuthProvider>().user?.tenantId ?? "";
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.adminUsers),
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
          final licenses = snapshot.data?.$2 ?? const [];
          return FloatingActionButton(
            onPressed: () => _createUser(licenses, defaultTenantId),
            child: const Icon(Icons.add),
          );
        },
      ),
      body: FutureBuilder<(List<Map<String, dynamic>>, List<Map<String, dynamic>>)>(
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
          final users = snapshot.data?.$1 ?? [];
          final licenses = snapshot.data?.$2 ?? const [];
          if (users.isEmpty) {
            return const AppEmptyState(
              icon: Icons.person,
              title: AppStrings.adminUsers,
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final u = users[index];
                return _UserCard(
                  user: u,
                  licenseName: _licenseName(u["licenseId"], licenses),
                  onMenu: (value) => _onUserMenu(u, value, licenses),
                );
              },
            ),
          );
        },
      ),
    );
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

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final String licenseName;
  final void Function(String value) onMenu;

  const _UserCard({
    required this.user,
    required this.licenseName,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = user["firstName"]?.toString() ?? "";
    final lastName = user["lastName"]?.toString() ?? "";
    final email = user["email"]?.toString() ?? "";
    final role = user["role"]?.toString() ?? "";
    final enabled = user["isEnabled"] != false;

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
            enabled ? Icons.person : Icons.person_off,
            color: AppColors.primary,
            size: 22,
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                "$firstName $lastName",
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
                color: AppColors.accentContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                role,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onAccentContainer,
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
              email,
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              "$licenseName · ${enabled ? AppStrings.activeLabel : AppStrings.inactiveLabel}",
              style: TextStyle(
                fontSize: 12,
                color: enabled ? AppColors.success : AppColors.textMuted,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          tooltip: "Opciones",
          onSelected: onMenu,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: "edit",
              child: Text(AppStrings.editUser),
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

class UserFormData {
  final String? id;
  final String email;
  final String? password;
  final String firstName;
  final String lastName;
  final String birthDate;
  final String role;
  final String tenantId;
  final String? licenseId;
  final bool isEnabled;

  UserFormData({
    this.id,
    required this.email,
    this.password,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.role,
    required this.tenantId,
    this.licenseId,
    required this.isEnabled,
  });

  bool get isEdit => id != null;

  Map<String, dynamic> toCreateJson() => {
        "email": email,
        "password": password ?? "",
        "firstName": firstName,
        "lastName": lastName,
        "birthDate": birthDate,
        "role": role,
        "tenantId": tenantId,
        if (licenseId != null) "licenseId": licenseId,
      };

  Map<String, dynamic> toUpdateJson() => {
        "firstName": firstName,
        "lastName": lastName,
        "birthDate": birthDate,
        "role": role,
        "licenseId": licenseId,
        "isEnabled": isEnabled,
      };
}

class _UserFormDialog extends StatefulWidget {
  final Map<String, dynamic>? user;
  final List<Map<String, dynamic>> licenses;
  final String? defaultTenantId;

  const _UserFormDialog({
    this.user,
    required this.licenses,
    this.defaultTenantId,
  });

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final bool _isEdit;
  late final TextEditingController _email;
  late final TextEditingController _password;
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _tenantId;
  late DateTime? _birthDate;
  late String _role;
  String? _licenseId;
  late bool _isEnabled;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _isEdit = user != null;
    _email = TextEditingController(text: user?["email"]?.toString() ?? "");
    _password = TextEditingController();
    _firstName =
        TextEditingController(text: user?["firstName"]?.toString() ?? "");
    _lastName =
        TextEditingController(text: user?["lastName"]?.toString() ?? "");
    _tenantId = TextEditingController(
      text: user?["tenantId"]?.toString() ?? widget.defaultTenantId ?? "",
    );
    _birthDate = _parseDate(user?["birthDate"]?.toString());
    _role = user?["role"]?.toString() ?? "OWNER";
    _licenseId = user?["licenseId"]?.toString();
    _isEnabled = user?["isEnabled"] != false;
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _tenantId.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "";
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return "${date.year}-$month-$day";
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? AppStrings.editUser : AppStrings.createUser),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _email,
                enabled: !_isEdit,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: AppStrings.emailLabel,
                ),
                validator: emailValidator,
              ),
              if (!_isEdit) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: AppStrings.passwordLabel,
                  ),
                  validator: (v) {
                    final error = requiredValidator(v);
                    if (error != null) return error;
                    if ((v ?? "").trim().length < 8) {
                      return AppStrings.passwordMinLength;
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _firstName,
                decoration: const InputDecoration(
                  labelText: AppStrings.firstNameLabel,
                ),
                validator: requiredValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastName,
                decoration: const InputDecoration(
                  labelText: AppStrings.lastNameLabel,
                ),
                validator: requiredValidator,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickBirthDate,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: AppStrings.birthDateLabel,
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _formatDate(_birthDate),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tenantId,
                enabled: !_isEdit,
                decoration: const InputDecoration(
                  labelText: AppStrings.tenantIdLabel,
                ),
                validator: requiredValidator,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(
                  labelText: AppStrings.roleLabel,
                ),
                items: const [
                  DropdownMenuItem(value: "OWNER", child: Text("OWNER")),
                  DropdownMenuItem(value: "ADMIN", child: Text("ADMIN")),
                ],
                onChanged: (v) => setState(() => _role = v!),
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
            if (_birthDate == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(AppStrings.requiredField)),
              );
              return;
            }
            Navigator.pop(
              context,
              UserFormData(
                id: _isEdit ? widget.user!["id"].toString() : null,
                email: _email.text.trim(),
                password: _password.text.trim(),
                firstName: _firstName.text.trim(),
                lastName: _lastName.text.trim(),
                birthDate: _formatDate(_birthDate),
                role: _role,
                tenantId: _tenantId.text.trim(),
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
}