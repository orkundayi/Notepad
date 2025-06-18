import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/task.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';

class TaskProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final Uuid _uuid = const Uuid();

  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _currentUserId;
  StreamSubscription<List<Task>>? _tasksSubscription;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;

  // Get tasks by status
  List<Task> getTasksByStatus(TaskStatus status) {
    return _tasks.where((task) => task.status == status).toList();
  }

  // Initialize provider - Web only
  Future<void> initialize(AppUser? user) async {
    if (user != null) {
      _currentUserId = user.uid;
    }

    // Load tasks after initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadTasks();
    });
  }

  // Load tasks - Web only (always from Firestore)
  Future<void> loadTasks() async {
    if (_currentUserId == null) return;

    _isLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      // Cancel existing subscription if any
      await _tasksSubscription?.cancel();

      // Always load from Firestore for web
      _tasksSubscription = _firestoreService
          .getUserTasks(_currentUserId!)
          .listen(
            (tasks) {
              _tasks = tasks;
              _isLoading = false;
              notifyListeners();
            },
            onError: (error) {
              if (kDebugMode) {
                print('Error loading tasks: $error');
              }
              _isLoading = false;
              notifyListeners();
            },
          );
    } catch (e) {
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  // Add a new task
  Future<bool> addTask(Task task) async {
    try {
      if (_currentUserId == null) return false;

      // Check if task number already exists
      bool exists = await _firestoreService.taskNumberExists(
        _currentUserId!,
        task.taskNumber,
      );

      if (exists) {
        throw Exception(
          'Bu task numarası zaten kullanılıyor: ${task.taskNumber}',
        );
      }

      final newTask = task.copyWith(
        id: _uuid.v4(),
        userId: _currentUserId!,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.createTask(newTask);
      // The task will be added to the list through the stream listener

      notifyListeners();
      return true;
    } catch (e) {
      rethrow;
    }
  }

  // Create a new task (legacy method for compatibility)
  Future<void> createTask({
    required String taskNumber,
    required String title,
    required String description,
    String? assignedToId,
    String? assignedToName,
  }) async {
    if (_currentUserId == null) return;
    try {
      // Check if task number already exists
      bool exists = await _firestoreService.taskNumberExists(
        _currentUserId!,
        taskNumber,
      );

      if (exists) {
        throw Exception('Bu task numarası zaten kullanılıyor: $taskNumber');
      }

      final now = DateTime.now();
      final task = Task(
        id: _uuid.v4(),
        taskNumber: taskNumber,
        title: title,
        description: description,
        status: TaskStatus.todo,
        createdAt: now,
        updatedAt: now,
        userId: _currentUserId!,
        assignedToId: assignedToId,
        assignedToName: assignedToName,
      );

      await _firestoreService.createTask(task);
      // The task will be added to the list through the stream listener

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Update task with Task object
  Future<bool> updateTask(Task task) async {
    try {
      final updates = {
        'taskNumber': task.taskNumber,
        'title': task.title,
        'description': task.description,
        'status': task.status.value,
        'priority': task.priority.value,
        'assignedToId': task.assignedToId,
        'assignedToName': task.assignedToName,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };
      await _firestoreService.updateTask(task.id, updates);

      notifyListeners();
      return true;
    } catch (e) {
      rethrow;
    }
  }

  // Update task status
  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    try {
      await _firestoreService.updateTaskStatus(taskId, status);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Delete task
  Future<void> deleteTask(String taskId) async {
    try {
      await _firestoreService.deleteTask(taskId);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Get task by ID
  Task? getTaskById(String taskId) {
    try {
      return _tasks.firstWhere((task) => task.id == taskId);
    } catch (e) {
      return null;
    }
  }

  // Search tasks
  List<Task> searchTasks(String query) {
    if (query.isEmpty) return _tasks;

    final lowercaseQuery = query.toLowerCase();
    return _tasks.where((task) {
      return task.title.toLowerCase().contains(lowercaseQuery) ||
          task.description.toLowerCase().contains(lowercaseQuery) ||
          task.taskNumber.toLowerCase().contains(lowercaseQuery) ||
          (task.assignedToName?.toLowerCase().contains(lowercaseQuery) ??
              false);
    }).toList();
  }

  // Get tasks assigned to a specific person
  List<Task> getTasksForPerson(String personId) {
    return _tasks.where((task) => task.assignedToId == personId).toList();
  }

  // Get task statistics
  Map<String, int> getTaskStatistics() {
    return {
      'total': _tasks.length,
      'todo': getTasksByStatus(TaskStatus.todo).length,
      'inProgress': getTasksByStatus(TaskStatus.inProgress).length,
      'done': getTasksByStatus(TaskStatus.done).length,
      'blocked': getTasksByStatus(TaskStatus.blocked).length,
    };
  }

  // Sign out and clean up
  Future<void> signOut() async {
    await _tasksSubscription?.cancel();
    _tasksSubscription = null;
    _currentUserId = null;
    _tasks.clear();
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    super.dispose();
  }
}
