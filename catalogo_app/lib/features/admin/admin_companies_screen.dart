import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/constants/app_strings.dart';
import '../../core/errors/app_error.dart';
import '../../core/models/company.dart';
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
  late Future<List<Company>> _future;

  @override
  void initState() {
    super.initState();
    _future = AdminService(context.read<ApiClient>()).listCompanies();
  }

  Future<void> _reload() async {
    setState(() {
      _future = AdminService(context.read<ApiClient>()).listCompanies();
    });
    await _future;
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
      body: FutureBuilder<List<Company>>(
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
          final companies = snapshot.data ?? [];
          if (companies.isEmpty) {
            return const AppEmptyState(
              icon: Icons.business,
              title: AppStrings.noCompanies,
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              itemCount: companies.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final c = companies[index];
                return ListTile(
                  leading: const Icon(Icons.business),
                  title: Text(c.name),
                  subtitle: Text(
                    "${AppStrings.whatsAppPrefix}${c.whatsappNumber}",
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