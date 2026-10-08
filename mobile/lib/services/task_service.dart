// lib/services/task_service.dart
//
// Service for Task API endpoints:
// - GET /tasks (filtered by projectId, search, status, priority, page, limit)
// - GET /tasks/:id
// - POST /tasks
// - PUT /tasks/:id
// - DELETE /tasks/:id

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../core/api_client.dart';
import '../core/error_handler.dart';
import '../models/pagination.dart';
import '../models/task.dart';

/// Container for task list and pagination metadata.
class TaskListResult {
  final List<Task> tasks;
  final Pagination pagination;

  const TaskListResult({
    required this.tasks,
    required this.pagination,
  });
}

class TaskService {
  final Dio _dio;
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  TaskService({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  /// Fetches a paginated list of tasks matching the supplied filters.
  /// Server response shape:
  /// { success: true, data: [...tasks], pagination: { page, limit, total, totalPages } }
  Future<TaskListResult> getTasks({
    String? projectId,
    String? search,
    String? status,
    String? priority,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (projectId != null && projectId.trim().isNotEmpty) {
        queryParams['projectId'] = projectId.trim();
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (status != null && status.trim().isNotEmpty) {
        queryParams['status'] = status.trim();
      }
      if (priority != null && priority.trim().isNotEmpty) {
        queryParams['priority'] = priority.trim();
      }

      final response = await _dio.get(
        '/tasks',
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final rawList = data['data'] as List<dynamic>? ?? [];
        final tasks = rawList
            .map((item) => Task.fromJson(item as Map<String, dynamic>))
            .toList();

        final pagination = data['pagination'] != null
            ? Pagination.fromJson(data['pagination'] as Map<String, dynamic>)
            : Pagination(page: page, limit: limit, total: tasks.length, totalPages: 1);

        return TaskListResult(
          tasks: tasks,
          pagination: pagination,
        );
      }

      throw const AppException(message: 'Invalid task list format received.');
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }

  /// Fetches a single task by ID.
  /// Server response shape: { success: true, data: { task: {...} } }
  Future<Task> getTaskById(String id) async {
    try {
      final response = await _dio.get('/tasks/$id');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        final inner = data['data'] as Map<String, dynamic>;
        final taskMap = inner['task'] ?? inner;
        return Task.fromJson(taskMap as Map<String, dynamic>);
      }
      throw const AppException(message: 'Invalid task data received.');
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }

  /// Creates a new task.
  /// Server response shape: { success: true, data: { task: {...} } }
  Future<Task> createTask({
    required String projectId,
    required String name,
    String? description,
    TaskPriority priority = TaskPriority.medium,
    TaskStatus status = TaskStatus.pending,
    DateTime? dueDate,
  }) async {
    try {
      final payload = <String, dynamic>{
        'projectId': projectId,
        'name': name.trim(),
        'priority': priority.toApiString(),
        'status': status.toApiString(),
      };

      if (description != null && description.trim().isNotEmpty) {
        payload['description'] = description.trim();
      }
      if (dueDate != null) {
        payload['dueDate'] = _dateFormat.format(dueDate);
      }

      final response = await _dio.post('/tasks', data: payload);
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        final inner = data['data'] as Map<String, dynamic>;
        final taskMap = inner['task'] ?? inner;
        return Task.fromJson(taskMap as Map<String, dynamic>);
      }
      throw const AppException(message: 'Failed to create task.');
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }

  /// Updates an existing task. Note: backend forbids changing projectId.
  /// Server response shape: { success: true, data: { task: {...} } }
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
      final payload = <String, dynamic>{};

      if (name != null) payload['name'] = name.trim();
      if (description != null) payload['description'] = description.trim();
      if (priority != null) payload['priority'] = priority.toApiString();
      if (status != null) payload['status'] = status.toApiString();
      if (clearDueDate) {
        payload['dueDate'] = null;
      } else if (dueDate != null) {
        payload['dueDate'] = _dateFormat.format(dueDate);
      }

      final response = await _dio.put('/tasks/$id', data: payload);
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        final inner = data['data'] as Map<String, dynamic>;
        final taskMap = inner['task'] ?? inner;
        return Task.fromJson(taskMap as Map<String, dynamic>);
      }
      throw const AppException(message: 'Failed to update task.');
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }

  /// Deletes a task by ID.
  /// Server response shape: { success: true, message: "..." }
  Future<void> deleteTask(String id) async {
    try {
      await _dio.delete('/tasks/$id');
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }
}
