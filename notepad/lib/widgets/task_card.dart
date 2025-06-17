import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../utils/theme.dart';
import '../utils/platform_utils.dart';

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
    return PlatformUtils.isWeb
        ? _buildWebCard(context)
        : _buildMobileCard(context);
  }

  Widget _buildWebCard(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: PlatformUtils.getSpacing(1.5)),
      elevation: PlatformUtils.getCardElevation(),
      shape: RoundedRectangleBorder(
        borderRadius: PlatformUtils.getCardRadius(),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: PlatformUtils.getCardRadius(),
        child: Container(
          padding: PlatformUtils.getCardPadding(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with hover effects
              Row(
                children: [
                  // Task number chip - larger for web
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.getStatusColor(
                        task.status.value,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.getStatusColor(
                          task.status.value,
                        ).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      task.taskNumber,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getStatusColor(task.status.value),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Actions - more spacious for web
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildWebStatusDropdown(),
                      SizedBox(width: PlatformUtils.getSpacing(1)),
                      _buildWebActionButton(
                        icon: Icons.edit_outlined,
                        onPressed: onEdit,
                        tooltip: 'Düzenle',
                      ),
                      SizedBox(width: PlatformUtils.getSpacing(0.5)),
                      _buildWebActionButton(
                        icon: Icons.delete_outline,
                        onPressed: onDelete,
                        tooltip: 'Sil',
                        isDestructive: true,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: PlatformUtils.getSpacing(2)),

              // Title - more prominent for web
              Text(
                task.title,
                style: PlatformUtils.getSubtitleStyle(
                  context,
                ).copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              if (task.description.isNotEmpty) ...[
                SizedBox(height: PlatformUtils.getSpacing(1)),
                Text(
                  task.description,
                  style: PlatformUtils.getBodyStyle(
                    context,
                  ).copyWith(color: Colors.grey[600]),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              SizedBox(height: PlatformUtils.getSpacing(2)),

              // Footer info
              _buildWebFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCard(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: PlatformUtils.getSpacing(1.5)),
      elevation: PlatformUtils.getCardElevation(),
      shape: RoundedRectangleBorder(
        borderRadius: PlatformUtils.getCardRadius(),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: PlatformUtils.getCardRadius(),
        child: Padding(
          padding: PlatformUtils.getCardPadding(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header - compact for mobile
              Row(
                children: [
                  // Task number chip - smaller for mobile
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
                  // Status dropdown - mobile friendly
                  _buildMobileStatusDropdown(),
                ],
              ),
              SizedBox(height: PlatformUtils.getSpacing(1.5)),

              // Title
              Text(
                task.title,
                style: PlatformUtils.getSubtitleStyle(context),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              if (task.description.isNotEmpty) ...[
                SizedBox(height: PlatformUtils.getSpacing(1)),
                Text(
                  task.description,
                  style: PlatformUtils.getBodyStyle(
                    context,
                  ).copyWith(color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              SizedBox(height: PlatformUtils.getSpacing(1.5)),

              // Footer info
              _buildMobileFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebStatusDropdown() {
    return PopupMenuButton<TaskStatus>(
      onSelected: onStatusChanged,
      tooltip: 'Durum değiştir',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.getStatusColor(task.status.value),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: AppTheme.getStatusColor(
                task.status.value,
              ).withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getStatusIcon(task.status), size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              task.status.displayName,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
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
                        color: AppTheme.getStatusColor(status.value),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        status.displayName,
                        style: TextStyle(
                          color:
                              status == task.status
                                  ? AppTheme.getStatusColor(status.value)
                                  : null,
                          fontWeight:
                              status == task.status ? FontWeight.w600 : null,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
    );
  }

  Widget _buildMobileStatusDropdown() {
    return PopupMenuButton<TaskStatus>(
      onSelected: onStatusChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.getStatusColor(task.status.value),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getStatusIcon(task.status), size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              task.status.displayName,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Icon(Icons.arrow_drop_down, size: 16, color: Colors.white),
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
                        size: 14,
                        color: AppTheme.getStatusColor(status.value),
                      ),
                      const SizedBox(width: 8),
                      Text(status.displayName),
                    ],
                  ),
                );
              }).toList(),
    );
  }

  Widget _buildWebActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    bool isDestructive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 18,
              color: isDestructive ? Colors.red[600] : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebFooter(BuildContext context) {
    return Row(
      children: [
        if (task.assignedToName != null) ...[
          Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            task.assignedToName!,
            style: PlatformUtils.getCaptionStyle(
              context,
            ).copyWith(color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 16),
        ],
        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          DateFormat('dd MMM yyyy, HH:mm').format(task.createdAt),
          style: PlatformUtils.getCaptionStyle(
            context,
          ).copyWith(color: Colors.grey[600]),
        ),
        if (task.updatedAt != task.createdAt) ...[
          const SizedBox(width: 16),
          Icon(Icons.edit_outlined, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 4),
          Text(
            DateFormat('dd MMM HH:mm').format(task.updatedAt),
            style: PlatformUtils.getCaptionStyle(
              context,
            ).copyWith(color: Colors.grey[500]),
          ),
        ],
      ],
    );
  }

  Widget _buildMobileFooter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (task.assignedToName != null) ...[
          Row(
            children: [
              Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                task.assignedToName!,
                style: PlatformUtils.getCaptionStyle(context).copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        Row(
          children: [
            Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              DateFormat('dd/MM/yyyy HH:mm').format(task.createdAt),
              style: PlatformUtils.getCaptionStyle(
                context,
              ).copyWith(color: Colors.grey[600]),
            ),
            if (task.updatedAt != task.createdAt) ...[
              const SizedBox(width: 8),
              Icon(Icons.edit_outlined, size: 12, color: Colors.grey[500]),
              const SizedBox(width: 2),
              Text(
                DateFormat('dd/MM HH:mm').format(task.updatedAt),
                style: PlatformUtils.getCaptionStyle(
                  context,
                ).copyWith(color: Colors.grey[500], fontSize: 11),
              ),
            ],
          ],
        ),
      ],
    );
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Icons.radio_button_unchecked;
      case TaskStatus.inProgress:
        return Icons.pending;
      case TaskStatus.done:
        return Icons.check_circle;
      case TaskStatus.blocked:
        return Icons.block;
    }
  }
}
