import 'package:cift_teker_front/models/requests/updateSharedRoute_request.dart';
import 'package:cift_teker_front/models/responses/sharedRoute_response.dart';
import 'package:cift_teker_front/services/sharedRoute_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EditSharedRoutePage extends StatefulWidget {
  final SharedRouteResponse sharedRoute;

  const EditSharedRoutePage({super.key, required this.sharedRoute});

  @override
  State<EditSharedRoutePage> createState() => _EditSharedRoutePageState();
}

class _EditSharedRoutePageState extends State<EditSharedRoutePage> {
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();
  final _sharedRouteService = SharedRouteService();

  late TextEditingController _routeNameController;
  late TextEditingController _descriptionController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _routeNameController = TextEditingController(
      text: widget.sharedRoute.routeName,
    );
    _descriptionController = TextEditingController(
      text: widget.sharedRoute.description,
    );
  }

  @override
  void dispose() {
    _routeNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final token = await _storage.read(key: "auth_token");
      if (token == null) return;

      final request = UpdateSharedRouteRequest(
        routeName: _routeNameController.text,
        description: _descriptionController.text,
      );

      await _sharedRouteService.updateSharedRoute(
        widget.sharedRoute.sharedRouteId,
        request,
        token,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Güncelleme başarısız")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Paylaşımı Düzenle")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              //Başlık
              TextFormField(
                controller: _routeNameController,
                decoration: const InputDecoration(labelText: "Başlık"),
                validator: (v) =>
                    v == null || v.isEmpty ? "Zorunlu alan" : null,
              ),

              const SizedBox(height: 12),

              //Açıklama
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: "Açıklama"),
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Güncelle"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
