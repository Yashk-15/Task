// lib/models/dashboard_stats.dart
//
// Mirrors the DashboardStats object returned by GET /api/dashboard.
// See backend/src/services/dashboard.service.ts for the exact field names.

class DashboardStats {
  final int totalProjects;
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int projectsInProgress;

  const DashboardStats({
    required this.totalProjects,
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.projectsInProgress,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalProjects: (json['totalProjects'] as num).toInt(),
      totalTasks: (json['totalTasks'] as num).toInt(),
      completedTasks: (json['completedTasks'] as num).toInt(),
      pendingTasks: (json['pendingTasks'] as num).toInt(),
      projectsInProgress: (json['projectsInProgress'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'totalProjects': totalProjects,
        'totalTasks': totalTasks,
        'completedTasks': completedTasks,
        'pendingTasks': pendingTasks,
        'projectsInProgress': projectsInProgress,
      };
}
