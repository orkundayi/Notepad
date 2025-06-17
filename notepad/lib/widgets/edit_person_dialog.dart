import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/person.dart';
import '../providers/person_provider.dart';
import '../utils/theme.dart';
import '../utils/platform_utils.dart';

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
    return PlatformUtils.isWeb ? _buildWebDialog() : _buildMobileDialog();
  }

  Widget _buildWebDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: PlatformUtils.getDialogMaxWidth(context),
        constraints: const BoxConstraints(maxHeight: 650),
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
            // Header
            _buildWebHeader(),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: PlatformUtils.getDialogPadding(),
                child: _buildWebForm(),
              ),
            ),

            // Actions
            _buildWebActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileDialog() {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: PlatformUtils.getCardRadius(),
      ),
      title: _buildMobileHeader(),
      content: SizedBox(width: double.maxFinite, child: _buildMobileForm()),
      actions: _buildMobileActions(),
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
            child: Text(
              widget.person.name.isNotEmpty
                  ? widget.person.name[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kişi Düzenle',
                  style: PlatformUtils.getTitleStyle(
                    context,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.person.name} kişisinin bilgilerini güncelleyin',
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

  Widget _buildMobileHeader() {
    return Row(
      children: [
        const Icon(Icons.edit_note, color: AppColors.primary),
        const SizedBox(width: 8),
        const Text('Kişi Düzenle'),
      ],
    );
  }

  Widget _buildWebForm() {
    return Form(
      key: _formKey,
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
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: PlatformUtils.getButtonRadius(),
                ),
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
                hintText: 'E-posta adresini girin',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: PlatformUtils.getButtonRadius(),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'E-posta gereklidir';
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value)) {
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
                hintText: 'Departman adını girin (isteğe bağlı)',
                prefixIcon: const Icon(Icons.business),
                border: OutlineInputBorder(
                  borderRadius: PlatformUtils.getButtonRadius(),
                ),
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
                hintText: 'Pozisyon veya rolünü girin (isteğe bağlı)',
                prefixIcon: const Icon(Icons.work),
                border: OutlineInputBorder(
                  borderRadius: PlatformUtils.getButtonRadius(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
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
              ),
            ),
            const SizedBox(height: 16),

            // Role Field
            TextFormField(
              controller: _roleController,
              decoration: const InputDecoration(
                labelText: 'Pozisyon/Rol',
                prefixIcon: Icon(Icons.work),
              ),
            ),
          ],
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
          // Delete button
          TextButton.icon(
            onPressed: _isLoading ? null : _deletePerson,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: const Text('Sil', style: TextStyle(color: Colors.red)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
          const Spacer(),
          // Cancel and Save buttons
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
                    : const Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMobileActions() {
    return [
      TextButton(
        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
        child: const Text('İptal'),
      ),
      TextButton(
        onPressed: _isLoading ? null : _deletePerson,
        style: TextButton.styleFrom(foregroundColor: Colors.red),
        child: const Text('Sil'),
      ),
      ElevatedButton(
        onPressed: _isLoading ? null : _savePerson,
        child:
            _isLoading
                ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : const Text('Güncelle'),
      ),
    ];
  }

  void _savePerson() async {
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
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kişi başarıyla güncellendi'),
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

  void _deletePerson() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Kişiyi Sil'),
            content: Text(
              '${widget.person.name} kişisini silmek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Sil'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;
    setState(() => _isLoading = true);

    try {
      if (!mounted) return;
      final personProvider = Provider.of<PersonProvider>(
        context,
        listen: false,
      );
      await personProvider.deletePerson(widget.person.id);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kişi başarıyla silindi'),
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
