import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../models/person.dart';
import '../providers/task_provider.dart';
import '../providers/person_provider.dart';
import '../utils/theme.dart';
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
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isEditing ? Icons.edit : Icons.add_task,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(isEditing ? 'Task Düzenle' : 'Yeni Task'),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Task Number Field
              TextFormField(
                controller: _taskNumberController,
                enabled:
                    !isEditing, // Task number cannot be changed when editing
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
                  labelText: 'Başlık *',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Başlık gereklidir';
                  }
                  if (value.length < 3) {
                    return 'Başlık en az 3 karakter olmalıdır';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                validator: (value) {
                  if (value != null && value.length > 500) {
                    return 'Açıklama 500 karakterden uzun olamaz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Person Assignment Field
              Consumer<PersonProvider>(
                builder: (context, personProvider, child) {
                  return Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<Person>(
                          value: _selectedPerson,
                          decoration: const InputDecoration(
                            labelText: 'Atanan Kişi',
                            prefixIcon: Icon(Icons.person),
                            helperText:
                                'Opsiyonel - task bir kişiye atanabilir',
                          ),
                          items: [
                            const DropdownMenuItem<Person>(
                              value: null,
                              child: Text('Atanmamış'),
                            ),
                            ...personProvider.people.map((person) {
                              return DropdownMenuItem<Person>(
                                value: person,
                                child: Text(person.name),
                              );
                            }),
                          ],
                          onChanged: (Person? value) {
                            setState(() {
                              _selectedPerson = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _showAddPersonDialog(),
                        icon: const Icon(Icons.person_add),
                        tooltip: 'Yeni Kişi Ekle',
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // Status info for new tasks
              if (!isEditing)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.todoColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.todoColor.withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info, color: AppColors.todoColor, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Yeni task "Todo" durumunda oluşturulacak',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
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
          onPressed: _isLoading ? null : _handleSubmit,
          child:
              _isLoading
                  ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Text(isEditing ? 'Güncelle' : 'Oluştur'),
        ),
      ],
    );
  }

  Future<void> _showAddPersonDialog() async {
    await showDialog(
      context: context,
      builder: (context) => const AddPersonDialog(),
    );
  }

  Future<void> _handleSubmit() async {
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

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task başarıyla güncellendi'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        // Create new task
        await taskProvider.createTask(
          taskNumber: _taskNumberController.text.trim(),
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          assignedToId: _selectedPerson?.id,
          assignedToName: _selectedPerson?.name,
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task başarıyla oluşturuldu'),
              backgroundColor: AppColors.success,
            ),
          );
        }
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
