import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/company.dart';
import '../companies/company_service.dart';
import '../products/product_model.dart';
import '../products/product_service.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key, this.initialCompanyId});

  final String? initialCompanyId;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  Future<List<Product>> _productsFuture = Future.value(<Product>[]);
  final List<Company> _companies = [];
  String? _companyId;
  bool _loadingCompanies = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    try {
      final companies = await CompanyService(ApiClient()).findMyCompanies();
      if (!mounted) return;
      setState(() {
        _companies.addAll(companies);
        _loadingCompanies = false;
        if (_companies.isNotEmpty) {
          _companyId = widget.initialCompanyId != null &&
                  companies.any((c) => c.id == widget.initialCompanyId)
              ? widget.initialCompanyId
              : _companies.first.id;
        }
      });
      _loadProducts();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingCompanies = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _error = null;
      _productsFuture = _companyId == null
          ? Future.value(<Product>[])
          : ProductService(ApiClient()).getProducts(_companyId!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Productos"),
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
                _loadProducts();
              },
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: _companyId == null
          ? null
          : FloatingActionButton(
              onPressed: () async {
                await context.push("/products/new", extra: _companyId);
                _loadProducts();
              },
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildBody() {
    if (_loadingCompanies) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _companies.isEmpty) {
      return Center(child: Text("Error: $_error"));
    }
    if (_companyId == null) {
      return const Center(child: Text("Selecciona una empresa"));
    }
    return FutureBuilder<List<Product>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        final products = snapshot.data ?? [];
        if (products.isEmpty) {
          return const Center(child: Text("Sin productos"));
        }
        return ListView.separated(
          itemCount: products.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final p = products[index];
            return ListTile(
              leading: const Icon(Icons.shopping_bag),
              title: Text(p.name),
              subtitle: Text(
                "\$${p.finalPrice.toStringAsFixed(2)}"
                "${p.discountPercentage > 0 ? " (${p.discountPercentage}% off)" : ""}",
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == "edit") {
                    await context.push("/products/${p.id}/edit", extra: p);
                    _loadProducts();
                  } else if (value == "delete") {
                    await ProductService(ApiClient()).delete(p.id);
                    _loadProducts();
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
      },
    );
  }
}
