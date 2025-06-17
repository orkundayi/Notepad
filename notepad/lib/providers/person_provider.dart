import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/person.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';

class PersonProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final LocalStorageService _localStorageService = LocalStorageService();
  final Uuid _uuid = const Uuid();

  List<Person> _people = [];
  bool _isLoading = false;
  bool _isOfflineMode = false;
  String? _currentUserId;

  List<Person> get people => _people;
  bool get isLoading => _isLoading;
  bool get isOfflineMode => _isOfflineMode;

  // Initialize provider
  Future<void> initialize(AppUser? user, bool isOfflineMode) async {
    if (user != null) {
      _currentUserId = user.uid;
    } else {
      _currentUserId = 'offline_user';
    }

    // Web'de her zaman online mode
    if (kIsWeb) {
      _isOfflineMode = false;
    } else {
      _isOfflineMode = isOfflineMode;
    }

    await loadPeople();
  }

  // Load people based on current mode
  Future<void> loadPeople() async {
    if (_currentUserId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      if (!kIsWeb && _isOfflineMode) {
        _people = await _localStorageService.getLocalPeople(_currentUserId!);
      } else {
        // Load from Firestore
        _firestoreService.getUserPeople(_currentUserId!).listen((people) {
          _people = people;
          notifyListeners();
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading people: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new person
  Future<void> createPerson({
    required String name,
    required String email,
    String? department,
    String? role,
  }) async {
    if (_currentUserId == null) return;

    try {
      final now = DateTime.now();
      final person = Person(
        id: _uuid.v4(),
        name: name,
        email: email,
        department: department,
        role: role,
        createdAt: now,
        updatedAt: now,
        userId: _currentUserId!,
      );

      if (!kIsWeb && _isOfflineMode) {
        await _localStorageService.savePersonLocally(person);
        _people.insert(0, person);
      } else {
        await _firestoreService.createPerson(person);
        // Firestore stream will automatically update the list
      }

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Update person
  Future<void> updatePerson(
    String personId, {
    String? name,
    String? email,
    String? department,
    String? role,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (email != null) updates['email'] = email;
      if (department != null) updates['department'] = department;
      if (role != null) updates['role'] = role;

      if (!kIsWeb && _isOfflineMode) {
        final personIndex = _people.indexWhere(
          (person) => person.id == personId,
        );
        if (personIndex != -1) {
          final updatedPerson = _people[personIndex].copyWith(
            name: name,
            email: email,
            department: department,
            role: role,
            updatedAt: DateTime.now(),
          );
          await _localStorageService.updateLocalPerson(updatedPerson);
          _people[personIndex] = updatedPerson;
        }
      } else {
        await _firestoreService.updatePerson(personId, updates);
      }

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Delete person
  Future<void> deletePerson(String personId) async {
    try {
      if (!kIsWeb && _isOfflineMode) {
        await _localStorageService.deleteLocalPerson(personId);
        _people.removeWhere((person) => person.id == personId);
      } else {
        await _firestoreService.deletePerson(personId);
      }

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Get person by ID
  Person? getPersonById(String personId) {
    try {
      return _people.firstWhere((person) => person.id == personId);
    } catch (e) {
      return null;
    }
  }

  // Search people
  List<Person> searchPeople(String query) {
    if (query.isEmpty) return _people;

    final lowercaseQuery = query.toLowerCase();
    return _people.where((person) {
      return person.name.toLowerCase().contains(lowercaseQuery) ||
          person.email.toLowerCase().contains(lowercaseQuery) ||
          (person.department?.toLowerCase().contains(lowercaseQuery) ??
              false) ||
          (person.role?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  // Clear all data
  Future<void> clearAllData() async {
    _people.clear();
    _currentUserId = null;
    _isOfflineMode = false;
    if (!kIsWeb) {
      await _localStorageService.clearLocalPeople();
    }
    notifyListeners();
  }
}
