// lib/models/task.dart
//
// Dart model for a Task returned by the API.
//
// Server response shape (from task.service.ts):
//   { id, projectId, name, description, priority, status,
//     dueDate, createdAt, project?: {id, name} }
//
// Allowed priority values: LOW | MEDIUM | HIGH
// Allowed status values:   PENDING | IN_PROGRESS | COMPLETED

// ─── Enums ────────────────────────────────────────────────────────────────────

enum TaskStatus { pending, inProgress, completed }

extension TaskStatusX on TaskStatus {
  static TaskStatus fromString(String value) {
    switch (value) {
      case 'IN_PROGRESS':
        return TaskStatus.inProgress;
      case 'COMPLETED':
        return TaskStatus.completed;
      case 'PENDING':
      default:
        return TaskStatus.pending;
    }
  }

  String toApiString() {
    switch (this) {
      case TaskStatus.inProgress:
        return 'IN_PROGRESS';
      case TaskStatus.completed:
        return 'COMPLETED';
      case TaskStatus.pending:
        return 'PENDING';
    }
  }

  String get label {
    switch (this) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
    }
  }
}

enum TaskPriority { low, medium, high }

extension TaskPriorityX on TaskPriority {
  static TaskPriority fromString(String value) {
    switch (value) {
      case 'HIGH':
        return TaskPriority.high;
      case 'MEDIUM':
        return TaskPriority.medium;
      case 'LOW':
      default:
        return TaskPriority.low;
    }
  }

  String toApiString() {
    switch (this) {
      case TaskPriority.high:
        return 'HIGH';
      case TaskPriority.medium:
        return 'MEDIUM';
      case TaskPriority.low:
        return 'LOW';
    }
  }

  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }
}

// ─── Task model ───────────────────────────────────────────────────────────────

/// Lightweight nested project info included in some task responses.
class TaskProject {
  final String id;
  final String name;

  const TaskProject({required this.id, required this.name});

  factory TaskProject.fromJson(Map<String, dynamic> json) =>
      TaskProject(id: json['id'] as String, name: json['name'] as String);
}

class Task {
  final String id;
  final String projectId;
  final String name;
  final String? description;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime? dueDate;
  final DateTime? createdAt;

  // Optional nested project info (present when fetching tasks across projects).
  final TaskProject? project;

  const Task({
    required this.id,
    required this.projectId,
    required this.name,
    this.description,
    required this.priority,
    required this.status,
    this.dueDate,
    this.createdAt,
    this.project,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      priority: TaskPriorityX.fromString(json['priority'] as String? ?? ''),
      status: TaskStatusX.fromString(json['status'] as String? ?? ''),
      dueDate: _parseDate(json['dueDate']),
      createdAt: _parseDate(json['createdAt']),
      project: json['project'] != null
          ? TaskProject.fromJson(json['project'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'name': name,
        if (description != null) 'description': description,
        'priority': priority.toApiString(),
        'status': status.toApiString(),
        if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
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
