import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/person_provider.dart';
import '../utils/theme.dart';

class AddPersonDialog extends StatefulWidget {
  const AddPersonDialog({super.key});

  @override
  State<AddPersonDialog> createState() => _AddPersonDialogState();
}

class _AddPersonDialogState extends State<AddPersonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _departmentController = TextEditingController();
  final _roleController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _departmentController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.person_add, color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Yeni Kişi Ekle',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad *',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ad soyad gereklidir';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-posta *',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'E-posta gereklidir';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Geçerli bir e-posta adresi girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Department Field
              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(
                  labelText: 'Departman',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                  hintText: 'ör: Yazılım, Pazarlama, İnsan Kaynakları',
                ),
              ),
              const SizedBox(height: 16),

              // Role Field
              TextFormField(
                controller: _roleController,
                decoration: const InputDecoration(
                  labelText: 'Pozisyon',
                  prefixIcon: Icon(Icons.work),
                  border: OutlineInputBorder(),
                  hintText: 'ör: Developer, Designer, Manager',
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('İptal'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _savePerson,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Text('Kaydet'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _savePerson() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final personProvider = Provider.of<PersonProvider>(
        context,
        listen: false,
      );

      await personProvider.createPerson(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        department:
            _departmentController.text.trim().isEmpty
                ? null
                : _departmentController.text.trim(),
        role:
            _roleController.text.trim().isEmpty
                ? null
                : _roleController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_nameController.text.trim()} başarıyla eklendi'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
