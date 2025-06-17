import 'package:flutter/material.dart';
import '../models/task.dart';
import '../utils/theme.dart';

class DraggableTaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(TaskStatus) onStatusChanged;

  const DraggableTaskCard({
    super.key,
    required this.task,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<Task>(
      data: task,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 300,
          constraints: const BoxConstraints(maxHeight: 200),
          child: TaskCardContent(
            task: task,
            onEdit: onEdit,
            onDelete: onDelete,
            isDragging: true,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: TaskCardContent(task: task, onEdit: onEdit, onDelete: onDelete),
      ),
      child: TaskCardContent(task: task, onEdit: onEdit, onDelete: onDelete),
    );
  }
}

class TaskDropZone extends StatefulWidget {
  final TaskStatus status;
  final List<Task> tasks;
  final Function(Task, TaskStatus) onTaskDropped;
  final Function(Task) onTaskEdit;
  final Function(Task) onTaskDelete;

  const TaskDropZone({
    super.key,
    required this.status,
    required this.tasks,
    required this.onTaskDropped,
    required this.onTaskEdit,
    required this.onTaskDelete,
  });

  @override
  State<TaskDropZone> createState() => _TaskDropZoneState();
}

class _TaskDropZoneState extends State<TaskDropZone> {
  bool _isDragOver = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<Task>(
      onAccept: (task) {
        if (task.status != widget.status) {
          widget.onTaskDropped(task, widget.status);
        }
        setState(() => _isDragOver = false);
      },
      onWillAccept: (task) {
        setState(() => _isDragOver = true);
        return task != null && task.status != widget.status;
      },
      onLeave: (task) {
        setState(() => _isDragOver = false);
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color:
                _isDragOver
                    ? AppTheme.getStatusColor(
                      widget.status.value,
                    ).withOpacity(0.1)
                    : Colors.transparent,
            border:
                _isDragOver
                    ? Border.all(
                      color: AppTheme.getStatusColor(widget.status.value),
                      width: 2,
                    )
                    : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.getStatusColor(
                    widget.status.value,
                  ).withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getStatusIcon(widget.status),
                      color: AppTheme.getStatusColor(widget.status.value),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.status.displayName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getStatusColor(widget.status.value),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.getStatusColor(widget.status.value),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.tasks.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Tasks
              Expanded(
                child:
                    widget.tasks.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getStatusIcon(widget.status),
                                size: 48,
                                color: AppColors.textHint,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isDragOver
                                    ? 'Task\'ı buraya bırakın'
                                    : 'Henüz ${widget.status.displayName.toLowerCase()} task yok',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: widget.tasks.length,
                          itemBuilder: (context, index) {
                            final task = widget.tasks[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: DraggableTaskCard(
                                task: task,
                                onEdit: () => widget.onTaskEdit(task),
                                onDelete: () => widget.onTaskDelete(task),
                                onStatusChanged:
                                    (status) =>
                                        widget.onTaskDropped(task, status),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Icons.radio_button_unchecked;
      case TaskStatus.inProgress:
        return Icons.play_circle_outline;
      case TaskStatus.done:
        return Icons.check_circle;
      case TaskStatus.blocked:
        return Icons.block;
    }
  }
}

class TaskCardContent extends StatelessWidget {
  final Task task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isDragging;

  const TaskCardContent({
    super.key,
    required this.task,
    required this.onEdit,
    required this.onDelete,
    this.isDragging = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isDragging ? 8 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  // Task number
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.getStatusColor(
                        task.status.value,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppTheme.getStatusColor(
                          task.status.value,
                        ).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      task.taskNumber,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getStatusColor(task.status.value),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (!isDragging)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            onEdit();
                            break;
                          case 'delete':
                            onDelete();
                            break;
                        }
                      },
                      itemBuilder:
                          (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 16),
                                  SizedBox(width: 8),
                                  Text('Düzenle'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    size: 16,
                                    color: AppColors.error,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Sil',
                                    style: TextStyle(color: AppColors.error),
                                  ),
                                ],
                              ),
                            ),
                          ],
                      child: const Icon(
                        Icons.more_vert,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                task.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Description
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Assignment
              if (task.assignedToId != null && task.assignedToName != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.assignedToName!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
