// lib/widgets/task_tile.dart
//
// Reusable task item widget displayed in lists.
// Includes:
// - Checkbox for instant optimistic completion with rollback on failure
// - Priority and Status color-coded chips
// - Due date with red highlight when overdue
// - Project name link (navigates to Project Detail)
// - Popup menu to change Status, Priority, Edit, or Delete (with confirmation)

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/date_utils.dart';
import '../core/error_handler.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import 'task_form_sheet.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final bool showProjectName;

  const TaskTile({
    super.key,
    required this.task,
    this.showProjectName = false,
  });

  Color _priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return const Color(0xFFDC2626); // Red
      case TaskPriority.medium:
        return const Color(0xFFD97706); // Amber
      case TaskPriority.low:
        return const Color(0xFF059669); // Green
    }
  }

  Color _statusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.completed:
        return const Color(0xFF16A34A); // Green
      case TaskStatus.inProgress:
        return const Color(0xFF2563EB); // Blue
      case TaskStatus.pending:
        return const Color(0xFFEA580C); // Orange
    }
  }

  Future<void> _handleToggleComplete(BuildContext context) async {
    final taskProvider = context.read<TaskProvider>();
    try {
      await taskProvider.toggleComplete(task);
    } on AppException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleChangeStatus(
    BuildContext context,
    TaskStatus newStatus,
  ) async {
    final taskProvider = context.read<TaskProvider>();
    try {
      await taskProvider.changeStatus(task, newStatus);
    } on AppException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleChangePriority(
    BuildContext context,
    TaskPriority newPriority,
  ) async {
    final taskProvider = context.read<TaskProvider>();
    try {
      await taskProvider.changePriority(task, newPriority);
    } on AppException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleEdit(BuildContext context) async {
    final updated = await TaskFormSheet.show(
      context,
      task: task,
      fixedProjectId: task.projectId,
      taskProvider: context.read<TaskProvider>(),
    );
    if (updated == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task updated successfully')),
      );
    }
  }

  Future<void> _handleDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final taskProvider = context.read<TaskProvider>();
      try {
        await taskProvider.deleteTask(task.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task deleted')),
          );
        }
      } on AppException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = task.status == TaskStatus.completed;
    final overdue = AppDateUtils.isOverdue(task.dueDate, task.status);

    final priorityColor = _priorityColor(task.priority);
    final statusColor = _statusColor(task.status);

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Checkbox, Name, and Menu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mark Complete Checkbox
                SizedBox(
                  width: 32,
                  height: 32,
                  child: Checkbox(
                    value: isCompleted,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    onChanged: (_) => _handleToggleComplete(context),
                  ),
                ),
                const SizedBox(width: 8),

                // Task Name & Optional description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: isCompleted
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      if (task.description != null &&
                          task.description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          task.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Overflow menu for Status, Priority, Edit, Delete
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  tooltip: 'Task actions',
                  onSelected: (action) {
                    if (action == 'edit') {
                      _handleEdit(context);
                    } else if (action == 'delete') {
                      _handleDelete(context);
                    } else if (action.startsWith('status:')) {
                      final statusKey = action.substring(7);
                      _handleChangeStatus(
                        context,
                        TaskStatusX.fromString(statusKey),
                      );
                    } else if (action.startsWith('priority:')) {
                      final priorityKey = action.substring(9);
                      _handleChangePriority(
                        context,
                        TaskPriorityX.fromString(priorityKey),
                      );
                    }
                  },
                  itemBuilder: (ctx) => [
                    // Status subheader
                    const PopupMenuItem(
                      enabled: false,
                      child: Text(
                        'Change Status',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...TaskStatus.values.map(
                      (s) => PopupMenuItem(
                        value: 'status:${s.toApiString()}',
                        child: Row(
                          children: [
                            Icon(
                              s == task.status
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              size: 16,
                              color: _statusColor(s),
                            ),
                            const SizedBox(width: 8),
                            Text(s.label),
                          ],
                        ),
                      ),
                    ),
                    const PopupMenuDivider(),

                    // Priority subheader
                    const PopupMenuItem(
                      enabled: false,
                      child: Text(
                        'Change Priority',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...TaskPriority.values.map(
                      (p) => PopupMenuItem(
                        value: 'priority:${p.toApiString()}',
                        child: Row(
                          children: [
                            Icon(
                              p == task.priority
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              size: 16,
                              color: _priorityColor(p),
                            ),
                            const SizedBox(width: 8),
                            Text(p.label),
                          ],
                        ),
                      ),
                    ),
                    const PopupMenuDivider(),

                    // Edit
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Edit Task'),
                        ],
                      ),
                    ),

                    // Delete
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Metadata row: Project name (if enabled)
            if (showProjectName) ...[
              Padding(
                padding: const EdgeInsets.only(left: 40, bottom: 6),
                child: InkWell(
                  onTap: () => context.push('/projects/${task.projectId}'),
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.folder_outlined,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.project?.name ?? 'View project',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Bottom Badges Row: Priority chip, Status chip, Due Date
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Priority Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: priorityColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      task.priority.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: priorityColor,
                      ),
                    ),
                  ),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      task.status.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),

                  // Due Date
                  if (task.dueDate != null) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          overdue
                              ? Icons.error_outline_rounded
                              : Icons.calendar_today_outlined,
                          size: 13,
                          color: overdue
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppDateUtils.formatDisplay(task.dueDate),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: overdue
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: overdue
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
