// lib/providers/task_provider.dart
//
// State management for Tasks.
// Handles filtering (by project, status, priority, search),
// pagination, optimistic updates, and CRUD operations.

import 'package:flutter/material.dart';
import '../core/error_handler.dart';
import '../models/pagination.dart';
import '../models/task.dart';
import '../services/task_service.dart';

class TaskProvider extends ChangeNotifier {
  final TaskService _service;

  List<Task> _tasks = [];
  Pagination? _pagination;
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  AppException? _error;

  // Filter criteria
  String? _projectId;
  String _search = '';
  String? _status; // 'PENDING', 'IN_PROGRESS', 'COMPLETED', or null
  String? _priority; // 'LOW', 'MEDIUM', 'HIGH', or null

  TaskProvider({TaskService? service}) : _service = service ?? TaskService();

  List<Task> get tasks => _tasks;
  Pagination? get pagination => _pagination;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isLoadingMore => _isLoadingMore;
  AppException? get error => _error;

  String? get projectId => _projectId;
  String get search => _search;
  String? get status => _status;
  String? get priority => _priority;
  bool get hasMore =>
      _pagination != null && _pagination!.page < _pagination!.totalPages;

  /// Updates all filter parameters and reloads tasks.
  void setFilters({
    String? projectId,
    String? search,
    String? status,
    String? priority,
  }) {
    _projectId = projectId;
    if (search != null) _search = search;
    _status = status;
    _priority = priority;
    loadTasks();
  }

  /// Sets the project filter. Pass null to show tasks across all projects.
  void setProjectId(String? projectId) {
    if (_projectId == projectId) return;
    _projectId = projectId;
    loadTasks();
  }

  /// Sets search term and reloads.
  void setSearch(String query) {
    if (_search == query) return;
    _search = query;
    loadTasks();
  }

  /// Sets status filter and reloads.
  void setStatus(String? status) {
    if (_status == status) return;
    _status = status;
    loadTasks();
  }

  /// Sets priority filter and reloads.
  void setPriority(String? priority) {
    if (_priority == priority) return;
    _priority = priority;
    loadTasks();
  }

  /// Loads the first page of tasks.
  /// If [isRefresh] is true, preserves [_tasks] to prevent blank screen flicker.
  Future<bool> loadTasks({bool isRefresh = false}) async {
    if (isRefresh) {
      _isRefreshing = true;
    } else {
      if (_tasks.isEmpty) {
        _isLoading = true;
      }
    }
    _error = null;
    notifyListeners();

    try {
      final result = await _service.getTasks(
        projectId: _projectId,
        search: _search,
        status: _status,
        priority: _priority,
        page: 1,
        limit: 20,
      );
      _tasks = result.tasks;
      _pagination = result.pagination;
      _error = null;
      return true;
    } on AppException catch (e) {
      _error = e;
      return false;
    } catch (e) {
      _error = AppException(message: e.toString());
      return false;
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Loads the next page of tasks and appends to the current list.
  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore || _pagination == null) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _pagination!.page + 1;
      final result = await _service.getTasks(
        projectId: _projectId,
        search: _search,
        status: _status,
        priority: _priority,
        page: nextPage,
        limit: 20,
      );
      _tasks.addAll(result.tasks);
      _pagination = result.pagination;
    } on AppException catch (e) {
      _error = e;
    } catch (e) {
      _error = AppException(message: e.toString());
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Creates a new task and adds it to the local list.
  Future<Task> createTask({
    required String projectId,
    required String name,
    String? description,
    TaskPriority priority = TaskPriority.medium,
    TaskStatus status = TaskStatus.pending,
    DateTime? dueDate,
  }) async {
    try {
      final created = await _service.createTask(
        projectId: projectId,
        name: name,
        description: description,
        priority: priority,
        status: status,
        dueDate: dueDate,
      );
      // Prepend to top of list if it matches current filter
      _tasks.insert(0, created);
      notifyListeners();
      return created;
    } on AppException {
      rethrow;
    }
  }

  /// Updates an existing task and replaces it in the local list.
  Future<Task> updateTask({
    required String id,
    String? name,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueDate,
    bool clearDueDate = false,
  }) async {
    try {
      final updated = await _service.updateTask(
        id: id,
        name: name,
        description: description,
        priority: priority,
        status: status,
        dueDate: dueDate,
        clearDueDate: clearDueDate,
      );
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        _tasks[index] = updated;
        notifyListeners();
      }
      return updated;
    } on AppException {
      rethrow;
    }
  }

  /// Optimistically toggles the completed status of a task.
  /// If the API call fails, rolls back the local change and throws [AppException].
  Future<void> toggleComplete(Task task) async {
    final originalIndex = _tasks.indexWhere((t) => t.id == task.id);
    if (originalIndex == -1) return;

    final targetStatus = task.status == TaskStatus.completed
        ? TaskStatus.pending
        : TaskStatus.completed;

    // Optimistic local update
    final updatedLocal = task.copyWith(status: targetStatus);
    _tasks[originalIndex] = updatedLocal;
    notifyListeners();

    try {
      final serverUpdated = await _service.updateTask(
        id: task.id,
        status: targetStatus,
      );
      // Confirm with server response
      final currentIndex = _tasks.indexWhere((t) => t.id == task.id);
      if (currentIndex != -1) {
        _tasks[currentIndex] = serverUpdated;
        notifyListeners();
      }
    } catch (e) {
      // Rollback to original on failure
      final currentIndex = _tasks.indexWhere((t) => t.id == task.id);
      if (currentIndex != -1) {
        _tasks[currentIndex] = task;
        notifyListeners();
      }
      if (e is AppException) rethrow;
      throw AppException(message: e.toString());
    }
  }

  /// Optimistically changes a task's status with rollback on failure.
  Future<void> changeStatus(Task task, TaskStatus newStatus) async {
    if (task.status == newStatus) return;

    final originalIndex = _tasks.indexWhere((t) => t.id == task.id);
    if (originalIndex == -1) return;

    final updatedLocal = task.copyWith(status: newStatus);
    _tasks[originalIndex] = updatedLocal;
    notifyListeners();

    try {
      final serverUpdated = await _service.updateTask(
        id: task.id,
        status: newStatus,
      );
      final currentIndex = _tasks.indexWhere((t) => t.id == task.id);
      if (currentIndex != -1) {
        _tasks[currentIndex] = serverUpdated;
        notifyListeners();
      }
    } catch (e) {
      final currentIndex = _tasks.indexWhere((t) => t.id == task.id);
      if (currentIndex != -1) {
        _tasks[currentIndex] = task;
        notifyListeners();
      }
      if (e is AppException) rethrow;
      throw AppException(message: e.toString());
    }
  }

  /// Optimistically changes a task's priority with rollback on failure.
  Future<void> changePriority(Task task, TaskPriority newPriority) async {
    if (task.priority == newPriority) return;

    final originalIndex = _tasks.indexWhere((t) => t.id == task.id);
    if (originalIndex == -1) return;

    final updatedLocal = task.copyWith(priority: newPriority);
    _tasks[originalIndex] = updatedLocal;
    notifyListeners();

    try {
      final serverUpdated = await _service.updateTask(
        id: task.id,
        priority: newPriority,
      );
      final currentIndex = _tasks.indexWhere((t) => t.id == task.id);
      if (currentIndex != -1) {
        _tasks[currentIndex] = serverUpdated;
        notifyListeners();
      }
    } catch (e) {
      final currentIndex = _tasks.indexWhere((t) => t.id == task.id);
      if (currentIndex != -1) {
        _tasks[currentIndex] = task;
        notifyListeners();
      }
      if (e is AppException) rethrow;
      throw AppException(message: e.toString());
    }
  }

  /// Deletes a task from the server and local list.
  Future<void> deleteTask(String id) async {
    final originalIndex = _tasks.indexWhere((t) => t.id == id);
    Task? removedTask;
    if (originalIndex != -1) {
      removedTask = _tasks.removeAt(originalIndex);
      notifyListeners();
    }

    try {
      await _service.deleteTask(id);
    } catch (e) {
      // Re-insert if deletion failed
      if (removedTask != null && originalIndex != -1) {
        _tasks.insert(originalIndex, removedTask);
        notifyListeners();
      }
      if (e is AppException) rethrow;
      throw AppException(message: e.toString());
    }
  }
}
