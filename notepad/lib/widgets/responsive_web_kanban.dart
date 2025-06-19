import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/responsive_provider.dart';
import '../utils/theme.dart';
import '../widgets/responsive_task_card.dart';

class ResponsiveWebKanbanLayout extends StatefulWidget {
  final List<Task> filteredTasks;
  final bool isFiltered;
  final Function() onRefresh;
  final Function(Task) onEditTask;
  final Function(Task) onDeleteTask;

  const ResponsiveWebKanbanLayout({
    super.key,
    required this.filteredTasks,
    required this.isFiltered,
    required this.onRefresh,
    required this.onEditTask,
    required this.onDeleteTask,
  });

  @override
  State<ResponsiveWebKanbanLayout> createState() =>
      _ResponsiveWebKanbanLayoutState();
}

class _ResponsiveWebKanbanLayoutState extends State<ResponsiveWebKanbanLayout> {
  late ScrollController _horizontalScrollController;

  @override
  void initState() {
    super.initState();
    _horizontalScrollController = ScrollController();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TaskProvider, ResponsiveProvider>(
      builder: (context, taskProvider, responsive, child) {
        final allTasks =
            widget.isFiltered ? widget.filteredTasks : taskProvider.tasks;

        // Mobile layout için kontrol
        if (responsive.isMobile) {
          return _buildMobileLayout(allTasks, taskProvider, responsive);
        }

        // Desktop layout for web and tablets
        return _buildDesktopLayout(allTasks, taskProvider, responsive);
      },
    );
  }

  Widget _buildDesktopLayout(
    List<Task> allTasks,
    TaskProvider taskProvider,
    ResponsiveProvider responsive,
  ) {
    return _buildMultiColumnLayout(allTasks, taskProvider, 4, responsive);
  }

  Widget _buildMultiColumnLayout(
    List<Task> allTasks,
    TaskProvider taskProvider,
    int columns,
    ResponsiveProvider responsive,
  ) {
    final allStatuses = TaskStatus.values;
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = responsive.responsivePadding(
      mobile: const EdgeInsets.all(16),
      tablet: const EdgeInsets.all(24),
      desktop: const EdgeInsets.all(32),
    );
    final availableWidth = screenWidth - padding.horizontal;

    // Calculate minimum column width and spacing
    final minColumnWidth = responsive.responsiveValue(
      mobile: 280.0,
      tablet: 300.0,
      desktop: 320.0,
    );
    final columnSpacing = responsive.responsiveValue(
      mobile: 12.0,
      tablet: 16.0,
      desktop: 20.0,
    );
    final totalSpacing = columnSpacing * (allStatuses.length - 1);
    final requiredWidth = (minColumnWidth * allStatuses.length) + totalSpacing;

    // Determine if we need horizontal scrolling
    final needsHorizontalScroll = requiredWidth > availableWidth;

    // Calculate actual column width
    final columnWidth =
        needsHorizontalScroll
            ? minColumnWidth
            : (availableWidth - totalSpacing) / allStatuses.length;

    return Padding(
      padding: padding,
      child:
          needsHorizontalScroll
              ? ScrollConfiguration(
                behavior: _DragScrollBehavior(),
                child: SingleChildScrollView(
                  controller: _horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:
                        allStatuses.asMap().entries.map((entry) {
                          final index = entry.key;
                          final status = entry.value;
                          final statusTasks =
                              allTasks
                                  .where((task) => task.status == status)
                                  .toList();

                          return Container(
                            width: columnWidth,
                            margin: EdgeInsets.only(
                              right:
                                  index < allStatuses.length - 1
                                      ? columnSpacing
                                      : 0,
                            ),
                            child: _buildKanbanColumn(
                              status,
                              statusTasks,
                              taskProvider,
                            ),
                          );
                        }).toList(),
                  ),
                ),
              )
              : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    allStatuses.map((status) {
                      final statusTasks =
                          allTasks
                              .where((task) => task.status == status)
                              .toList();

                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          child: _buildKanbanColumn(
                            status,
                            statusTasks,
                            taskProvider,
                          ),
                        ),
                      );
                    }).toList(),
              ),
    );
  }

  Widget _buildKanbanColumn(
    TaskStatus status,
    List<Task> tasks,
    TaskProvider taskProvider,
  ) {
    return Container(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height - 200,
      ),
      decoration: BoxDecoration(
        color: AppTheme.getStatusBackgroundColor(status.value),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.getStatusColor(status.value).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildColumnHeader(status, tasks.length),
          Expanded(
            child: ResponsiveTaskDropZone(
              status: status,
              tasks: tasks,
              onTaskDropped: (task, newStatus) async {
                await taskProvider.updateTaskStatus(task.id, newStatus);
                _showStatusChangeSnackbar(task, newStatus);
              },
              onTaskEdit: widget.onEditTask,
              onTaskDelete: widget.onDeleteTask,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeader(TaskStatus status, int taskCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppTheme.getStatusColor(status.value),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              status.displayName,
              style: AppTheme.getResponsiveTextStyle(
                context,
                baseFontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.getStatusColor(status.value).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              taskCount.toString(),
              style: AppTheme.getResponsiveTextStyle(
                context,
                baseFontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.getStatusColor(status.value),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusChangeSnackbar(Task task, TaskStatus newStatus) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${task.title} → ${newStatus.displayName}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.getStatusColor(newStatus.value),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.1,
          left: 16,
          right: 16,
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    List<Task> allTasks,
    TaskProvider taskProvider,
    ResponsiveProvider responsive,
  ) {
    final allStatuses = TaskStatus.values;

    return DefaultTabController(
      length: allStatuses.length,
      child: Column(
        children: [
          // Tab bar for mobile
          Container(
            color: Colors.white,
            child: TabBar(
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs:
                  allStatuses.map((status) {
                    final count =
                        allTasks.where((task) => task.status == status).length;
                    return Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(status.displayName),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              count.toString(),
                              style: TextStyle(
                                fontSize: responsive.getResponsiveFontSize(12),
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
          // Tab view content
          Expanded(
            child: TabBarView(
              children:
                  allStatuses.map((status) {
                    final statusTasks =
                        allTasks
                            .where((task) => task.status == status)
                            .toList();
                    return _buildMobileColumn(
                      status,
                      statusTasks,
                      taskProvider,
                      responsive,
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileColumn(
    TaskStatus status,
    List<Task> tasks,
    TaskProvider taskProvider,
    ResponsiveProvider responsive,
  ) {
    return Container(
      padding: responsive.responsivePadding(
        mobile: const EdgeInsets.all(16),
        desktop: const EdgeInsets.all(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: status.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(responsive.borderRadius),
              border: Border.all(color: status.color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  status.icon,
                  color: status.color,
                  size: responsive.getResponsiveFontSize(20),
                ),
                const SizedBox(width: 8),
                Text(
                  status.displayName,
                  style: TextStyle(
                    fontSize: responsive.getResponsiveFontSize(16),
                    fontWeight: FontWeight.w600,
                    color: status.color,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: status.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: TextStyle(
                      fontSize: responsive.getResponsiveFontSize(12),
                      fontWeight: FontWeight.w600,
                      color: status.color,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tasks list
          Expanded(
            child:
                tasks.isEmpty
                    ? _buildEmptyState(status, responsive)
                    : ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ResponsiveTaskCard(
                            task: task,
                            onEdit: () => widget.onEditTask(task),
                            onDelete: () => widget.onDeleteTask(task),
                            onStatusChanged: (newStatus) {
                              taskProvider.updateTaskStatus(task.id, newStatus);
                            },
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(TaskStatus status, ResponsiveProvider responsive) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            status.icon,
            size: responsive.getResponsiveFontSize(48),
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz ${status.displayName.toLowerCase()} görev yok',
            style: TextStyle(
              fontSize: responsive.getResponsiveFontSize(16),
              color: AppColors.textHint,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class ResponsiveWebSidePanel extends StatelessWidget {
  final List<Task> tasks;
  final Function() onAddTask;
  final Function() onManagePeople;
  final Function()? onShowFilters;

  const ResponsiveWebSidePanel({
    super.key,
    required this.tasks,
    required this.onAddTask,
    required this.onManagePeople,
    this.onShowFilters,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Provider.of<ResponsiveProvider>(context, listen: false);
    final sidebarWidth = responsive.responsiveValue(
      mobile: 0.0,
      tablet: 280.0,
      desktop: 320.0,
    );

    return Container(
      width: sidebarWidth,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickStats(),
          const SizedBox(height: 24),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final todoCount = tasks.where((t) => t.status == TaskStatus.todo).length;
    final inProgressCount =
        tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final doneCount = tasks.where((t) => t.status == TaskStatus.done).length;
    final blockedCount =
        tasks.where((t) => t.status == TaskStatus.blocked).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Görev Özeti',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatItem('Yapılacak', todoCount, AppColors.todoColor),
            _buildStatItem(
              'Devam Ediyor',
              inProgressCount,
              AppColors.inProgressColor,
            ),
            _buildStatItem('Tamamlandı', doneCount, AppColors.doneColor),
            _buildStatItem('Bloke', blockedCount, AppColors.blockedColor),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    final recentTasks = tasks.take(3).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Son Aktiviteler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            if (recentTasks.isEmpty)
              const Text(
                'Henüz aktivite yok',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              )
            else
              ...recentTasks.map((task) => _buildActivityItem(task)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(Task task) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.getStatusColor(task.status.value),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  task.status.displayName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Enhanced drag scroll behavior that supports mouse dragging
class _DragScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}
