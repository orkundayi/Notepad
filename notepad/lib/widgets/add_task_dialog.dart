import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../models/person.dart';
import '../providers/task_provider.dart';
import '../providers/person_provider.dart';
import '../utils/theme.dart';
import '../utils/platform_utils.dart';
import 'add_person_dialog.dart';

class AddTaskDialog extends StatefulWidget {
  final Task? task;

  const AddTaskDialog({super.key, this.task});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _taskNumberController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  Person? _selectedPerson;

  bool get isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _taskNumberController.text = widget.task!.taskNumber;
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;

      // Set selected person if task is assigned
      if (widget.task!.assignedToId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final personProvider = Provider.of<PersonProvider>(
            context,
            listen: false,
          );
          _selectedPerson = personProvider.getPersonById(
            widget.task!.assignedToId!,
          );
          if (mounted) setState(() {});
        });
      }
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
    return PlatformUtils.isWeb ? _buildWebDialog() : _buildMobileDialog();
  }

  Widget _buildWebDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: PlatformUtils.getDialogMaxWidth(context),
        constraints: const BoxConstraints(maxHeight: 700),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isEditing ? Icons.edit : Icons.add_task,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Task Düzenle' : 'Yeni Task Oluştur',
                  style: PlatformUtils.getTitleStyle(
                    context,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  isEditing
                      ? 'Task bilgilerini güncelleyin'
                      : 'Yeni bir görev oluşturun ve kişi atayın',
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
        Icon(isEditing ? Icons.edit : Icons.add_task, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(isEditing ? 'Task Düzenle' : 'Yeni Task'),
      ],
    );
  }

  Widget _buildWebForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Task Number Field
          _buildWebFormField(
            label: 'Task Numarası',
            isRequired: true,
            child: TextFormField(
              controller: _taskNumberController,
              enabled: !isEditing,
              decoration: InputDecoration(
                hintText: 'Örnek: TASK-001',
                prefixIcon: const Icon(Icons.tag),
                border: OutlineInputBorder(
                  borderRadius: PlatformUtils.getButtonRadius(),
                ),
                helperText:
                    isEditing
                        ? 'Task numarası değiştirilemez'
                        : 'Benzersiz bir task numarası girin',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Task numarası gereklidir';
                }
                if (value.length < 3) {
                  return 'Task numarası en az 3 karakter olmalıdır';
                }
                return null;
              },
            ),
          ),

          SizedBox(height: PlatformUtils.getSpacing(3)),

          // Title Field
          _buildWebFormField(
            label: 'Task Başlığı',
            isRequired: true,
            child: TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Task başlığını girin',
                prefixIcon: const Icon(Icons.title),
                border: OutlineInputBorder(
                  borderRadius: PlatformUtils.getButtonRadius(),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Task başlığı gereklidir';
                }
                if (value.length < 3) {
                  return 'Task başlığı en az 3 karakter olmalıdır';
                }
                return null;
              },
            ),
          ),

          SizedBox(height: PlatformUtils.getSpacing(3)),

          // Description Field
          _buildWebFormField(
            label: 'Açıklama',
            child: TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Task açıklamasını girin (isteğe bağlı)',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: PlatformUtils.getButtonRadius(),
                ),
              ),
            ),
          ),

          SizedBox(height: PlatformUtils.getSpacing(3)),

          // Person Assignment
          _buildWebFormField(
            label: 'Atanan Kişi',
            child: _buildPersonSelector(),
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
            // Task Number Field
            TextFormField(
              controller: _taskNumberController,
              enabled: !isEditing,
              decoration: InputDecoration(
                labelText: 'Task Numarası *',
                prefixIcon: const Icon(Icons.tag),
                helperText:
                    isEditing
                        ? 'Task numarası değiştirilemez'
                        : 'Örnek: TASK-001',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Task numarası gereklidir';
                }
                if (value.length < 3) {
                  return 'Task numarası en az 3 karakter olmalıdır';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Title Field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Task Başlığı *',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Task başlığı gereklidir';
                }
                if (value.length < 3) {
                  return 'Task başlığı en az 3 karakter olmalıdır';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Description Field
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Açıklama',
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 16),

            // Person Assignment
            _buildPersonSelector(),
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

  Widget _buildPersonSelector() {
    return Consumer<PersonProvider>(
      builder: (context, personProvider, child) {
        final people = personProvider.people;

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: PlatformUtils.getButtonRadius(),
          ),
          child: Column(
            children: [
              // Selected person or select button
              if (_selectedPerson != null)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      _selectedPerson!.name[0].toUpperCase(),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(_selectedPerson!.name),
                  subtitle:
                      _selectedPerson!.role != null
                          ? Text(_selectedPerson!.role!)
                          : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showPersonPicker(people),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () {
                          setState(() {
                            _selectedPerson = null;
                          });
                        },
                      ),
                    ],
                  ),
                )
              else
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.person_add, color: Colors.grey),
                  ),
                  title: const Text('Kişi Seç'),
                  subtitle: const Text(
                    'Bu task\'ı birine atayın (isteğe bağlı)',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showPersonPicker(people),
                ),

              // Quick add person button
              if (people.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.only(
                      bottomLeft: PlatformUtils.getButtonRadius().bottomLeft,
                      bottomRight: PlatformUtils.getButtonRadius().bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.grey[600],
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Henüz kişi eklenmemiş',
                          style: PlatformUtils.getCaptionStyle(
                            context,
                          ).copyWith(color: Colors.grey[600]),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showAddPersonDialog(),
                        icon: const Icon(Icons.person_add, size: 16),
                        label: const Text('Kişi Ekle'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
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
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('İptal'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isLoading ? null : _saveTask,
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
                    : Text(isEditing ? 'Güncelle' : 'Oluştur'),
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
      ElevatedButton(
        onPressed: _isLoading ? null : _saveTask,
        child:
            _isLoading
                ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : Text(isEditing ? 'Güncelle' : 'Oluştur'),
      ),
    ];
  }

  void _showPersonPicker(List<Person> people) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Kişi Seç'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child:
                  people.isEmpty
                      ? const Center(child: Text('Henüz kişi eklenmemiş'))
                      : ListView.builder(
                        itemCount: people.length,
                        itemBuilder: (context, index) {
                          final person = people[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(
                                0.1,
                              ),
                              child: Text(
                                person.name[0].toUpperCase(),
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(person.name),
                            subtitle:
                                person.role != null ? Text(person.role!) : null,
                            onTap: () {
                              setState(() {
                                _selectedPerson = person;
                              });
                              Navigator.of(context).pop();
                            },
                          );
                        },
                      ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () => _showAddPersonDialog(),
                child: const Text('Yeni Kişi Ekle'),
              ),
            ],
          ),
    );
  }

  void _showAddPersonDialog() {
    showDialog(context: context, builder: (context) => const AddPersonDialog());
  }

  void _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      if (isEditing) {
        // Update existing task
        await taskProvider.updateTask(
          widget.task!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          assignedToId: _selectedPerson?.id,
          assignedToName: _selectedPerson?.name,
        );
      } else {
        // Create new task
        await taskProvider.createTask(
          taskNumber: _taskNumberController.text.trim(),
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          assignedToId: _selectedPerson?.id,
          assignedToName: _selectedPerson?.name,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Task başarıyla güncellendi'
                  : 'Task başarıyla oluşturuldu',
            ),
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
