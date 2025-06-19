import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/person.dart';
import '../providers/person_provider.dart';
import '../providers/responsive_provider.dart';
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
    return Consumer<ResponsiveProvider>(
      builder: (context, responsive, child) {
        if (responsive.isMobile) {
          return _buildMobileDialog(responsive);
        } else {
          return _buildWebDialog(responsive);
        }
      },
    );
  }

  Widget _buildMobileDialog(ResponsiveProvider responsive) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(responsive.horizontalPadding),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(responsive.cardRadius),
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
            _buildMobileHeader(responsive),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(responsive.horizontalPadding),
                child: _buildMobileForm(responsive),
              ),
            ),
            // Actions
            _buildMobileActions(responsive),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileHeader(ResponsiveProvider responsive) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.horizontalPadding),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(responsive.cardRadius),
          topRight: Radius.circular(responsive.cardRadius),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.1),
            radius: 20,
            child: Text(
              widget.person.name.isNotEmpty
                  ? widget.person.name[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: responsive.subtitleFontSize,
              ),
            ),
          ),
          SizedBox(width: responsive.horizontalPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kişi Düzenle',
                  style: TextStyle(
                    fontSize: responsive.titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${widget.person.name} kişisinin bilgilerini güncelleyin',
                  style: TextStyle(
                    fontSize: responsive.bodyFontSize,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceVariant,
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileForm(ResponsiveProvider responsive) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMobileTextField(
            controller: _nameController,
            label: 'Ad Soyad *',
            hint: 'Kişinin adı ve soyadı',
            icon: Icons.person,
            responsive: responsive,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Lütfen ad soyad girin';
              }
              return null;
            },
          ),
          SizedBox(height: responsive.verticalSpacing),
          _buildMobileTextField(
            controller: _emailController,
            label: 'E-posta *',
            hint: 'ornek@email.com',
            icon: Icons.email,
            responsive: responsive,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Lütfen e-posta adresi girin';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Lütfen geçerli bir e-posta adresi girin';
              }
              return null;
            },
          ),
          SizedBox(height: responsive.verticalSpacing),
          _buildMobileTextField(
            controller: _departmentController,
            label: 'Departman',
            hint: 'Çalıştığı departman',
            icon: Icons.business,
            responsive: responsive,
          ),
          SizedBox(height: responsive.verticalSpacing),
          _buildMobileTextField(
            controller: _roleController,
            label: 'Pozisyon/Rol',
            hint: 'İş pozisyonu veya rolü',
            icon: Icons.work,
            responsive: responsive,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ResponsiveProvider responsive,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: responsive.bodyFontSize,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.verticalSpacing / 2),
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textHint,
              fontSize: responsive.bodyFontSize,
            ),
            prefixIcon: Icon(
              icon,
              color: AppColors.textSecondary,
              size: responsive.bodyFontSize * 1.4,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(responsive.cardRadius),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(responsive.cardRadius),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(responsive.cardRadius),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(responsive.cardRadius),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(responsive.cardRadius),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            contentPadding: EdgeInsets.symmetric(
              horizontal: responsive.horizontalPadding,
              vertical: responsive.verticalSpacing,
            ),
          ),
          style: TextStyle(
            fontSize: responsive.bodyFontSize,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileActions(ResponsiveProvider responsive) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.horizontalPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(responsive.cardRadius),
          bottomRight: Radius.circular(responsive.cardRadius),
        ),
      ),
      child: Column(
        children: [
          // Delete button (full width)
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: _isLoading ? null : _deletePerson,
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 16,
              ),
              label: Text(
                'Kişiyi Sil',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: responsive.bodyFontSize,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  vertical: responsive.verticalSpacing,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(responsive.buttonRadius),
                  side: const BorderSide(color: Colors.red, width: 1),
                ),
              ),
            ),
          ),
          SizedBox(height: responsive.verticalSpacing),
          // Cancel and Save buttons (full width in column for mobile)
          Column(
            children: [
              // Save button first (primary action)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePerson,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: responsive.verticalSpacing * 1.2,
                    ),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        responsive.buttonRadius,
                      ),
                    ),
                  ),
                  child:
                      _isLoading
                          ? SizedBox(
                            width: 20,
                            height: 20,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.save, size: 16),
                              SizedBox(width: responsive.horizontalPadding / 3),
                              Text(
                                'Güncelle',
                                style: TextStyle(
                                  fontSize: responsive.bodyFontSize,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                ),
              ),
              SizedBox(height: responsive.verticalSpacing / 2),
              // Cancel button second
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed:
                      _isLoading ? null : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: responsive.verticalSpacing,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        responsive.buttonRadius,
                      ),
                      side: BorderSide(
                        color: AppColors.textSecondary.withOpacity(0.3),
                      ),
                    ),
                  ),
                  child: Text(
                    'İptal',
                    style: TextStyle(
                      fontSize: responsive.bodyFontSize,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWebDialog(ResponsiveProvider responsive) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: responsive.isLargeDesktop ? 500 : 450,
        constraints: const BoxConstraints(maxHeight: 650),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(responsive.cardRadius),
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
            _buildWebHeader(responsive),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(responsive.horizontalPadding * 1.5),
                child: _buildWebForm(responsive),
              ),
            ),
            // Actions
            _buildWebActions(responsive),
          ],
        ),
      ),
    );
  }

  Widget _buildWebHeader(ResponsiveProvider responsive) {
    return Container(
      padding: EdgeInsets.all(responsive.horizontalPadding * 1.5),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(responsive.cardRadius),
          topRight: Radius.circular(responsive.cardRadius),
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
                fontSize: responsive.titleFontSize,
              ),
            ),
          ),
          SizedBox(width: responsive.horizontalPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kişi Düzenle',
                  style: TextStyle(
                    fontSize: responsive.titleFontSize * 1.1,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: responsive.verticalSpacing / 3),
                Text(
                  '${widget.person.name} kişisinin bilgilerini güncelleyin',
                  style: TextStyle(
                    fontSize: responsive.bodyFontSize,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceVariant,
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebForm(ResponsiveProvider responsive) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name Field
          _buildWebFormField(
            label: 'Ad Soyad',
            isRequired: true,
            responsive: responsive,
            child: TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Kişinin ad ve soyadını girin',
                hintStyle: TextStyle(
                  color: AppColors.textHint,
                  fontSize: responsive.bodyFontSize,
                ),
                prefixIcon: Icon(
                  Icons.person,
                  color: AppColors.textSecondary,
                  size: responsive.bodyFontSize * 1.4,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(responsive.buttonRadius),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(responsive.buttonRadius),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(responsive.buttonRadius),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: responsive.horizontalPadding,
                  vertical: responsive.verticalSpacing,
                ),
              ),
              style: TextStyle(
                fontSize: responsive.bodyFontSize,
                color: AppColors.textPrimary,
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

          SizedBox(height: responsive.verticalSpacing * 2),

          // Email Field
          _buildWebFormField(
            label: 'E-posta',
            isRequired: true,
            responsive: responsive,
            child: TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'E-posta adresini girin',
                hintStyle: TextStyle(
                  color: AppColors.textHint,
                  fontSize: responsive.bodyFontSize,
                ),
                prefixIcon: Icon(
                  Icons.email,
                  color: AppColors.textSecondary,
                  size: responsive.bodyFontSize * 1.4,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(responsive.buttonRadius),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(responsive.buttonRadius),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(responsive.buttonRadius),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: responsive.horizontalPadding,
                  vertical: responsive.verticalSpacing,
                ),
              ),
              style: TextStyle(
                fontSize: responsive.bodyFontSize,
                color: AppColors.textPrimary,
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

          SizedBox(height: responsive.verticalSpacing * 2),

          // Department Field
          _buildWebFormField(
            label: 'Departman',
            responsive: responsive,
            child: TextFormField(
              controller: _departmentController,
              decoration: InputDecoration(
                hintText: 'Departman adını girin (isteğe bağlı)',
                hintStyle: TextStyle(
                  color: AppColors.textHint,
                  fontSize: responsive.bodyFontSize,
                ),
                prefixIcon: Icon(
                  Icons.business,
                  color: AppColors.textSecondary,
                  size: responsive.bodyFontSize * 1.4,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(responsive.buttonRadius),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(responsive.buttonRadius),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(responsive.buttonRadius),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: responsive.horizontalPadding,
                  vertical: responsive.verticalSpacing,
                ),
              ),
              style: TextStyle(
                fontSize: responsive.bodyFontSize,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          SizedBox(height: responsive.verticalSpacing * 2),

          // Role Field
          _buildWebFormField(
            label: 'Pozisyon/Rol',
            responsive: responsive,
            child: TextFormField(
              controller: _roleController,
              decoration: InputDecoration(
                hintText: 'Pozisyon veya rolünü girin (isteğe bağlı)',
                hintStyle: TextStyle(
                  color: AppColors.textHint,
                  fontSize: responsive.bodyFontSize,
                ),
                prefixIcon: Icon(
                  Icons.work,
                  color: AppColors.textSecondary,
                  size: responsive.bodyFontSize * 1.4,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(responsive.buttonRadius),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(responsive.buttonRadius),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(responsive.buttonRadius),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: responsive.horizontalPadding,
                  vertical: responsive.verticalSpacing,
                ),
              ),
              style: TextStyle(
                fontSize: responsive.bodyFontSize,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebFormField({
    required String label,
    required Widget child,
    required ResponsiveProvider responsive,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (isRequired ? ' *' : ''),
          style: TextStyle(
            fontSize: responsive.subtitleFontSize,
            fontWeight: FontWeight.w600,
            color: isRequired ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
        SizedBox(height: responsive.verticalSpacing / 2),
        child,
      ],
    );
  }

  Widget _buildWebActions(ResponsiveProvider responsive) {
    return Container(
      padding: EdgeInsets.all(responsive.horizontalPadding * 1.5),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(responsive.cardRadius),
          bottomRight: Radius.circular(responsive.cardRadius),
        ),
      ),
      child: Row(
        children: [
          // Delete button
          TextButton.icon(
            onPressed: _isLoading ? null : _deletePerson,
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
            label: Text(
              'Sil',
              style: TextStyle(
                color: Colors.red,
                fontSize: responsive.bodyFontSize,
              ),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.horizontalPadding,
                vertical: responsive.verticalSpacing,
              ),
              side: const BorderSide(color: Colors.red, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(responsive.buttonRadius),
              ),
            ),
          ),
          const Spacer(),
          // Cancel and Save buttons
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.horizontalPadding * 1.5,
                vertical: responsive.verticalSpacing,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(responsive.buttonRadius),
              ),
            ),
            child: Text(
              'İptal',
              style: TextStyle(fontSize: responsive.bodyFontSize),
            ),
          ),
          SizedBox(width: responsive.horizontalPadding),
          ElevatedButton(
            onPressed: _isLoading ? null : _savePerson,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.horizontalPadding * 2,
                vertical: responsive.verticalSpacing,
              ),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(responsive.buttonRadius),
              ),
            ),
            child:
                _isLoading
                    ? SizedBox(
                      width: 20,
                      height: 20,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : Text(
                      'Güncelle',
                      style: TextStyle(fontSize: responsive.bodyFontSize),
                    ),
          ),
        ],
      ),
    );
  }

  void _savePerson() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final personProvider = Provider.of<PersonProvider>(
        context,
        listen: false,
      );

      final updatedPerson = widget.person.copyWith(
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
        updatedAt: DateTime.now(),
      );

      await personProvider.updatePerson(updatedPerson);

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
