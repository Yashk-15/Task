// lib/screens/tasks_screen.dart
//
// The global Tasks tab:
// - Shows all tasks across all projects (GET /tasks).
// - Shows project name on each task tile (tapping it opens that project).
// - Search box with 400ms debounce.
// - Filter chips for status and priority.
// - Floating Action Button "Add task" opens the form with a project selector dropdown.
// - Pull-to-refresh, infinite scroll pagination, empty state, and error handling.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/project_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/task_form_sheet.dart';
import '../widgets/task_tile.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taskProvider = context.read<TaskProvider>();
      if (taskProvider.tasks.isEmpty) {
        taskProvider.loadTasks();
      }
      final projectProvider = context.read<ProjectProvider>();
      if (projectProvider.projects.isEmpty) {
        projectProvider.loadProjects();
      }
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

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        context.read<TaskProvider>().setSearch(query);
      }
    });
  }

  Future<void> _onRefresh() async {
    final provider = context.read<TaskProvider>();
    final ok = await provider.loadTasks(isRefresh: true);
    if (!ok && mounted && provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final tasks = provider.tasks;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Preload projects if not yet cached
          final projectProvider = context.read<ProjectProvider>();
          if (projectProvider.projects.isEmpty) {
            await projectProvider.loadProjects();
          }
          if (!context.mounted) return;

          final created = await TaskFormSheet.show(
            context,
            taskProvider: context.read<TaskProvider>(),
          );
          if (created == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Task created successfully')),
            );
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add task'),
      ),
      body: Column(
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          context.read<TaskProvider>().setSearch('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Filters: Status and Priority chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                // Status chips
                ChoiceChip(
                  label: const Text('All Status'),
                  selected: provider.status == null,
                  onSelected: (_) => provider.setStatus(null),
                ),
                const SizedBox(width: 6),
                ...TaskStatus.values.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(s.label),
                      selected: provider.status == s.toApiString(),
                      onSelected: (_) => provider.setStatus(s.toApiString()),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Priority chips
                ChoiceChip(
                  label: const Text('All Priority'),
                  selected: provider.priority == null,
                  onSelected: (_) => provider.setPriority(null),
                ),
                const SizedBox(width: 6),
                ...TaskPriority.values.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(p.label),
                      selected: provider.priority == p.toApiString(),
                      onSelected: (_) =>
                          provider.setPriority(p.toApiString()),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Main task list
          Expanded(
            child: Builder(
              builder: (context) {
                // Initial loading
                if (provider.isLoading && tasks.isEmpty) {
                  return const LoadingView(message: 'Loading tasks...');
                }

                // Initial error
                if (provider.error != null && tasks.isEmpty) {
                  return ErrorView(
                    message: provider.error!.message,
                    onRetry: () => provider.loadTasks(),
                  );
                }

                // Empty state
                if (tasks.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 64,
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.task_alt_rounded,
                              size: 64,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No tasks found',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Try adjusting your search query or filters, or tap "Add task" to create one.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // Task list
                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 4, bottom: 80),
                    itemCount: tasks.length + (provider.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
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
                        showProjectName: true,
                      );
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
}
