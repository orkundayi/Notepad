import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/person_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';
import '../utils/platform_utils.dart';

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
    return _buildWebDialog();
  }

  Widget _buildWebDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: PlatformUtils.getDialogMaxWidth(context),
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: PlatformUtils.getCardRadius(),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildWebHeader(),
            Flexible(child: _buildWebForm()),
            _buildWebActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildWebHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.only(
          topLeft: PlatformUtils.getCardRadius().topLeft,
          topRight: PlatformUtils.getCardRadius().topRight,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.1),
            radius: 24,
            child: Icon(Icons.person_add, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yeni Kişi Ekle',
                  style: PlatformUtils.getTitleStyle(
                    context,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Projeye yeni bir kişi ekleyin',
                  style: PlatformUtils.getBodyStyle(
                    context,
                  ).copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[100],
              foregroundColor: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebForm() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name Field
              _buildWebFormField(
                label: 'Ad Soyad',
                isRequired: true,
                child: TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Kişinin ad ve soyadını girin',
                    prefixIcon: Icon(Icons.person, color: AppColors.primary),
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
              ),
              SizedBox(height: PlatformUtils.getSpacing(3)),

              // Email Field
              _buildWebFormField(
                label: 'E-posta',
                isRequired: true,
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'ornek@email.com',
                    prefixIcon: Icon(Icons.email, color: AppColors.primary),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'E-posta gereklidir';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value.trim())) {
                      return 'Geçerli bir e-posta adresi girin';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: PlatformUtils.getSpacing(3)),

              // Department Field
              _buildWebFormField(
                label: 'Departman',
                child: TextFormField(
                  controller: _departmentController,
                  decoration: InputDecoration(
                    hintText: 'Ör: Yazılım Geliştirme',
                    prefixIcon: Icon(Icons.business, color: AppColors.primary),
                  ),
                ),
              ),
              SizedBox(height: PlatformUtils.getSpacing(3)),

              // Role Field
              _buildWebFormField(
                label: 'Pozisyon/Rol',
                child: TextFormField(
                  controller: _roleController,
                  decoration: InputDecoration(
                    hintText: 'Ör: Senior Developer',
                    prefixIcon: Icon(Icons.work, color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebFormField({
    required String label,
    required Widget child,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (isRequired ? ' *' : ''),
          style: PlatformUtils.getSubtitleStyle(context).copyWith(
            fontWeight: FontWeight.w600,
            color: isRequired ? AppColors.primary : Colors.grey[700],
          ),
        ),
        SizedBox(height: PlatformUtils.getSpacing(1)),
        child,
      ],
    );
  }

  Widget _buildWebActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.only(
          bottomLeft: PlatformUtils.getCardRadius().bottomLeft,
          bottomRight: PlatformUtils.getCardRadius().bottomRight,
        ),
      ),
      child: Row(
        children: [
          const Spacer(),
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('İptal'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isLoading ? null : _savePerson,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: PlatformUtils.getButtonRadius(),
              ),
            ),
            child:
                _isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _savePerson() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final personProvider = Provider.of<PersonProvider>(
        context,
        listen: false,
      );
      final userId = authProvider.user?.uid;
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

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
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kişi başarıyla eklendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
