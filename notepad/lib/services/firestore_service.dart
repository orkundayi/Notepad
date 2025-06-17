import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../models/person.dart';

class FirestoreService {
  late FirebaseFirestore _db;

  FirestoreService() {
    // Firebase artık tüm platformlarda destekleniyor
    _db = FirebaseFirestore.instance;
  }
  // Tasks collection reference
  CollectionReference get _tasksRef {
    return _db.collection('tasks');
  }

  // Create a new task
  Future<String> createTask(Task task) async {
    try {
      DocumentReference docRef = await _tasksRef.add(task.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Task oluşturulurken hata: ${e.toString()}');
    }
  }

  // Get all tasks for a user
  Stream<List<Task>> getUserTasks(String userId) {
    return _tasksRef
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList(),
        );
  }

  // Get tasks by status for a user
  Stream<List<Task>> getUserTasksByStatus(String userId, TaskStatus status) {
    return _tasksRef
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: status.value)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList(),
        );
  }

  // Update a task
  Future<void> updateTask(String taskId, Map<String, dynamic> data) async {
    try {
      await _tasksRef.doc(taskId).update({
        ...data,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Task güncellenirken hata: ${e.toString()}');
    }
  }

  // Update task status
  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    try {
      await _tasksRef.doc(taskId).update({
        'status': status.value,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Task durumu güncellenirken hata: ${e.toString()}');
    }
  }

  // Delete a task
  Future<void> deleteTask(String taskId) async {
    try {
      await _tasksRef.doc(taskId).delete();
    } catch (e) {
      throw Exception('Task silinirken hata: ${e.toString()}');
    }
  }

  // Check if task number exists for user
  Future<bool> taskNumberExists(String userId, String taskNumber) async {
    try {
      QuerySnapshot query =
          await _tasksRef
              .where('userId', isEqualTo: userId)
              .where('taskNumber', isEqualTo: taskNumber)
              .limit(1)
              .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Task numarası kontrol edilirken hata: ${e.toString()}');
    }
  }

  // Get task by task number
  Future<Task?> getTaskByNumber(String userId, String taskNumber) async {
    try {
      QuerySnapshot query =
          await _tasksRef
              .where('userId', isEqualTo: userId)
              .where('taskNumber', isEqualTo: taskNumber)
              .limit(1)
              .get();

      if (query.docs.isNotEmpty) {
        return Task.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Task aranırken hata: ${e.toString()}');
    }
  }

  // Users collection reference
  CollectionReference get _usersRef {
    return _db.collection('users');
  }

  // Create user profile in Firestore
  Future<void> createUserProfile(AppUser user) async {
    try {
      final now = DateTime.now();
      if (kDebugMode) {
        print('Firestore\'a kullanıcı profili kaydediliyor: ${user.uid}');
      }
      if (kDebugMode) {
        print('Email: ${user.email}');
      }

      await _usersRef.doc(user.uid).set({
        'email': user.email,
        'displayName': user.displayName,
        'createdAt': now.toIso8601String(),
        'lastLogin': now.toIso8601String(),
      });

      if (kDebugMode) {
        print('Firestore kullanıcı profili başarıyla kaydedildi');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Firestore kullanıcı profili hatası: $e');
      }
      throw Exception('Kullanıcı profili oluşturulurken hata: ${e.toString()}');
    }
  }

  // Update user last login
  Future<void> updateUserLastLogin(String userId) async {
    try {
      await _usersRef.doc(userId).update({
        'lastLogin': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Son giriş güncellenirken hata: ${e.toString()}');
    }
  }

  // People collection reference
  CollectionReference get _peopleRef {
    return _db.collection('people');
  }

  // Create a new person
  Future<String> createPerson(Person person) async {
    try {
      DocumentReference docRef = await _peopleRef.add(person.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Kişi oluşturulurken hata: ${e.toString()}');
    }
  }

  // Get all people for a user
  Stream<List<Person>> getUserPeople(String userId) {
    return _peopleRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Person.fromFirestore(doc)).toList(),
        );
  }

  // Update a person
  Future<void> updatePerson(String personId, Map<String, dynamic> data) async {
    try {
      await _peopleRef.doc(personId).update({
        ...data,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Kişi güncellenirken hata: ${e.toString()}');
    }
  }

  // Delete a person
  Future<void> deletePerson(String personId) async {
    try {
      await _peopleRef.doc(personId).delete();
    } catch (e) {
      throw Exception('Kişi silinirken hata: ${e.toString()}');
    }
  }
}
