import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskStatus {
  todo('Todo', 'Yapılacak'),
  inProgress('In Progress', 'Devam Ediyor'),
  done('Done', 'Tamamlandı'),
  blocked('Blocked', 'Bloke');

  const TaskStatus(this.value, this.displayName);
  final String value;
  final String displayName;

  static TaskStatus fromString(String value) {
    return TaskStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TaskStatus.todo,
    );
  }
}

class Task {
  final String id;
  final String taskNumber;
  final String title;
  final String description;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;
  final String? assignedToId; // ID of the person assigned to this task
  final String? assignedToName; // Name of the person (for quick display)

  Task({
    required this.id,
    required this.taskNumber,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    this.assignedToId,
    this.assignedToName,
  });
  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      taskNumber: data['taskNumber'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: TaskStatus.fromString(data['status'] ?? 'Todo'),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
      assignedToId: data['assignedToId'],
      assignedToName: data['assignedToName'],
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? '',
      taskNumber: json['taskNumber'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: TaskStatus.fromString(json['status'] ?? 'Todo'),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      userId: json['userId'] ?? '',
      assignedToId: json['assignedToId'],
      assignedToName: json['assignedToName'],
    );
  }
  Map<String, dynamic> toFirestore() {
    return {
      'taskNumber': taskNumber,
      'title': title,
      'description': description,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'userId': userId,
      'assignedToId': assignedToId,
      'assignedToName': assignedToName,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskNumber': taskNumber,
      'title': title,
      'description': description,
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'userId': userId,
      'assignedToId': assignedToId,
      'assignedToName': assignedToName,
    };
  }

  Task copyWith({
    String? id,
    String? taskNumber,
    String? title,
    String? description,
    TaskStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    String? assignedToId,
    String? assignedToName,
  }) {
    return Task(
      id: id ?? this.id,
      taskNumber: taskNumber ?? this.taskNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      assignedToId: assignedToId ?? this.assignedToId,
      assignedToName: assignedToName ?? this.assignedToName,
    );
  }
}
