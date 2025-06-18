import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/person.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';

class PersonProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final Uuid _uuid = const Uuid();

  List<Person> _people = [];
  bool _isLoading = false;
  String? _currentUserId;
  StreamSubscription<List<Person>>? _peopleSubscription;

  List<Person> get people => _people;
  bool get isLoading => _isLoading;

  // Initialize provider - Web only
  Future<void> initialize(AppUser? user) async {
    if (user != null) {
      _currentUserId = user.uid;
    }

    await loadPeople();
  }

  // Load people - Web only (always from Firestore)
  Future<void> loadPeople() async {
    if (_currentUserId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Cancel existing subscription if any
      await _peopleSubscription?.cancel();

      // Always load from Firestore for web
      _peopleSubscription = _firestoreService
          .getUserPeople(_currentUserId!)
          .listen(
            (people) {
              _people = people;
              _isLoading = false;
              notifyListeners();
            },
            onError: (error) {
              if (kDebugMode) {
                print('Error loading people: $error');
              }
              _isLoading = false;
              notifyListeners();
            },
          );
    } catch (e) {
      if (kDebugMode) {
        print('Error loading people: $e');
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new person
  Future<bool> createPerson({
    required String name,
    required String email,
    String? department,
    String? role,
  }) async {
    if (_currentUserId == null) return false;

    try {
      final now = DateTime.now();
      final person = Person(
        id: _uuid.v4(),
        name: name,
        email: email,
        department: department,
        role: role ?? 'Team Member',
        createdAt: now,
        updatedAt: now,
        userId: _currentUserId!,
      );

      await _firestoreService.createPerson(person);
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating person: $e');
      }
      rethrow;
    }
  }

  // Update a person
  Future<bool> updatePerson(Person person) async {
    try {
      final updates = {
        'name': person.name,
        'email': person.email,
        'department': person.department,
        'role': person.role,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };
      await _firestoreService.updatePerson(person.id, updates);
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating person: $e');
      }
      rethrow;
    }
  }

  // Delete a person
  Future<bool> deletePerson(String personId) async {
    try {
      await _firestoreService.deletePerson(personId);
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting person: $e');
      }
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
          (person.role?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  // Get people statistics
  Map<String, int> getPeopleStatistics() {
    final roles = <String, int>{};
    for (final person in _people) {
      final role = person.role ?? 'Unknown';
      roles[role] = (roles[role] ?? 0) + 1;
    }
    return {'total': _people.length, ...roles};
  }

  // Sign out and clean up
  Future<void> signOut() async {
    await _peopleSubscription?.cancel();
    _peopleSubscription = null;
    _currentUserId = null;
    _people.clear();
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _peopleSubscription?.cancel();
    super.dispose();
  }
}
