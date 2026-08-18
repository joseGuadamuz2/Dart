import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/constants/app_strings.dart';
import '../../core/errors/app_error.dart';
import '../../core/theme/app_colors.dart';
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
    final nameCtrl = TextEditingController();
    final companiesCtrl = TextEditingController();
    final productsCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.createLicense),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: AppStrings.nameLabel),
            ),
            TextField(
              controller: companiesCtrl,
              decoration: const InputDecoration(
                labelText: AppStrings.maxCompaniesLabel,
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: productsCtrl,
              decoration: const InputDecoration(
                labelText: AppStrings.maxProductsLabel,
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(AppStrings.create),
          ),
        ],
      ),
    );
    if (result == true) {
      await AdminService(apiClient).createLicense({
        "name": nameCtrl.text.trim(),
        "maxCompanies": int.tryParse(companiesCtrl.text.trim()) ?? 1,
        "maxProducts": int.tryParse(productsCtrl.text.trim()) ?? 1,
      });
      if (mounted) _reload();
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
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.verified_user,
                          color: AppColors.primary, size: 22),
                    ),
                    title: Text(
                      l["name"] ?? "",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      "${AppStrings.maxCompaniesLabel}: ${l["maxCompanies"]} · "
                      "${AppStrings.maxProductsLabel}: ${l["maxProducts"]}",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}