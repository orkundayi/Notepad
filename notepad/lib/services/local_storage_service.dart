import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';
import '../models/person.dart';

class LocalStorageService {
  static Database? _database;
  static const String _offlineModeKey = 'offline_mode';

  // Initialize database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'tasks.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks(
        id TEXT PRIMARY KEY,
        taskNumber TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        status TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        userId TEXT NOT NULL,
        assignedToId TEXT,
        assignedToName TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE people(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        department TEXT,
        role TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        userId TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns to tasks table
      await db.execute('ALTER TABLE tasks ADD COLUMN assignedToId TEXT');
      await db.execute('ALTER TABLE tasks ADD COLUMN assignedToName TEXT');

      // Create people table
      await db.execute('''
        CREATE TABLE people(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          email TEXT NOT NULL,
          department TEXT,
          role TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          userId TEXT NOT NULL
        )
      ''');
    }
  }

  // Save task locally
  Future<void> saveTaskLocally(Task task) async {
    final db = await database;
    await db.insert(
      'tasks',
      task.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all local tasks for user
  Future<List<Task>> getLocalTasks(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'updatedAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Task.fromJson(maps[i]);
    });
  }

  // Get local tasks by status
  Future<List<Task>> getLocalTasksByStatus(
    String userId,
    TaskStatus status,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'userId = ? AND status = ?',
      whereArgs: [userId, status.value],
      orderBy: 'updatedAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Task.fromJson(maps[i]);
    });
  }

  // Update local task
  Future<void> updateLocalTask(Task task) async {
    final db = await database;
    await db.update(
      'tasks',
      task.toJson(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  // Delete local task
  Future<void> deleteLocalTask(String taskId) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [taskId]);
  }

  // Check if task number exists locally
  Future<bool> taskNumberExistsLocally(String userId, String taskNumber) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'userId = ? AND taskNumber = ?',
      whereArgs: [userId, taskNumber],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  // Get task by number locally
  Future<Task?> getLocalTaskByNumber(String userId, String taskNumber) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'userId = ? AND taskNumber = ?',
      whereArgs: [userId, taskNumber],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Task.fromJson(maps.first);
    }
    return null;
  }

  // Offline mode preferences
  Future<void> setOfflineMode(bool isOffline) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_offlineModeKey, isOffline);
  }

  Future<bool> getOfflineMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_offlineModeKey) ?? false;
  }

  // Save user preference for offline mode
  Future<void> saveUserOfflinePreference(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_offline_user', userId);
  }

  Future<String?> getCurrentOfflineUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_offline_user');
  }

  // Clear all local data
  Future<void> clearLocalData() async {
    final db = await database;
    await db.delete('tasks');
    await db.delete('people');

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_offlineModeKey);
    await prefs.remove('current_offline_user');
  }

  // Sync local data with Firestore (for when going back online)
  Future<List<Task>> getPendingSyncTasks(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    return List.generate(maps.length, (i) {
      return Task.fromJson(maps[i]);
    });
  }

  // =============== PEOPLE METHODS ===============

  // Save person locally
  Future<void> savePersonLocally(Person person) async {
    final db = await database;
    await db.insert(
      'people',
      person.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all local people for user
  Future<List<Person>> getLocalPeople(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'people',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      return Person.fromMap(maps[i]);
    });
  }

  // Update local person
  Future<void> updateLocalPerson(Person person) async {
    final db = await database;
    await db.update(
      'people',
      person.toMap(),
      where: 'id = ?',
      whereArgs: [person.id],
    );
  }

  // Delete local person
  Future<void> deleteLocalPerson(String personId) async {
    final db = await database;
    await db.delete('people', where: 'id = ?', whereArgs: [personId]);
  }

  // Clear local people
  Future<void> clearLocalPeople() async {
    final db = await database;
    await db.delete('people');
  }
}
