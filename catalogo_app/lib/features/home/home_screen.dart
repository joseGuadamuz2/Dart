import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/company.dart';
import '../../shared/widgets/app_dialog.dart';
import '../../shared/widgets/app_empty_state.dart';
import '../../shared/widgets/app_error_view.dart';
import '../../shared/widgets/app_loading.dart';
import '../companies/company_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CompanyProvider>().load();
    });
  }

  Future<void> _shareCatalog(Company company) async {
    await Share.share(
      AppStrings.shareCatalogText
          .replaceFirst("{name}", company.name)
          .replaceFirst("{url}", ApiClient.catalogUrl(company.id)),
    );
  }

  Future<void> _copyLink(Company company) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: ApiClient.catalogUrl(company.id)));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(AppStrings.linkCopied)));
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

  Future<void> _onMenuSelected(Company company, String value) async {
    switch (value) {
      case "catalog":
        await context.push("/public-catalog/${company.id}", extra: company.name);
      case "share":
        await _shareCatalog(company);
      case "copy":
        await _copyLink(company);
      case "edit":
        final provider = context.read<CompanyProvider>();
        await context.push("/companies/${company.id}/edit", extra: company);
        if (context.mounted) provider.refresh();
      case "delete":
        await _deleteCompany(company);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isAdmin = user?.isAdmin ?? false;
    final provider = context.watch<CompanyProvider>();
    final companies = provider.companies;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: AppStrings.logout,
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<CompanyProvider>().refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (user != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.greeting.replaceFirst("{name}", user.fullName),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${user.email} · ${user.role}",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (isAdmin) ...[
              _menuTile(context, AppStrings.adminCompanies, Icons.business,
                  "/admin/companies"),
              _menuTile(context, AppStrings.adminUsers, Icons.group,
                  "/admin/users"),
              _menuTile(context, AppStrings.adminLicenses, Icons.verified_user,
                  "/admin/licenses"),
              const SizedBox(height: 16),
            ],
            _buildCompaniesSection(provider, companies),
          ],
        ),
      ),
    );
  }

  Widget _buildCompaniesSection(CompanyProvider provider, List<Company> companies) {
    if (provider.isLoading && companies.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: AppLoading(),
      );
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
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(AppStrings.sectionCompanies,
              style: Theme.of(context).textTheme.titleMedium),
        ),
        for (final company in companies)
          Card(
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              controlAffinity: ListTileControlAffinity.leading,
              leading: const Icon(Icons.expand_more),
              title: Row(
                children: [
                  const Icon(Icons.store),
                  const SizedBox(width: 8),
                  Expanded(child: Text(company.name)),
                ],
              ),
              subtitle: Text(
                "${AppStrings.whatsAppPrefix}${company.whatsappNumber}",
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.share),
                    tooltip: AppStrings.shareCatalog,
                    onPressed: () => _shareCatalog(company),
                  ),
                  PopupMenuButton<String>(
                    tooltip: "Configuración",
                    onSelected: (value) => _onMenuSelected(company, value),
                    itemBuilder: (context) => const [
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
                        value: "edit",
                        child: Text(AppStrings.configureCompany),
                      ),
                      PopupMenuItem(
                        value: "delete",
                        child: Text(AppStrings.delete),
                      ),
                    ],
                  ),
                ],
              ),
              childrenPadding: const EdgeInsets.only(bottom: 8),
              children: [
                ListTile(
                  leading: const Icon(Icons.public),
                  title: const Text(AppStrings.viewPublicCatalog),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(
                    "/public-catalog/${company.id}",
                    extra: company.name,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.shopping_bag),
                  title: const Text(AppStrings.productsTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(
                    "/companies/${company.id}/products",
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.category),
                  title: const Text(AppStrings.categoriesTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(
                    "/companies/${company.id}/categories",
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        _menuTile(
          context,
          AppStrings.manageMyCompanies,
          Icons.manage_accounts,
          "/companies",
        ),
      ],
    );
  }

  Widget _menuTile(BuildContext context, String title, IconData icon,
      String route) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          final provider = context.read<CompanyProvider>();
          await context.push(route);
          if (context.mounted) provider.refresh();
        },
      ),
    );
  }
}