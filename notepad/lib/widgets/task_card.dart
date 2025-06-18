import 'package:flutter/material.dart';
import '../models/task.dart';
import '../utils/theme.dart';
import '../utils/platform_utils.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(TaskStatus) onStatusChanged;

  const TaskCard({
    super.key,
    required this.task,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _buildWebCard(context);
  }

  Widget _buildWebCard(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: PlatformUtils.getSpacing(1.5)),
      elevation: PlatformUtils.getCardElevation(),
      shape: RoundedRectangleBorder(
        borderRadius: PlatformUtils.getCardRadius(),
        side: BorderSide(
          color: AppTheme.getStatusColor(task.status.value).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: PlatformUtils.getCardRadius(),
        child: Padding(
          padding: PlatformUtils.getCardPadding(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWebHeader(context),
              SizedBox(height: PlatformUtils.getSpacing(1.5)),
              _buildContent(context),
              if (task.description.isNotEmpty) ...[
                SizedBox(height: PlatformUtils.getSpacing(1)),
                _buildDescription(context),
              ],
              SizedBox(height: PlatformUtils.getSpacing(2)),
              _buildWebFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebHeader(BuildContext context) {
    return Row(
      children: [
        // Task number chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.getStatusColor(task.status.value).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.getStatusColor(
                task.status.value,
              ).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            task.taskNumber,
            style: TextStyle(
              color: AppTheme.getStatusColor(task.status.value),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        const Spacer(),
        // Status dropdown
        _buildWebStatusDropdown(),
        const SizedBox(width: 8),
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
                      Icon(Icons.delete, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Sil', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.more_vert, size: 16, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Text(
      task.title,
      style: PlatformUtils.getSubtitleStyle(
        context,
      ).copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      task.description,
      style: PlatformUtils.getCaptionStyle(context),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildWebStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.getStatusColor(task.status.value).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.getStatusColor(task.status.value).withOpacity(0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TaskStatus>(
          value: task.status,
          isDense: true,
          style: TextStyle(
            color: AppTheme.getStatusColor(task.status.value),
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          onChanged: (TaskStatus? newStatus) {
            if (newStatus != null) {
              onStatusChanged(newStatus);
            }
          },
          items:
              TaskStatus.values.map((TaskStatus status) {
                return DropdownMenuItem<TaskStatus>(
                  value: status,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppTheme.getStatusColor(status.value),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(status.displayName),
                    ],
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildWebFooter(BuildContext context) {
    return Row(
      children: [
        // Priority indicator
        Row(
          children: [
            Icon(
              task.priority == TaskPriority.high
                  ? Icons.keyboard_arrow_up
                  : task.priority == TaskPriority.medium
                  ? Icons.remove
                  : Icons.keyboard_arrow_down,
              size: 16,
              color:
                  task.priority == TaskPriority.high
                      ? Colors.red
                      : task.priority == TaskPriority.medium
                      ? Colors.orange
                      : Colors.green,
            ),
            const SizedBox(width: 4),
            Text(
              task.priority.displayName,
              style: TextStyle(
                fontSize: 11,
                color:
                    task.priority == TaskPriority.high
                        ? Colors.red
                        : task.priority == TaskPriority.medium
                        ? Colors.orange
                        : Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const Spacer(),
        // Created date
        Text(
          _formatDate(task.createdAt),
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) {
      return 'Bugün';
    } else if (difference == 1) {
      return 'Yarın';
    } else if (difference == -1) {
      return 'Dün';
    } else if (difference > 1 && difference <= 7) {
      return '$difference gün kaldı';
    } else if (difference < -1 && difference >= -7) {
      return '${difference.abs()} gün geçti';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
