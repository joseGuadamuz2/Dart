import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/api/api_client.dart';
import '../../core/models/company.dart';
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
    final service = CompanyService(ApiClient());
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
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? "Editar empresa" : "Nueva empresa")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Nombre"),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? "Requerido" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _whatsappController,
                decoration: const InputDecoration(
                  labelText: "WhatsApp (506 + 8 dígitos)",
                  hintText: "50688888888",
                ),
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Requerido";
                  if (!RegExp(r"^506\d{8}$").hasMatch(v.trim())) {
                    return "Debe ser 506 + 8 dígitos";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (_isEditing) ...[
                Divider(),
                const SizedBox(height: 16),
                const Text(
                  "Tu catálogo",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "Comparte este enlace con tus clientes:",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Share.share(
                            "Mira el catálogo de ${_nameController.text.trim()}: ${ApiClient.catalogUrl(widget.company!.id)}",
                          );
                        },
                        icon: const Icon(Icons.share),
                        label: const Text("Compartir"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(
                              text: ApiClient.catalogUrl(widget.company!.id),
                            ),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Enlace copiado")),
                            );
                          }
                        },
                        icon: const Icon(Icons.link),
                        label: const Text("Copiar enlace"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(_isEditing ? "Guardar" : "Crear"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}