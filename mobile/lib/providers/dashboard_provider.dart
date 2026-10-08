// lib/providers/dashboard_provider.dart
//
// State management for the Dashboard metrics tab.
// Handles loading, pull-to-refresh, and error propagation.

import 'package:flutter/material.dart';
import '../core/error_handler.dart';
import '../models/dashboard_stats.dart';
import '../services/dashboard_service.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardService _service;

  DashboardStats? _stats;
  bool _isLoading = false;
  bool _isRefreshing = false;
  AppException? _error;

  DashboardProvider({DashboardService? service})
      : _service = service ?? DashboardService();

  DashboardStats? get stats => _stats;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  AppException? get error => _error;

  /// Loads dashboard metrics.
  /// If [isRefresh] is true, keeps existing [_stats] so the screen doesn't flicker or go blank.
  Future<bool> loadDashboard({bool isRefresh = false}) async {
    if (isRefresh) {
      _isRefreshing = true;
    } else {
      if (_stats == null) {
        _isLoading = true;
      }
    }
    _error = null;
    notifyListeners();

    try {
      _stats = await _service.getDashboardStats();
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

  /// Clears the current error.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
