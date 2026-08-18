import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/api/api_client.dart';
import '../../core/models/category.dart';
import '../../core/models/company.dart';
import '../companies/company_service.dart';
import 'category_service.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key, this.initialCompanyId});

  final String? initialCompanyId;

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  List<Company> _companies = [];
  String? _companyId;
  List<Category>? _categories;
  bool _loadingCompanies = true;
  bool _loadingCategories = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    try {
      final companies = await CompanyService(ApiClient()).findMyCompanies();
      setState(() {
        _companies = companies;
        _loadingCompanies = false;
        if (companies.isNotEmpty) {
          _companyId = widget.initialCompanyId != null &&
                  companies.any((c) => c.id == widget.initialCompanyId)
              ? widget.initialCompanyId
              : companies.first.id;
        }
      });
      if (companies.isNotEmpty) _loadCategories();
    } catch (e) {
      setState(() {
        _loadingCompanies = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadCategories() async {
    if (_companyId == null) {
      setState(() => _categories = []);
      return;
    }
    setState(() {
      _loadingCategories = true;
      _error = null;
    });
    try {
      final categories =
          await CategoryService(ApiClient()).findByCompany(_companyId!);
      setState(() {
        _categories = categories;
        _loadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _loadingCategories = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Categorías"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              initialValue: _companyId,
              decoration: const InputDecoration(labelText: "Empresa"),
              items: _companies
                  .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: (value) {
                setState(() => _companyId = value);
                _loadCategories();
              },
            ),
          ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
      floatingActionButton: _companyId == null
          ? null
          : FloatingActionButton(
              onPressed: () async {
                await context.push("/categories/new", extra: _companyId);
                _loadCategories();
              },
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildBody() {
    if (_loadingCompanies || _loadingCategories) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) return Center(child: Text("Error: $_error"));
    if (_companyId == null) {
      return const Center(child: Text("Selecciona una empresa"));
    }
    final categories = _categories ?? [];
    if (categories.isEmpty) {
      return const Center(child: Text("Sin categorías para esta empresa"));
    }
    return ListView.separated(
      itemCount: categories.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final c = categories[index];
        return ListTile(
          leading: const Icon(Icons.category),
          title: Text(c.name),
          trailing: PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == "edit") {
                await context.push("/categories/${c.id}/edit", extra: c);
                _loadCategories();
              } else if (value == "delete") {
                await CategoryService(ApiClient()).delete(c.id);
                _loadCategories();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: "edit", child: Text("Editar")),
              PopupMenuItem(value: "delete", child: Text("Eliminar")),
            ],
          ),
        );
      },
    );
  }
}