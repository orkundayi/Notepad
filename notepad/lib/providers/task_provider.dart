import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';

class TaskProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final LocalStorageService _localStorageService = LocalStorageService();
  final Uuid _uuid = const Uuid();

  List<Task> _tasks = [];
  bool _isLoading = false;
  bool _isOfflineMode = false;
  String? _currentUserId;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  bool get isOfflineMode => _isOfflineMode;

  // Get tasks by status
  List<Task> getTasksByStatus(TaskStatus status) {
    return _tasks.where((task) => task.status == status).toList();
  }

  // Initialize provider
  Future<void> initialize(AppUser? user) async {
    if (user != null) {
      _currentUserId = user.uid;
    } else {
      // For offline mode, create a temporary user ID
      _currentUserId = 'offline_user';
    }

    // Web'de her zaman online mode
    if (kIsWeb) {
      _isOfflineMode = false;
    } else {
      _isOfflineMode = await _localStorageService.getOfflineMode();
    }

    // Don't call loadTasks immediately, let the UI request it
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadTasks();
    });
  }

  // Set offline mode
  Future<void> setOfflineMode(bool isOffline) async {
    // Web'de offline mode desteklenmez
    if (kIsWeb) {
      _isOfflineMode = false;
      notifyListeners();
      return;
    }

    _isOfflineMode = isOffline;
    await _localStorageService.setOfflineMode(_isOfflineMode);
    notifyListeners();
  }

  // Toggle offline mode
  Future<void> toggleOfflineMode() async {
    // Web'de offline mode desteklenmez
    if (kIsWeb) {
      return;
    }

    _isOfflineMode = !_isOfflineMode;
    await _localStorageService.setOfflineMode(_isOfflineMode);
    if (_currentUserId != null) {
      if (!kIsWeb && _isOfflineMode) {
        await _localStorageService.saveUserOfflinePreference(_currentUserId!);
        // Load local tasks
        await loadTasks();
      } else {
        // Sync local data to Firestore when going online (only on mobile)
        if (!kIsWeb) {
          await _syncLocalDataToFirestore();
        }
        // Load from Firestore
        await loadTasks();
      }
    }
    notifyListeners();
  }

  // Load tasks based on current mode
  Future<void> loadTasks() async {
    if (_currentUserId == null) return;

    _isLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      if (!kIsWeb && _isOfflineMode) {
        _tasks = await _localStorageService.getLocalTasks(_currentUserId!);
        _isLoading = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      } else {
        // Load from Firestore
        _firestoreService.getUserTasks(_currentUserId!).listen((tasks) {
          _tasks = tasks;
          _isLoading = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            notifyListeners();
          });
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading tasks: $e');
      }
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  // Create a new task
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
      bool exists =
          (!kIsWeb && _isOfflineMode)
              ? await _localStorageService.taskNumberExistsLocally(
                _currentUserId!,
                taskNumber,
              )
              : await _firestoreService.taskNumberExists(
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
      if (!kIsWeb && _isOfflineMode) {
        await _localStorageService.saveTaskLocally(task);
        _tasks.insert(0, task);
      } else {
        await _firestoreService.createTask(task);
        // The task will be added to the list through the stream listener
      }

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Update task
  Future<void> updateTask(
    String taskId, {
    String? title,
    String? description,
    TaskStatus? status,
    String? assignedToId,
    String? assignedToName,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (status != null) updates['status'] = status.value;
      if (assignedToId != null) updates['assignedToId'] = assignedToId;
      if (assignedToName != null) updates['assignedToName'] = assignedToName;

      // Handle assignment removal (when assignedToId is explicitly null)
      if (assignedToId == null && assignedToName == null) {
        updates['assignedToId'] = null;
        updates['assignedToName'] = null;
      }

      if (!kIsWeb && _isOfflineMode) {
        final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
        if (taskIndex != -1) {
          final updatedTask = _tasks[taskIndex].copyWith(
            title: title,
            description: description,
            status: status,
            assignedToId: assignedToId,
            assignedToName: assignedToName,
            updatedAt: DateTime.now(),
          );
          await _localStorageService.updateLocalTask(updatedTask);
          _tasks[taskIndex] = updatedTask;
        }
      } else {
        await _firestoreService.updateTask(taskId, updates);
      }

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Update task status
  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    try {
      if (!kIsWeb && _isOfflineMode) {
        final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
        if (taskIndex != -1) {
          final updatedTask = _tasks[taskIndex].copyWith(
            status: status,
            updatedAt: DateTime.now(),
          );
          await _localStorageService.updateLocalTask(updatedTask);
          _tasks[taskIndex] = updatedTask;
        }
      } else {
        await _firestoreService.updateTaskStatus(taskId, status);
      }

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Delete task
  Future<void> deleteTask(String taskId) async {
    try {
      if (!kIsWeb && _isOfflineMode) {
        await _localStorageService.deleteLocalTask(taskId);
        _tasks.removeWhere((task) => task.id == taskId);
      } else {
        await _firestoreService.deleteTask(taskId);
      }

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Search tasks
  List<Task> searchTasks(String query) {
    if (query.isEmpty) return _tasks;

    final lowercaseQuery = query.toLowerCase();
    return _tasks.where((task) {
      return task.title.toLowerCase().contains(lowercaseQuery) ||
          task.description.toLowerCase().contains(lowercaseQuery) ||
          task.taskNumber.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Sync local data to Firestore
  Future<void> _syncLocalDataToFirestore() async {
    if (_currentUserId == null || kIsWeb) return;

    try {
      final localTasks = await _localStorageService.getPendingSyncTasks(
        _currentUserId!,
      );

      for (final task in localTasks) {
        // Check if task already exists in Firestore
        final existingTask = await _firestoreService.getTaskByNumber(
          _currentUserId!,
          task.taskNumber,
        );

        if (existingTask == null) {
          // Create new task in Firestore
          await _firestoreService.createTask(task);
        } else {
          // Update existing task if local version is newer
          if (task.updatedAt.isAfter(existingTask.updatedAt)) {
            await _firestoreService.updateTask(existingTask.id, {
              'title': task.title,
              'description': task.description,
              'status': task.status.value,
            });
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing local data: $e');
      }
    }
  }

  // Clear all data
  Future<void> clearAllData() async {
    _tasks.clear();
    _currentUserId = null;
    _isOfflineMode = false;

    // Web'de local storage temizleme yapmayız
    if (!kIsWeb) {
      await _localStorageService.clearLocalData();
    }

    notifyListeners();
  }
}
