import 'package:flutter/material.dart';
import '../models/task.dart';
import '../utils/theme.dart';
import '../utils/platform_utils.dart';

class ResponsiveTaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(TaskStatus) onStatusChanged;
  final bool isDragging;

  const ResponsiveTaskCard({
    super.key,
    required this.task,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChanged,
    this.isDragging = false,
  });

  @override
  State<ResponsiveTaskCard> createState() => _ResponsiveTaskCardState();
}

class _ResponsiveTaskCardState extends State<ResponsiveTaskCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: MouseRegion(
            onEnter: (_) => _handleHover(true),
            onExit: (_) => _handleHover(false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: _isHovered ? 8 : 2,
                shadowColor: AppColors.cardShadow,
                shape: RoundedRectangleBorder(
                  borderRadius: PlatformUtils.getCardRadius(),
                  side: BorderSide(
                    color:
                        _isHovered
                            ? AppTheme.getStatusColor(
                              widget.task.status.value,
                            ).withOpacity(0.3)
                            : AppColors.divider,
                    width: _isHovered ? 2 : 1,
                  ),
                ),
                child: InkWell(
                  onTap: widget.onEdit,
                  borderRadius: PlatformUtils.getCardRadius(),
                  child: Padding(
                    padding: PlatformUtils.getCardPadding(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTaskHeader(),
                        const SizedBox(height: 8),
                        _buildTaskContent(),
                        const SizedBox(height: 12),
                        _buildTaskFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.getStatusColor(
              widget.task.status.value,
            ).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.task.taskNumber,
            style: AppTheme.getResponsiveTextStyle(
              context,
              baseFontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.getStatusColor(widget.task.status.value),
            ),
          ),
        ),
        const Spacer(),
        if (_isHovered) ...[
          _buildActionButton(
            icon: Icons.edit,
            color: AppColors.primary,
            onTap: widget.onEdit,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.delete_outline,
            color: AppColors.error,
            onTap: widget.onDelete,
          ),
        ],
      ],
    );
  }

  Widget _buildTaskContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.task.title,
          style: AppTheme.getResponsiveTextStyle(
            context,
            baseFontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (widget.task.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            widget.task.description,
            style: AppTheme.getResponsiveTextStyle(
              context,
              baseFontSize: 14,
              color: AppColors.textSecondary,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildTaskFooter() {
    return Row(
      children: [
        if (widget.task.assignedToName != null) ...[
          _buildAssigneeChip(),
          const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _buildAssigneeChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 8,
            backgroundColor: AppColors.primary,
            child: Text(
              widget.task.assignedToName!.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            widget.task.assignedToName!,
            style: AppTheme.getResponsiveTextStyle(
              context,
              baseFontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  void _handleHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });

    if (isHovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }
}

class ResponsiveDraggableTaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(TaskStatus) onStatusChanged;

  const ResponsiveDraggableTaskCard({
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
        borderRadius: PlatformUtils.getCardRadius(),
        child: Container(
          width: PlatformUtils.getTaskCardWidth(context) * 0.9,
          constraints: const BoxConstraints(maxHeight: 200),
          child: ResponsiveTaskCard(
            task: task,
            onEdit: onEdit,
            onDelete: onDelete,
            onStatusChanged: onStatusChanged,
            isDragging: true,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: ResponsiveTaskCard(
          task: task,
          onEdit: onEdit,
          onDelete: onDelete,
          onStatusChanged: onStatusChanged,
        ),
      ),
      child: ResponsiveTaskCard(
        task: task,
        onEdit: onEdit,
        onDelete: onDelete,
        onStatusChanged: onStatusChanged,
      ),
    );
  }
}

class ResponsiveTaskDropZone extends StatefulWidget {
  final TaskStatus status;
  final List<Task> tasks;
  final Function(Task, TaskStatus) onTaskDropped;
  final Function(Task) onTaskEdit;
  final Function(Task) onTaskDelete;

  const ResponsiveTaskDropZone({
    super.key,
    required this.status,
    required this.tasks,
    required this.onTaskDropped,
    required this.onTaskEdit,
    required this.onTaskDelete,
  });

  @override
  State<ResponsiveTaskDropZone> createState() => _ResponsiveTaskDropZoneState();
}

class _ResponsiveTaskDropZoneState extends State<ResponsiveTaskDropZone>
    with SingleTickerProviderStateMixin {
  bool _isDragOver = false;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<Task>(
      onAccept: (task) {
        if (task.status != widget.status) {
          widget.onTaskDropped(task, widget.status);
        }
        setState(() => _isDragOver = false);
        _animationController.stop();
      },
      onWillAccept: (task) {
        setState(() => _isDragOver = true);
        _animationController.repeat(reverse: true);
        return task != null && task.status != widget.status;
      },
      onLeave: (task) {
        setState(() => _isDragOver = false);
        _animationController.stop();
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isDragOver ? _pulseAnimation.value : 1.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(8),
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
                child:
                    widget.tasks.isEmpty
                        ? _buildEmptyDropZone()
                        : _buildTaskList(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyDropZone() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border, style: BorderStyle.none),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getStatusIcon(),
              size: 48,
              color: AppTheme.getStatusColor(
                widget.status.value,
              ).withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              _isDragOver
                  ? 'Görevi buraya bırakın'
                  : 'Henüz ${widget.status.displayName.toLowerCase()} görev yok',
              style: AppTheme.getResponsiveTextStyle(
                context,
                baseFontSize: 14,
                color:
                    _isDragOver
                        ? AppTheme.getStatusColor(widget.status.value)
                        : AppColors.textSecondary,
                fontWeight: _isDragOver ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: widget.tasks.length,
      itemBuilder: (context, index) {
        final task = widget.tasks[index];
        return ResponsiveDraggableTaskCard(
          task: task,
          onEdit: () => widget.onTaskEdit(task),
          onDelete: () => widget.onTaskDelete(task),
          onStatusChanged: (newStatus) => widget.onTaskDropped(task, newStatus),
        );
      },
    );
  }

  IconData _getStatusIcon() {
    switch (widget.status) {
      case TaskStatus.todo:
        return Icons.assignment_outlined;
      case TaskStatus.inProgress:
        return Icons.work_outline;
      case TaskStatus.done:
        return Icons.check_circle_outline;
      case TaskStatus.blocked:
        return Icons.block_outlined;
    }
  }
}
