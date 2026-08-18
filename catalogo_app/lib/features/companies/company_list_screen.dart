import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/company.dart';
import '../../core/theme/app_colors.dart';
import '../companies/company_provider.dart';
import '../../shared/widgets/app_dialog.dart';
import '../../shared/widgets/app_empty_state.dart';
import '../../shared/widgets/app_error_view.dart';
import '../../shared/widgets/app_loading.dart';

class CompanyListScreen extends StatefulWidget {
  const CompanyListScreen({super.key});

  @override
  State<CompanyListScreen> createState() => _CompanyListScreenState();
}

class _CompanyListScreenState extends State<CompanyListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CompanyProvider>().load();
    });
  }

  Future<void> _deleteCompany(Company company) async {
    final provider = context.read<CompanyProvider>();
    final confirmed = await confirmAction(
      context,
      title: AppStrings.deleteCompanyTitle,
      message: AppStrings.deleteCompanyMessage,
    );
    if (!confirmed) return;
    await provider.delete(company.id);
  }

  Future<void> _copyLink(Company company) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(
        ClipboardData(text: ApiClient.catalogUrl(company.id)));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(AppStrings.linkCopied)));
  }

  Future<void> _onMenuSelected(Company company, String value) async {
    switch (value) {
      case "edit":
        final provider = context.read<CompanyProvider>();
        await context.push("/companies/${company.id}/edit", extra: company);
        if (context.mounted) provider.refresh();
      case "catalog":
        await context.push("/public-catalog/${company.id}", extra: company.name);
      case "share":
        await Share.share(
          AppStrings.shareCatalogText
              .replaceFirst("{name}", company.name)
              .replaceFirst("{url}", ApiClient.catalogUrl(company.id)),
        );
      case "copy":
        await _copyLink(company);
      case "delete":
        await _deleteCompany(company);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CompanyProvider>();
    final companies = provider.companies;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.companiesTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: AppStrings.logout,
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final provider = context.read<CompanyProvider>();
          await context.push("/companies/new");
          if (context.mounted) provider.refresh();
        },
        child: const Icon(Icons.add),
      ),
      body: _buildBody(provider, companies),
    );
  }

  Widget _buildBody(CompanyProvider provider, List<Company> companies) {
    if (provider.isLoading && companies.isEmpty) {
      return const AppLoading();
    }
    if (companies.isEmpty) {
      if (provider.error != null) {
        return AppErrorView(
          message: provider.error!,
          onRetry: () => context.read<CompanyProvider>().refresh(),
        );
      }
      return const AppEmptyState(
        icon: Icons.store,
        title: AppStrings.noCompanies,
        message: AppStrings.noCompaniesHint,
      );
    }
    return RefreshIndicator(
      onRefresh: () => context.read<CompanyProvider>().refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: companies.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final c = companies[index];
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.storefront,
                    color: AppColors.primary, size: 22),
              ),
              title: Text(
                c.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                "${AppStrings.whatsAppPrefix}${c.whatsappNumber}",
                style: const TextStyle(fontSize: 12),
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) => _onMenuSelected(c, value),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: "edit", child: Text(AppStrings.edit)),
                  PopupMenuItem(
                    value: "catalog",
                    child: Text(AppStrings.viewPublicCatalog),
                  ),
                  PopupMenuItem(
                    value: "share",
                    child: Text(AppStrings.shareCatalog),
                  ),
                  PopupMenuItem(
                    value: "copy",
                    child: Text(AppStrings.copyLink),
                  ),
                  PopupMenuItem(
                    value: "delete",
                    child: Text(AppStrings.delete),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}