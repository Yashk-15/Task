// lib/widgets/task_form_sheet.dart
//
// Modal bottom sheet for creating or editing a task.
// Features:
// - Form validation (name required, max 150 chars; max 2000 description)
// - Date picker with clear option
// - Priority and Status dropdowns
// - Project selector (if not opened from within a project)
// - Server field error display
// - Disabled button with spinner while saving

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/date_utils.dart';
import '../core/error_handler.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../providers/project_provider.dart';
import '../providers/task_provider.dart';

class TaskFormSheet extends StatefulWidget {
  final Task? task;
  final String? fixedProjectId;
  final TaskProvider? taskProvider;

  const TaskFormSheet({
    super.key,
    this.task,
    this.fixedProjectId,
    this.taskProvider,
  });

  /// Helper to display the form inside a bottom sheet
  static Future<bool?> show(
    BuildContext context, {
    Task? task,
    String? fixedProjectId,
    TaskProvider? taskProvider,
  }) {
    final tp = taskProvider ?? context.read<TaskProvider>();

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => TaskFormSheet(
        task: task,
        fixedProjectId: fixedProjectId,
        taskProvider: tp,
      ),
    );
  }

  @override
  State<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  late TaskPriority _priority;
  late TaskStatus _status;
  DateTime? _dueDate;
  String? _selectedProjectId;

  bool _isSaving = false;
  Map<String, String> _serverFieldErrors = {};
  List<Project> _availableProjects = [];

  bool get isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _nameController = TextEditingController(text: task?.name ?? '');
    _descriptionController = TextEditingController(
      text: task?.description ?? '',
    );
    _priority = task?.priority ?? TaskPriority.medium;
    _status = task?.status ?? TaskStatus.pending;
    _dueDate = task?.dueDate;
    _selectedProjectId = widget.fixedProjectId ?? task?.projectId;

    // Load available projects synchronously from ProjectProvider
    _availableProjects = List.from(context.read<ProjectProvider>().projects);
    if (_selectedProjectId == null && _availableProjects.isNotEmpty) {
      _selectedProjectId = _availableProjects.first.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final initial = _dueDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _save() async {
    _serverFieldErrors.clear();
    if (!_formKey.currentState!.validate()) return;

    final projectId = _selectedProjectId ?? widget.fixedProjectId;
    if (projectId == null || projectId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a project.')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final taskProvider = widget.taskProvider ?? context.read<TaskProvider>();
      if (isEditing) {
        await taskProvider.updateTask(
          id: widget.task!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _priority,
          status: _status,
          dueDate: _dueDate,
          clearDueDate: _dueDate == null,
        );
      } else {
        await taskProvider.createTask(
          projectId: projectId,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _priority,
          status: _status,
          dueDate: _dueDate,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on AppException catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _serverFieldErrors = e.fieldErrors ?? {};
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Edit Task' : 'New Task',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Project Selector (only if not fixed to a project and creating)
                if (widget.fixedProjectId == null && !isEditing) ...[
                  if (_availableProjects.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No projects found. Please create a project first.',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue:
                          _availableProjects.any(
                            (p) => p.id == _selectedProjectId,
                          )
                          ? _selectedProjectId
                          : _availableProjects.first.id,
                      decoration: const InputDecoration(
                        labelText: 'Project *',
                        prefixIcon: Icon(Icons.folder_outlined),
                      ),
                      items: _availableProjects.map((p) {
                        return DropdownMenuItem(
                          value: p.id,
                          child: Text(p.name, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedProjectId = val);
                      },
                      validator: (val) => val == null || val.isEmpty
                          ? 'Please select a project'
                          : null,
                    ),
                  const SizedBox(height: 16),
                ],

                // Task Name
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Task Name *',
                    hintText: 'e.g. Design app homepage',
                    prefixIcon: const Icon(Icons.assignment_outlined),
                    errorText: _serverFieldErrors['name'],
                  ),
                  maxLength: 150,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'Task name is required';
                    if (text.length > 150) {
                      return 'Task name must be at most 150 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  maxLength: 2000,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'Additional details about this task...',
                    alignLabelWithHint: true,
                    errorText: _serverFieldErrors['description'],
                  ),
                ),
                const SizedBox(height: 12),

                // Priority & Status in a responsive row
                Row(
                  children: [
                    // Priority Dropdown
                    Expanded(
                      child: DropdownButtonFormField<TaskPriority>(
                        initialValue: _priority,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                        ),
                        items: TaskPriority.values.map((p) {
                          return DropdownMenuItem(
                            value: p,
                            child: Text(p.label),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _priority = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Status Dropdown
                    Expanded(
                      child: DropdownButtonFormField<TaskStatus>(
                        initialValue: _status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: TaskStatus.values.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Text(s.label),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _status = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Due Date selector
                // Due Date selector
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _dueDate == null
                            ? 'No due date set'
                            : 'Due: ${AppDateUtils.formatDisplay(_dueDate)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: _dueDate != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (_dueDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        tooltip: 'Clear due date',
                        onPressed: () => setState(() => _dueDate = null),
                      ),
                    FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 40),
                      ),
                      onPressed: _pickDueDate,
                      child: Text(_dueDate == null ? 'Set date' : 'Change'),
                    ),
                  ],
                ),
                if (_serverFieldErrors['dueDate'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _serverFieldErrors['dueDate']!,
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // Submit Button
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isEditing ? 'Save Changes' : 'Create Task'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
