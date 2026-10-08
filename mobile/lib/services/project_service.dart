// lib/services/project_service.dart
//
// Service for Project API endpoints.
// Interacts with GET /projects and GET /projects/:id.

import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/error_handler.dart';
import '../models/pagination.dart';
import '../models/project.dart';

/// Container for projects list and its pagination metadata.
class ProjectListResult {
  final List<Project> projects;
  final Pagination pagination;

  const ProjectListResult({
    required this.projects,
    required this.pagination,
  });
}

class ProjectService {
  final Dio _dio;

  ProjectService({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  /// Fetches a paginated list of projects with optional search and status filter.
  /// Server response shape:
  /// { success: true, data: [...projects], pagination: { page, limit, total, totalPages } }
  Future<ProjectListResult> getProjects({
    String? search,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (status != null && status.trim().isNotEmpty) {
        queryParams['status'] = status.trim();
      }

      final response = await _dio.get(
        '/projects',
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final rawList = data['data'] as List<dynamic>? ?? [];
        final projects = rawList
            .map((item) => Project.fromJson(item as Map<String, dynamic>))
            .toList();

        final pagination = data['pagination'] != null
            ? Pagination.fromJson(data['pagination'] as Map<String, dynamic>)
            : Pagination(page: page, limit: limit, total: projects.length, totalPages: 1);

        return ProjectListResult(
          projects: projects,
          pagination: pagination,
        );
      }

      throw const AppException(message: 'Invalid project list format received.');
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }

  /// Fetches a single project by ID.
  /// Server response shape: { success: true, data: { project: {...} } }
  Future<Project> getProjectById(String id) async {
    try {
      final response = await _dio.get('/projects/$id');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        final inner = data['data'] as Map<String, dynamic>;
        final projectMap = inner['project'] ?? inner;
        return Project.fromJson(projectMap as Map<String, dynamic>);
      }
      throw const AppException(message: 'Invalid project data received.');
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }
}
