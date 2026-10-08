// lib/providers/project_provider.dart
//
// State management for Projects list and detail.
// Supports search, status filtering, pull-to-refresh, and pagination.

import 'package:flutter/material.dart';
import '../core/error_handler.dart';
import '../models/pagination.dart';
import '../models/project.dart';
import '../services/project_service.dart';

class ProjectProvider extends ChangeNotifier {
  final ProjectService _service;

  List<Project> _projects = [];
  Pagination? _pagination;
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  AppException? _error;

  String _search = '';
  String? _status; // e.g. 'NOT_STARTED', 'IN_PROGRESS', 'COMPLETED' or null for All

  ProjectProvider({ProjectService? service})
      : _service = service ?? ProjectService();

  List<Project> get projects => _projects;
  Pagination? get pagination => _pagination;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isLoadingMore => _isLoadingMore;
  AppException? get error => _error;
  String get search => _search;
  String? get status => _status;
  bool get hasMore =>
      _pagination != null && _pagination!.page < _pagination!.totalPages;

  /// Sets the search keyword and immediately triggers a reload.
  void setSearch(String query) {
    if (_search == query) return;
    _search = query;
    loadProjects();
  }

  /// Sets the status filter and immediately triggers a reload.
  void setStatus(String? status) {
    if (_status == status) return;
    _status = status;
    loadProjects();
  }

  /// Loads the first page of projects.
  /// If [isRefresh] is true, preserves existing [_projects] while loading in background.
  Future<bool> loadProjects({bool isRefresh = false}) async {
    if (isRefresh) {
      _isRefreshing = true;
    } else {
      if (_projects.isEmpty) {
        _isLoading = true;
      }
    }
    _error = null;
    notifyListeners();

    try {
      final result = await _service.getProjects(
        search: _search,
        status: _status,
        page: 1,
        limit: 20,
      );
      _projects = result.projects;
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

  /// Loads the next page of projects and appends them to the current list.
  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore || _pagination == null) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _pagination!.page + 1;
      final result = await _service.getProjects(
        search: _search,
        status: _status,
        page: nextPage,
        limit: 20,
      );
      _projects.addAll(result.projects);
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

  /// Fetches an individual project by ID.
  Future<Project> getProject(String id) async {
    return await _service.getProjectById(id);
  }
}
