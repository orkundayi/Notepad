import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../utils/theme.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final Function(TaskStatus) onStatusChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onStatusChanged,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Task number chip
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
                  // Status dropdown
                  PopupMenuButton<TaskStatus>(
                    onSelected: onStatusChanged,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.getStatusColor(task.status.value),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(task.status),
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            task.status.displayName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_drop_down,
                            size: 16,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    itemBuilder:
                        (context) =>
                            TaskStatus.values.map((status) {
                              return PopupMenuItem<TaskStatus>(
                                value: status,
                                child: Row(
                                  children: [
                                    Icon(
                                      _getStatusIcon(status),
                                      size: 16,
                                      color: AppTheme.getStatusColor(
                                        status.value,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(status.displayName),
                                  ],
                                ),
                              );
                            }).toList(),
                  ),
                  // More options
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
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Assignment info
              if (task.assignedToId != null && task.assignedToName != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
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
                        'Atanan: ${task.assignedToName}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.textHint.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.textHint.withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_off,
                        size: 14,
                        color: AppColors.textHint,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Atanmamış',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Footer
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    'Oluşturuldu: ${DateFormat('dd/MM/yyyy HH:mm').format(task.createdAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                  const Spacer(),
                  if (task.createdAt != task.updatedAt) ...[
                    Icon(Icons.update, size: 14, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(
                      'Güncellendi: ${DateFormat('dd/MM/yyyy HH:mm').format(task.updatedAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
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
