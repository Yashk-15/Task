// lib/services/dashboard_service.dart
//
// Service for fetching dashboard summary statistics.
// Calls GET /dashboard and transforms the response into a DashboardStats model.

import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/error_handler.dart';
import '../models/dashboard_stats.dart';

class DashboardService {
  final Dio _dio;

  DashboardService({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  /// Fetches aggregate stats for the authenticated user.
  /// Backend response shape: { success: true, data: { totalProjects, ... } }
  Future<DashboardStats> getDashboardStats() async {
    try {
      final response = await _dio.get('/dashboard');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return DashboardStats.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw const AppException(message: 'Unexpected server response format.');
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }
}
