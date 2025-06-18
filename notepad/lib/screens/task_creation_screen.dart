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
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      title: Text(
        widget.task != null ? 'Edit Task' : 'Create New Task',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
      actions: [
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else ...[
          TextButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _saveTask,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(widget.task != null ? 'Update' : 'Create'),
          ),
          const SizedBox(width: 16),
        ],
      ],
    );
  }

  Widget _buildBody() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        margin: const EdgeInsets.all(24),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: _buildTextField(
                                  controller: _taskNumberController,
                                  label: 'Task Number',
                                  hint: 'e.g., GMO-4567',
                                  icon: Icons.tag_rounded,
                                  validator: (value) {
                                    if (value != null &&
                                        value.trim().isNotEmpty) {
                                      // Optional validation for format
                                      if (!RegExp(
                                        r'^[A-Z]+-\d+$',
                                      ).hasMatch(value.trim())) {
                                        return 'Format: ABC-123';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 2,
                                child: _buildTextField(
                                  controller: _titleController,
                                  label: 'Task Title *',
                                  hint: 'Enter a descriptive task title',
                                  icon: Icons.title_rounded,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter a task title';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildTextField(
                            controller: _descriptionController,
                            label: 'Description',
                            hint: 'Describe what needs to be done',
                            icon: Icons.description_rounded,
                            maxLines: 4,
                          ),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(child: _buildPriorityField()),
                              const SizedBox(width: 24),
                              Expanded(child: _buildStatusField()),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildAssigneeField(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                widget.task != null
                    ? Icons.edit_rounded
                    : Icons.add_task_rounded,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.task != null ? 'Edit Task' : 'Create New Task',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.task != null
                        ? 'Update the details of your task'
                        : 'Fill in the details to create a new task',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(height: 1, color: Colors.grey.shade200),
      ],
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
            fontSize: 16,
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
            prefixIcon: Icon(icon, color: Colors.grey.shade600),
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
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Priority',
          style: TextStyle(
            fontSize: 16,
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
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
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

  Widget _buildStatusField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status',
          style: TextStyle(
            fontSize: 16,
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
            prefixIcon: Icon(Icons.flag_rounded, color: Colors.grey.shade600),
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
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
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

  Widget _buildAssigneeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assign To',
          style: TextStyle(
            fontSize: 16,
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
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(16),
              ),
              items: [
                const DropdownMenuItem<Person?>(
                  value: null,
                  child: Text('Unassigned'),
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
                  ? 'Task updated successfully!'
                  : 'Task created successfully!',
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
            content: Text('Error: $e'),
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
