import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../utils/platform_utils.dart';
import '../utils/theme.dart';
import '../widgets/drag_drop_task.dart';

class WebKanbanLayout extends StatefulWidget {
  final List<Task> filteredTasks;
  final bool isFiltered;
  final Function() onRefresh;
  final Function(Task) onEditTask;
  final Function(Task) onDeleteTask;

  const WebKanbanLayout({
    super.key,
    required this.filteredTasks,
    required this.isFiltered,
    required this.onRefresh,
    required this.onEditTask,
    required this.onDeleteTask,
  });

  @override
  State<WebKanbanLayout> createState() => _WebKanbanLayoutState();
}

class _WebKanbanLayoutState extends State<WebKanbanLayout> {
  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final allTasks =
            widget.isFiltered ? widget.filteredTasks : taskProvider.tasks;

        return SizedBox(
          width: PlatformUtils.getContentWidth(context),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                TaskStatus.values.map((status) {
                  final statusTasks =
                      allTasks.where((task) => task.status == status).toList();

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Container(
                        height: MediaQuery.of(context).size.height - 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: TaskDropZone(
                          status: status,
                          tasks: statusTasks,
                          onTaskDropped: (task, newStatus) async {
                            await taskProvider.updateTaskStatus(
                              task.id,
                              newStatus,
                            );
                            _showStatusChangeSnackbar(task, newStatus);
                          },
                          onTaskEdit: widget.onEditTask,
                          onTaskDelete: widget.onDeleteTask,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        );
      },
    );
  }

  void _showStatusChangeSnackbar(Task task, TaskStatus newStatus) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${task.title} → ${newStatus.displayName}'),
        backgroundColor: AppTheme.getStatusColor(newStatus.value),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class WebSidePanel extends StatelessWidget {
  final List<Task> tasks;
  final Function() onAddTask;
  final Function() onManagePeople;
  final Function() onShowFilters;

  const WebSidePanel({
    super.key,
    required this.tasks,
    required this.onAddTask,
    required this.onManagePeople,
    required this.onShowFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Actions
          Card(
            elevation: PlatformUtils.getCardElevation(),
            shape: RoundedRectangleBorder(
              borderRadius: PlatformUtils.getCardRadius(),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hızlı İşlemler',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ActionButton(
                    icon: Icons.add_task,
                    label: 'Yeni Task',
                    color: AppColors.primary,
                    onTap: onAddTask,
                  ),
                  const SizedBox(height: 12),
                  _ActionButton(
                    icon: Icons.people,
                    label: 'Kişileri Yönet',
                    color: AppColors.secondary,
                    onTap: onManagePeople,
                  ),
                  const SizedBox(height: 12),
                  _ActionButton(
                    icon: Icons.filter_list,
                    label: 'Filtreler',
                    color: AppColors.warning,
                    onTap: onShowFilters,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
