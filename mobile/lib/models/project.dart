// lib/models/project.dart
//
// Dart model for a Project returned by the API.
//
// Server response shape (from project.service.ts formatProject helper):
//   { id, userId?, name, description, status, startDate, endDate,
//     createdAt, taskCount, _count? }
//
// Allowed status values: NOT_STARTED | IN_PROGRESS | COMPLETED

// Enum for project status — mirrors the Prisma/backend enum.
enum ProjectStatus { notStarted, inProgress, completed }

extension ProjectStatusX on ProjectStatus {
  /// Convert from the API string to our enum.
  static ProjectStatus fromString(String value) {
    switch (value) {
      case 'IN_PROGRESS':
        return ProjectStatus.inProgress;
      case 'COMPLETED':
        return ProjectStatus.completed;
      case 'NOT_STARTED':
      default:
        return ProjectStatus.notStarted;
    }
  }

  /// Convert back to the API string so we can send it in requests.
  String toApiString() {
    switch (this) {
      case ProjectStatus.inProgress:
        return 'IN_PROGRESS';
      case ProjectStatus.completed:
        return 'COMPLETED';
      case ProjectStatus.notStarted:
        return 'NOT_STARTED';
    }
  }

  /// A nice label for display in the UI.
  String get label {
    switch (this) {
      case ProjectStatus.notStarted:
        return 'Not Started';
      case ProjectStatus.inProgress:
        return 'In Progress';
      case ProjectStatus.completed:
        return 'Completed';
    }
  }
}

class Project {
  final String id;
  final String name;

  // Nullable fields — the backend allows null for all of these.
  final String? description;
  final ProjectStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;

  // taskCount is added by the backend's formatProject() helper.
  final int taskCount;

  const Project({
    required this.id,
    required this.name,
    this.description,
    required this.status,
    this.startDate,
    this.endDate,
    this.createdAt,
    required this.taskCount,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      status: ProjectStatusX.fromString(json['status'] as String? ?? ''),
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      createdAt: _parseDate(json['createdAt']),
      // taskCount is injected by the server's formatProject helper.
      taskCount: (json['taskCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        'status': status.toApiString(),
        if (startDate != null) 'startDate': startDate!.toIso8601String(),
        if (endDate != null) 'endDate': endDate!.toIso8601String(),
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        'taskCount': taskCount,
      };
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  try {
    return DateTime.parse(value as String);
  } catch (_) {
    return null;
  }
}
