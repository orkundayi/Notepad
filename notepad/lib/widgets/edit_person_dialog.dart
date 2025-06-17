import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/person.dart';
import '../providers/person_provider.dart';
import '../utils/theme.dart';

class EditPersonDialog extends StatefulWidget {
  final Person person;

  const EditPersonDialog({super.key, required this.person});

  @override
  State<EditPersonDialog> createState() => _EditPersonDialogState();
}

class _EditPersonDialogState extends State<EditPersonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _departmentController = TextEditingController();
  final _roleController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.person.name;
    _emailController.text = widget.person.email;
    _departmentController.text = widget.person.department ?? '';
    _roleController.text = widget.person.role ?? '';
  }

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
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.edit_note, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Kişi Düzenle'),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad *',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ad soyad gereklidir';
                  }
                  if (value.trim().length < 2) {
                    return 'Ad soyad en az 2 karakter olmalıdır';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-posta *',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'E-posta gereklidir';
                  }
                  // Simple email validation
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value.trim())) {
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
                  helperText: 'Opsiyonel',
                ),
              ),
              const SizedBox(height: 16),

              // Role Field
              TextFormField(
                controller: _roleController,
                decoration: const InputDecoration(
                  labelText: 'Rol/Pozisyon',
                  prefixIcon: Icon(Icons.work),
                  helperText: 'Opsiyonel',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleUpdate,
          child:
              _isLoading
                  ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Güncelle'),
        ),
      ],
    );
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final personProvider = Provider.of<PersonProvider>(
        context,
        listen: false,
      );

      await personProvider.updatePerson(
        widget.person.id,
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
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kişi başarıyla güncellendi'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
