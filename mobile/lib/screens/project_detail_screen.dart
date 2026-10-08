// lib/screens/project_detail_screen.dart
//
// Project detail screen:
// - Shows project info (name, description, status, date range, created date) at top.
// - Project-specific tasks list (GET /tasks?projectId=...).
// - Task search box (debounced), status chips, and priority chips.
// - Reusable TaskTile widgets.
// - Pull-to-refresh, empty state ("No tasks yet").
// - Floating Action Button "Add task" pre-populates this project.
// - Back navigation works out-of-the-box.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/date_utils.dart';
import '../core/error_handler.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../providers/project_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/task_form_sheet.dart';
import '../widgets/task_tile.dart';

class ProjectDetailScreen extends StatelessWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    // We scope a dedicated TaskProvider specifically for this project
    // so it doesn't conflict with or overwrite the global Tasks tab filters.
    return ChangeNotifierProvider<TaskProvider>(
      create: (_) => TaskProvider()..setProjectId(projectId),
      child: _ProjectDetailBody(projectId: projectId),
    );
  }
}

class _ProjectDetailBody extends StatefulWidget {
  final String projectId;

  const _ProjectDetailBody({required this.projectId});

  @override
  State<_ProjectDetailBody> createState() => _ProjectDetailBodyState();
}

class _ProjectDetailBodyState extends State<_ProjectDetailBody> {
  Project? _project;
  bool _isLoadingProject = false;
  AppException? _projectError;

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProjectDetails();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<TaskProvider>().loadMore();
    }
  }

  Future<void> _loadProjectDetails() async {
    setState(() {
      _isLoadingProject = true;
      _projectError = null;
    });

    try {
      final projectProvider = context.read<ProjectProvider>();
      final project = await projectProvider.getProject(widget.projectId);
      if (mounted) {
        setState(() {
          _project = project;
          _isLoadingProject = false;
        });
      }
    } on AppException catch (e) {
      if (mounted) {
        setState(() {
          _projectError = e;
          _isLoadingProject = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _projectError = AppException(message: e.toString());
          _isLoadingProject = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        context.read<TaskProvider>().setSearch(query);
      }
    });
  }

  Future<void> _onRefresh() async {
    final taskProvider = context.read<TaskProvider>();
    await Future.wait([
      _loadProjectDetails(),
      taskProvider.loadTasks(isRefresh: true),
    ]);
  }

  Color _statusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.completed:
        return const Color(0xFF16A34A);
      case ProjectStatus.inProgress:
        return const Color(0xFF2563EB);
      case ProjectStatus.notStarted:
        return const Color(0xFF64748B);
    }
  }

  Widget _buildProjectHeader(Project project) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(project.status);

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name and Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    project.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    project.status.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            // Description
            if (project.description != null &&
                project.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                project.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Dates metadata
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Start - End dates
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppDateUtils.formatRange(
                        project.startDate,
                        project.endDate,
                      ),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                // Created date
                if (project.createdAt != null) ...[
                  Text(
                    'Created: ${AppDateUtils.formatDisplay(project.createdAt)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final tasks = taskProvider.tasks;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_project?.name ?? 'Project Details'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await TaskFormSheet.show(
            context,
            fixedProjectId: widget.projectId,
            taskProvider: context.read<TaskProvider>(),
          );
          if (created == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Task added to project')),
            );
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add task'),
      ),
      body: Builder(
        builder: (context) {
          // If project itself is loading and not available yet
          if (_isLoadingProject && _project == null) {
            return const LoadingView(message: 'Loading project details...');
          }

          // If project failed to load
          if (_projectError != null && _project == null) {
            return ErrorView(
              message: _projectError!.message,
              onRetry: _loadProjectDetails,
            );
          }

          final project = _project!;

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Top project info
                SliverToBoxAdapter(
                  child: _buildProjectHeader(project),
                ),

                // Tasks Section Title
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tasks',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${tasks.length} ${tasks.length == 1 ? 'task' : 'tasks'}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Task Search Box
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search tasks in this project...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  taskProvider.setSearch('');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ),

                // Status & Priority Filter Chips
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        // Status chips
                        ChoiceChip(
                          label: const Text('All Status'),
                          selected: taskProvider.status == null,
                          onSelected: (_) => taskProvider.setStatus(null),
                        ),
                        const SizedBox(width: 6),
                        ...TaskStatus.values.map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(s.label),
                              selected: taskProvider.status == s.toApiString(),
                              onSelected: (_) =>
                                  taskProvider.setStatus(s.toApiString()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Priority chips
                        ChoiceChip(
                          label: const Text('All Priority'),
                          selected: taskProvider.priority == null,
                          onSelected: (_) => taskProvider.setPriority(null),
                        ),
                        const SizedBox(width: 6),
                        ...TaskPriority.values.map(
                          (p) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(p.label),
                              selected:
                                  taskProvider.priority == p.toApiString(),
                              onSelected: (_) =>
                                  taskProvider.setPriority(p.toApiString()),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Tasks list / Empty state / Loading
                if (taskProvider.isLoading && tasks.isEmpty)
                  const SliverFillRemaining(
                    child: LoadingView(message: 'Loading tasks...'),
                  )
                else if (taskProvider.error != null && tasks.isEmpty)
                  SliverFillRemaining(
                    child: ErrorView(
                      message: taskProvider.error!.message,
                      onRetry: () => taskProvider.loadTasks(),
                    ),
                  )
                else if (tasks.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.task_alt_rounded,
                              size: 56,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No tasks yet',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap "Add task" below to create the first task for this project.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == tasks.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        }
                        return TaskTile(
                          task: tasks[index],
                          showProjectName: false,
                        );
                      },
                      childCount:
                          tasks.length + (taskProvider.isLoadingMore ? 1 : 0),
                    ),
                  ),

                // Bottom padding for FAB
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
