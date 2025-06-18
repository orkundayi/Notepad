import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/task.dart';
import '../models/person.dart';
import '../providers/task_provider.dart';
import '../providers/person_provider.dart';
import '../providers/auth_provider.dart';

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
    return _buildWebLayout();
  }

  Widget _buildWebLayout() {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 280,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Colors.grey, width: 0.5)),
            ),
            child: _buildSidebar(),
          ),
          // Main content
          Expanded(
            child: Container(
              color: Colors.grey.shade50,
              child: Column(
                children: [
                  _buildWebHeader(),
                  Expanded(child: _buildWebContent()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Column(
      children: [
        // Sidebar Header
        Container(
          padding: const EdgeInsets.all(24),
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
                icon: const Icon(Icons.arrow_back, color: Colors.blue),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue.withOpacity(0.1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.task != null ? 'Görev Düzenle' : 'Yeni Görev',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Sidebar Content
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Görev Yönetimi',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSidebarAction(
                  icon: Icons.save,
                  title:
                      widget.task != null ? 'Görevi Güncelle' : 'Görevi Kaydet',
                  subtitle: 'Değişiklikleri kaydet',
                  onTap: _saveTask,
                  isLoading: _isLoading,
                  isPrimary: true,
                ),
                const SizedBox(height: 12),
                _buildSidebarAction(
                  icon: Icons.preview,
                  title: 'Önizleme',
                  subtitle: 'Görev detaylarını gözden geçir',
                  onTap: () {
                    // Önizleme functionality
                  },
                ),
                const SizedBox(height: 12),
                _buildSidebarAction(
                  icon: Icons.refresh,
                  title: 'Sıfırla',
                  subtitle: 'Formu temizle',
                  onTap: _resetForm,
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
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isPrimary ? Colors.blue.shade200 : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isPrimary ? Colors.blue.shade50 : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    isPrimary
                        ? Colors.blue.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Icon(
                        icon,
                        color: isPrimary ? Colors.blue : Colors.grey.shade600,
                        size: 20,
                      ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isPrimary ? Colors.blue.shade700 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.task != null ? 'Görev Düzenle' : 'Yeni Görev Oluştur',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.task != null
                      ? 'Görev detaylarını güncelleyin'
                      : 'Yeni bir görev oluşturmak için formu doldurun',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBasicInfoSection(),
                const SizedBox(height: 32),
                _buildDetailsSection(),
                const SizedBox(height: 32),
                _buildAssignmentSection(),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSection(
      title: 'Temel Bilgiler',
      icon: Icons.info_outline_rounded,
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
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: _buildTextField(
                  controller: _titleController,
                  label: 'Görev Başlığı *',
                  hint: 'Açıklayıcı bir başlık girin',
                  icon: Icons.title_rounded,
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
          const SizedBox(height: 20),
          _buildTextField(
            controller: _descriptionController,
            label: 'Açıklama',
            hint: 'Yapılması gerekenleri açıklayın...',
            icon: Icons.description_rounded,
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return _buildSection(
      title: 'Görev Detayları',
      icon: Icons.settings_rounded,
      child: Row(
        children: [
          Expanded(child: _buildPriorityField()),
          const SizedBox(width: 20),
          Expanded(child: _buildStatusField()),
        ],
      ),
    );
  }

  Widget _buildAssignmentSection() {
    return _buildSection(
      title: 'Atama',
      icon: Icons.person_rounded,
      child: _buildAssigneeField(),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              Icon(icon, color: Colors.blue, size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildPriorityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Öncelik',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
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
              color: Colors.grey.shade600,
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          style: const TextStyle(fontSize: 14, color: Colors.black87),
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

  Widget _buildStatusField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Durum',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
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
              color: Colors.grey.shade600,
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          style: const TextStyle(fontSize: 14, color: Colors.black87),
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

  Widget _buildAssigneeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Atanan Kişi',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
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
                  color: Colors.grey.shade600,
                  size: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              style: const TextStyle(fontSize: 14, color: Colors.black87),
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
}
