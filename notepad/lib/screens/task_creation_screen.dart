import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/task.dart';
import '../models/person.dart';
import '../providers/task_provider.dart';
import '../providers/person_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/responsive_provider.dart';
import '../utils/theme.dart';

class TaskCreationScreen extends StatefulWidget {
  final Task? task;

  const TaskCreationScreen({super.key, this.task});

  @override
  State<TaskCreationScreen> createState() => _TaskCreationScreenState();
}

class _TaskCreationScreenState extends State<TaskCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _taskNumberController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  TaskPriority _selectedPriority = TaskPriority.medium;
  TaskStatus _selectedStatus = TaskStatus.todo;
  Person? _selectedAssignee;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _taskNumberController.text = widget.task!.taskNumber;
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _selectedPriority = widget.task!.priority;
      _selectedStatus = widget.task!.status;
      // Set assignee if available
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final personProvider = Provider.of<PersonProvider>(
          context,
          listen: false,
        );
        final assignee =
            personProvider.people
                .where((p) => p.id == widget.task!.assignedToId)
                .firstOrNull;
        if (assignee != null) {
          setState(() => _selectedAssignee = assignee);
        }
      });
    }
  }

  @override
  void dispose() {
    _taskNumberController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ResponsiveProvider>(
      builder: (context, responsive, child) {
        if (responsive.isMobile) {
          return _buildMobileLayout();
        } else {
          return _buildWebLayout();
        }
      },
    );
  }

  Widget _buildWebLayout() {
    return Consumer<ResponsiveProvider>(
      builder: (context, responsive, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Row(
            children: [
              // Sidebar - sadece desktop'ta görünür
              if (responsive.isDesktop) ...[
                Container(
                  width: responsive.responsiveValue(
                    mobile: 280.0,
                    tablet: 280.0,
                    desktop: 320.0,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      right: BorderSide(color: AppColors.divider, width: 1),
                    ),
                  ),
                  child: _buildSidebar(responsive),
                ),
              ],
              // Main content
              Expanded(
                child: Container(
                  color: AppColors.background,
                  child: Column(
                    children: [
                      _buildWebHeader(responsive),
                      Expanded(child: _buildWebContent(responsive)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebar(ResponsiveProvider responsive) {
    return Column(
      children: [
        // Sidebar Header
        Container(
          padding: EdgeInsets.all(
            responsive.responsiveValue(mobile: 16.0, desktop: 24.0),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/dashboard');
                  }
                },
                icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                ),
              ),
              SizedBox(
                width: responsive.responsiveValue(mobile: 8.0, desktop: 12.0),
              ),
              Expanded(
                child: Text(
                  widget.task != null ? 'Görev Düzenle' : 'Yeni Görev',
                  style: TextStyle(
                    fontSize: responsive.getResponsiveFontSize(18),
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: AppColors.divider),
        // Sidebar Content
        Expanded(
          child: Container(
            padding: EdgeInsets.all(
              responsive.responsiveValue(mobile: 12.0, desktop: 16.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Görev Yönetimi',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    fontSize: responsive.getResponsiveFontSize(14),
                  ),
                ),
                SizedBox(
                  height: responsive.responsiveValue(
                    mobile: 12.0,
                    desktop: 16.0,
                  ),
                ),
                _buildSidebarAction(
                  icon: Icons.save,
                  title:
                      widget.task != null ? 'Görevi Güncelle' : 'Görevi Kaydet',
                  subtitle: 'Değişiklikleri kaydet',
                  onTap: _saveTask,
                  isLoading: _isLoading,
                  isPrimary: true,
                  responsive: responsive,
                ),
                SizedBox(
                  height: responsive.responsiveValue(
                    mobile: 8.0,
                    desktop: 12.0,
                  ),
                ),
                _buildSidebarAction(
                  icon: Icons.preview,
                  title: 'Önizleme',
                  subtitle: 'Görev detaylarını gözden geçir',
                  onTap: () {
                    // Önizleme functionality
                  },
                  responsive: responsive,
                ),
                SizedBox(
                  height: responsive.responsiveValue(
                    mobile: 8.0,
                    desktop: 12.0,
                  ),
                ),
                _buildSidebarAction(
                  icon: Icons.refresh,
                  title: 'Sıfırla',
                  subtitle: 'Formu temizle',
                  onTap: _resetForm,
                  responsive: responsive,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLoading = false,
    bool isPrimary = false,
    required ResponsiveProvider responsive,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(responsive.borderRadius),
      child: Container(
        padding: EdgeInsets.all(
          responsive.responsiveValue(mobile: 12.0, desktop: 16.0),
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color:
                isPrimary
                    ? AppColors.primary.withOpacity(0.3)
                    : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(responsive.borderRadius),
          color: isPrimary ? AppColors.primary.withOpacity(0.05) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    isPrimary
                        ? AppColors.primary.withOpacity(0.15)
                        : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  isLoading
                      ? SizedBox(
                        width: responsive.getResponsiveFontSize(16),
                        height: responsive.getResponsiveFontSize(16),
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Icon(
                        icon,
                        color:
                            isPrimary
                                ? AppColors.primary
                                : AppColors.textSecondary,
                        size: responsive.getResponsiveFontSize(16),
                      ),
            ),
            SizedBox(
              width: responsive.responsiveValue(mobile: 8.0, desktop: 12.0),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: responsive.getResponsiveFontSize(14),
                      color:
                          isPrimary ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: responsive.getResponsiveFontSize(12),
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebHeader(ResponsiveProvider responsive) {
    return Container(
      padding: EdgeInsets.all(
        responsive.responsiveValue(mobile: 16.0, desktop: 24.0),
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Row(
        children: [
          // Back button for tablet mode
          if (responsive.isTablet) ...[
            IconButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/dashboard');
                }
              },
              icon: const Icon(
                Icons.arrow_back,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(
              width: responsive.responsiveValue(mobile: 8.0, desktop: 12.0),
            ),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.task != null ? 'Görev Düzenle' : 'Yeni Görev Oluştur',
                  style: TextStyle(
                    fontSize: responsive.getResponsiveFontSize(24),
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(
                  height: responsive.responsiveValue(mobile: 2.0, desktop: 4.0),
                ),
                Text(
                  widget.task != null
                      ? 'Görev detaylarını güncelleyin'
                      : 'Yeni bir görev oluşturmak için formu doldurun',
                  style: TextStyle(
                    fontSize: responsive.getResponsiveFontSize(14),
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Save button for tablet mode
          if (responsive.isTablet) ...[
            SizedBox(
              width: responsive.responsiveValue(mobile: 8.0, desktop: 12.0),
            ),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveTask,
              icon:
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
                      : const Icon(Icons.save, size: 16),
              label: Text(
                widget.task != null ? 'Güncelle' : 'Kaydet',
                style: TextStyle(
                  fontSize: responsive.getResponsiveFontSize(14),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.responsiveValue(
                    mobile: 16.0,
                    desktop: 20.0,
                  ),
                  vertical: responsive.responsiveValue(
                    mobile: 8.0,
                    desktop: 12.0,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWebContent(ResponsiveProvider responsive) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(
        responsive.responsiveValue(mobile: 24.0, desktop: 40.0),
      ),
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: responsive.responsiveValue(
              mobile: double.infinity,
              tablet: 800.0,
              desktop: 1000.0,
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBasicInfoSection(responsive),
                SizedBox(
                  height: responsive.responsiveValue(
                    mobile: 24.0,
                    desktop: 32.0,
                  ),
                ),
                _buildDetailsSection(responsive),
                SizedBox(
                  height: responsive.responsiveValue(
                    mobile: 24.0,
                    desktop: 32.0,
                  ),
                ),
                _buildAssignmentSection(responsive),
                SizedBox(
                  height: responsive.responsiveValue(
                    mobile: 40.0,
                    desktop: 60.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection(ResponsiveProvider responsive) {
    return _buildSection(
      title: 'Temel Bilgiler',
      icon: Icons.info_outline_rounded,
      responsive: responsive,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 1,
                child: _buildTextField(
                  controller: _taskNumberController,
                  label: 'Görev Numarası',
                  hint: 'örn: GMO-4567',
                  icon: Icons.tag_rounded,
                  responsive: responsive,
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      if (!RegExp(r'^[A-Z]+-\d+$').hasMatch(value.trim())) {
                        return 'Format: ABC-123';
                      }
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(
                width: responsive.responsiveValue(mobile: 16.0, desktop: 20.0),
              ),
              Expanded(
                flex: 2,
                child: _buildTextField(
                  controller: _titleController,
                  label: 'Görev Başlığı *',
                  hint: 'Açıklayıcı bir başlık girin',
                  icon: Icons.title_rounded,
                  responsive: responsive,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Lütfen bir görev başlığı girin';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          SizedBox(
            height: responsive.responsiveValue(mobile: 16.0, desktop: 20.0),
          ),
          _buildTextField(
            controller: _descriptionController,
            label: 'Açıklama',
            hint: 'Yapılması gerekenleri açıklayın...',
            icon: Icons.description_rounded,
            maxLines: 4,
            responsive: responsive,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(ResponsiveProvider responsive) {
    return _buildSection(
      title: 'Görev Detayları',
      icon: Icons.settings_rounded,
      responsive: responsive,
      child: Row(
        children: [
          Expanded(child: _buildPriorityField(responsive)),
          SizedBox(
            width: responsive.responsiveValue(mobile: 16.0, desktop: 20.0),
          ),
          Expanded(child: _buildStatusField(responsive)),
        ],
      ),
    );
  }

  Widget _buildAssignmentSection(ResponsiveProvider responsive) {
    return _buildSection(
      title: 'Atama',
      icon: Icons.person_rounded,
      responsive: responsive,
      child: _buildAssigneeField(responsive),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
    required ResponsiveProvider responsive,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        responsive.responsiveValue(mobile: 16.0, desktop: 24.0),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppColors.primary,
                size: responsive.getResponsiveFontSize(20),
              ),
              SizedBox(
                width: responsive.responsiveValue(mobile: 8.0, desktop: 12.0),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: responsive.getResponsiveFontSize(18),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(
            height: responsive.responsiveValue(mobile: 16.0, desktop: 20.0),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ResponsiveProvider responsive,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: responsive.getResponsiveFontSize(14),
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.responsiveValue(mobile: 6.0, desktop: 8.0)),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textHint,
              fontSize: responsive.getResponsiveFontSize(14),
            ),
            prefixIcon: Icon(
              icon,
              color: AppColors.textSecondary,
              size: responsive.getResponsiveFontSize(20),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(responsive.borderRadius),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(responsive.borderRadius),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(responsive.borderRadius),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(responsive.borderRadius),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(responsive.borderRadius),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            contentPadding: EdgeInsets.symmetric(
              horizontal: responsive.responsiveValue(
                mobile: 12.0,
                desktop: 16.0,
              ),
              vertical: responsive.responsiveValue(mobile: 12.0, desktop: 14.0),
            ),
          ),
          style: TextStyle(
            fontSize: responsive.getResponsiveFontSize(14),
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityField(ResponsiveProvider responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Öncelik',
          style: TextStyle(
            fontSize: responsive.getResponsiveFontSize(14),
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.responsiveValue(mobile: 6.0, desktop: 8.0)),
        DropdownButtonFormField<TaskPriority>(
          value: _selectedPriority,
          onChanged: (TaskPriority? priority) {
            if (priority != null) {
              setState(() => _selectedPriority = priority);
            }
          },
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.priority_high_rounded,
              color: AppColors.textSecondary,
              size: responsive.getResponsiveFontSize(20),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(responsive.borderRadius),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(responsive.borderRadius),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(responsive.borderRadius),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            contentPadding: EdgeInsets.symmetric(
              horizontal: responsive.responsiveValue(
                mobile: 12.0,
                desktop: 16.0,
              ),
              vertical: responsive.responsiveValue(mobile: 12.0, desktop: 14.0),
            ),
          ),
          style: TextStyle(
            fontSize: responsive.getResponsiveFontSize(14),
            color: AppColors.textPrimary,
          ),
          items:
              TaskPriority.values.map((TaskPriority priority) {
                return DropdownMenuItem<TaskPriority>(
                  value: priority,
                  child: Text(priority.displayName),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatusField(ResponsiveProvider responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Durum',
          style: TextStyle(
            fontSize: responsive.getResponsiveFontSize(14),
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.responsiveValue(mobile: 6.0, desktop: 8.0)),
        DropdownButtonFormField<TaskStatus>(
          value: _selectedStatus,
          onChanged: (TaskStatus? status) {
            if (status != null) {
              setState(() => _selectedStatus = status);
            }
          },
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.flag_rounded,
              color: AppColors.textSecondary,
              size: responsive.getResponsiveFontSize(20),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(responsive.borderRadius),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(responsive.borderRadius),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(responsive.borderRadius),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            contentPadding: EdgeInsets.symmetric(
              horizontal: responsive.responsiveValue(
                mobile: 12.0,
                desktop: 16.0,
              ),
              vertical: responsive.responsiveValue(mobile: 12.0, desktop: 14.0),
            ),
          ),
          style: TextStyle(
            fontSize: responsive.getResponsiveFontSize(14),
            color: AppColors.textPrimary,
          ),
          items:
              TaskStatus.values.map((TaskStatus status) {
                return DropdownMenuItem<TaskStatus>(
                  value: status,
                  child: Text(status.displayName),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildAssigneeField(ResponsiveProvider responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Atanan Kişi',
          style: TextStyle(
            fontSize: responsive.getResponsiveFontSize(14),
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.responsiveValue(mobile: 6.0, desktop: 8.0)),
        Consumer<PersonProvider>(
          builder: (context, personProvider, child) {
            return DropdownButtonFormField<Person?>(
              value: _selectedAssignee,
              onChanged: (Person? person) {
                setState(() => _selectedAssignee = person);
              },
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.person_rounded,
                  color: AppColors.textSecondary,
                  size: responsive.getResponsiveFontSize(20),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(responsive.borderRadius),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(responsive.borderRadius),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(responsive.borderRadius),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: responsive.responsiveValue(
                    mobile: 12.0,
                    desktop: 16.0,
                  ),
                  vertical: responsive.responsiveValue(
                    mobile: 12.0,
                    desktop: 14.0,
                  ),
                ),
              ),
              style: TextStyle(
                fontSize: responsive.getResponsiveFontSize(14),
                color: AppColors.textPrimary,
              ),
              items: [
                const DropdownMenuItem<Person?>(
                  value: null,
                  child: Text('Atanmamış'),
                ),
                ...personProvider.people.map((Person person) {
                  return DropdownMenuItem<Person?>(
                    value: person,
                    child: Text(person.name),
                  );
                }),
              ],
            );
          },
        ),
      ],
    );
  }

  void _resetForm() {
    _taskNumberController.clear();
    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedPriority = TaskPriority.medium;
      _selectedStatus = TaskStatus.todo;
      _selectedAssignee = null;
    });
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid ?? '';

      if (widget.task != null) {
        // Update existing task
        final updatedTask = widget.task!.copyWith(
          taskNumber:
              _taskNumberController.text.trim().isNotEmpty
                  ? _taskNumberController.text.trim()
                  : widget.task!.taskNumber,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _selectedPriority,
          status: _selectedStatus,
          assignedToId: _selectedAssignee?.id,
          assignedToName: _selectedAssignee?.name,
          updatedAt: DateTime.now(),
        );
        await taskProvider.updateTask(updatedTask);
      } else {
        // Create new task
        final taskNumber =
            _taskNumberController.text.trim().isNotEmpty
                ? _taskNumberController.text.trim()
                : 'TSK-${DateTime.now().millisecondsSinceEpoch}';
        final newTask = Task(
          id: '', // Will be set by Firestore
          taskNumber: taskNumber,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _selectedPriority,
          status: _selectedStatus,
          assignedToId: _selectedAssignee?.id,
          assignedToName: _selectedAssignee?.name,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: userId,
        );
        await taskProvider.addTask(newTask);
      }

      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/dashboard');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.task != null
                  ? 'Görev başarıyla güncellendi!'
                  : 'Görev başarıyla oluşturuldu!',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildMobileLayout() {
    return Consumer<ResponsiveProvider>(
      builder: (context, responsive, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildMobileAppBar(responsive),
          body: _buildMobileContent(responsive),
          floatingActionButton: _buildMobileFAB(responsive),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  PreferredSizeWidget _buildMobileAppBar(ResponsiveProvider responsive) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/dashboard');
          }
        },
      ),
      title: Text(
        widget.task != null ? 'Görev Düzenle' : 'Yeni Görev',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: responsive.getResponsiveFontSize(18),
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        if (!_isLoading)
          IconButton(
            onPressed: _saveTask,
            icon: const Icon(Icons.check, color: AppColors.primary),
            tooltip: widget.task != null ? 'Güncelle' : 'Kaydet',
          ),
        if (_isLoading)
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMobileContent(ResponsiveProvider responsive) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.all(
          responsive.responsiveValue(mobile: 16.0, desktop: 24.0),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMobileBasicInfoSection(responsive),
              SizedBox(
                height: responsive.responsiveValue(mobile: 20.0, desktop: 24.0),
              ),
              _buildMobileDetailsSection(responsive),
              SizedBox(
                height: responsive.responsiveValue(mobile: 20.0, desktop: 24.0),
              ),
              _buildMobileAssignmentSection(responsive),
              SizedBox(
                height: responsive.responsiveValue(mobile: 80.0, desktop: 60.0),
              ), // Space for FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileFAB(ResponsiveProvider responsive) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _saveTask,
        backgroundColor: _isLoading ? AppColors.textHint : AppColors.primary,
        icon:
            _isLoading
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : const Icon(Icons.save, color: Colors.white),
        label: Text(
          widget.task != null ? 'Güncelle' : 'Kaydet',
          style: TextStyle(
            color: Colors.white,
            fontSize: responsive.getResponsiveFontSize(16),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMobileBasicInfoSection(ResponsiveProvider responsive) {
    return _buildMobileSection(
      title: 'Temel Bilgiler',
      icon: Icons.info_outline,
      responsive: responsive,
      child: Column(
        children: [
          _buildMobileTextField(
            controller: _taskNumberController,
            label: 'Görev Numarası',
            hint: 'örn: GMO-4567',
            icon: Icons.tag,
            responsive: responsive,
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                if (!RegExp(r'^[A-Z]+-\d+$').hasMatch(value.trim())) {
                  return 'Format: ABC-123';
                }
              }
              return null;
            },
          ),
          SizedBox(
            height: responsive.responsiveValue(mobile: 16.0, desktop: 20.0),
          ),
          _buildMobileTextField(
            controller: _titleController,
            label: 'Görev Başlığı *',
            hint: 'Açıklayıcı bir başlık girin',
            icon: Icons.title,
            responsive: responsive,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Lütfen bir görev başlığı girin';
              }
              return null;
            },
          ),
          SizedBox(
            height: responsive.responsiveValue(mobile: 16.0, desktop: 20.0),
          ),
          _buildMobileTextField(
            controller: _descriptionController,
            label: 'Açıklama',
            hint: 'Yapılması gerekenleri açıklayın...',
            icon: Icons.description,
            maxLines: 4,
            responsive: responsive,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDetailsSection(ResponsiveProvider responsive) {
    return _buildMobileSection(
      title: 'Görev Detayları',
      icon: Icons.settings,
      responsive: responsive,
      child: Column(
        children: [
          _buildMobilePriorityField(responsive),
          SizedBox(
            height: responsive.responsiveValue(mobile: 16.0, desktop: 20.0),
          ),
          _buildMobileStatusField(responsive),
        ],
      ),
    );
  }

  Widget _buildMobileAssignmentSection(ResponsiveProvider responsive) {
    return _buildMobileSection(
      title: 'Atama',
      icon: Icons.person,
      responsive: responsive,
      child: _buildMobileAssigneeField(responsive),
    );
  }

  Widget _buildMobileSection({
    required String title,
    required IconData icon,
    required Widget child,
    required ResponsiveProvider responsive,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        responsive.responsiveValue(mobile: 16.0, desktop: 20.0),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: responsive.getResponsiveFontSize(18),
                ),
              ),
              SizedBox(
                width: responsive.responsiveValue(mobile: 12.0, desktop: 16.0),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: responsive.getResponsiveFontSize(16),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(
            height: responsive.responsiveValue(mobile: 16.0, desktop: 20.0),
          ),
          child,
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
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: responsive.getResponsiveFontSize(14),
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(
          height: responsive.responsiveValue(mobile: 8.0, desktop: 10.0),
        ),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textHint,
              fontSize: responsive.getResponsiveFontSize(14),
            ),
            prefixIcon: Icon(
              icon,
              color: AppColors.textSecondary,
              size: responsive.getResponsiveFontSize(20),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(responsive.borderRadius),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(responsive.borderRadius),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(responsive.borderRadius),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(responsive.borderRadius),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(responsive.borderRadius),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            contentPadding: EdgeInsets.symmetric(
              horizontal: responsive.responsiveValue(
                mobile: 12.0,
                desktop: 16.0,
              ),
              vertical: responsive.responsiveValue(mobile: 12.0, desktop: 14.0),
            ),
          ),
          style: TextStyle(
            fontSize: responsive.getResponsiveFontSize(14),
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildMobilePriorityField(ResponsiveProvider responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Öncelik',
          style: TextStyle(
            fontSize: responsive.getResponsiveFontSize(14),
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(
          height: responsive.responsiveValue(mobile: 8.0, desktop: 10.0),
        ),
        DropdownButtonFormField<TaskPriority>(
          value: _selectedPriority,
          onChanged: (TaskPriority? priority) {
            if (priority != null) {
              setState(() => _selectedPriority = priority);
            }
          },
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.priority_high,
              color: AppColors.textSecondary,
              size: responsive.getResponsiveFontSize(20),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(responsive.borderRadius),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(responsive.borderRadius),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(responsive.borderRadius),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            contentPadding: EdgeInsets.symmetric(
              horizontal: responsive.responsiveValue(
                mobile: 12.0,
                desktop: 16.0,
              ),
              vertical: responsive.responsiveValue(mobile: 12.0, desktop: 14.0),
            ),
          ),
          style: TextStyle(
            fontSize: responsive.getResponsiveFontSize(14),
            color: AppColors.textPrimary,
          ),
          items:
              TaskPriority.values.map((TaskPriority priority) {
                return DropdownMenuItem<TaskPriority>(
                  value: priority,
                  child: Text(priority.displayName),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildMobileStatusField(ResponsiveProvider responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Durum',
          style: TextStyle(
            fontSize: responsive.getResponsiveFontSize(14),
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(
          height: responsive.responsiveValue(mobile: 8.0, desktop: 10.0),
        ),
        DropdownButtonFormField<TaskStatus>(
          value: _selectedStatus,
          onChanged: (TaskStatus? status) {
            if (status != null) {
              setState(() => _selectedStatus = status);
            }
          },
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.flag,
              color: AppColors.textSecondary,
              size: responsive.getResponsiveFontSize(20),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(responsive.borderRadius),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(responsive.borderRadius),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(responsive.borderRadius),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            contentPadding: EdgeInsets.symmetric(
              horizontal: responsive.responsiveValue(
                mobile: 12.0,
                desktop: 16.0,
              ),
              vertical: responsive.responsiveValue(mobile: 12.0, desktop: 14.0),
            ),
          ),
          style: TextStyle(
            fontSize: responsive.getResponsiveFontSize(14),
            color: AppColors.textPrimary,
          ),
          items:
              TaskStatus.values.map((TaskStatus status) {
                return DropdownMenuItem<TaskStatus>(
                  value: status,
                  child: Text(status.displayName),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildMobileAssigneeField(ResponsiveProvider responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Atanan Kişi',
          style: TextStyle(
            fontSize: responsive.getResponsiveFontSize(14),
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(
          height: responsive.responsiveValue(mobile: 8.0, desktop: 10.0),
        ),
        Consumer<PersonProvider>(
          builder: (context, personProvider, child) {
            return DropdownButtonFormField<Person?>(
              value: _selectedAssignee,
              onChanged: (Person? person) {
                setState(() => _selectedAssignee = person);
              },
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.person,
                  color: AppColors.textSecondary,
                  size: responsive.getResponsiveFontSize(20),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(responsive.borderRadius),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(responsive.borderRadius),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(responsive.borderRadius),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: responsive.responsiveValue(
                    mobile: 12.0,
                    desktop: 16.0,
                  ),
                  vertical: responsive.responsiveValue(
                    mobile: 12.0,
                    desktop: 14.0,
                  ),
                ),
              ),
              style: TextStyle(
                fontSize: responsive.getResponsiveFontSize(14),
                color: AppColors.textPrimary,
              ),
              items: [
                const DropdownMenuItem<Person?>(
                  value: null,
                  child: Text('Atanmamış'),
                ),
                ...personProvider.people.map((Person person) {
                  return DropdownMenuItem<Person?>(
                    value: person,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            person.name.isNotEmpty
                                ? person.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(person.name),
                      ],
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ],
    );
  }
}
