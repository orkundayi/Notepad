import 'package:cloud_firestore/cloud_firestore.dart';

class Person {
  final String id;
  final String name;
  final String email;
  final String? department;
  final String? role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId; // Who created this person (for data isolation)

  Person({
    required this.id,
    required this.name,
    required this.email,
    this.department,
    this.role,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
  });

  // Convert to Map for local storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'department': department,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'userId': userId,
    };
  }

  // Convert from Map for local storage
  factory Person.fromMap(Map<String, dynamic> map) {
    return Person(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      department: map['department'],
      role: map['role'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      userId: map['userId'] ?? '',
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'department': department,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'userId': userId,
    };
  }

  // Convert from Firestore document
  factory Person.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Person(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      department: data['department'],
      role: data['role'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
    );
  }

  // Copy with method for updates
  Person copyWith({
    String? id,
    String? name,
    String? email,
    String? department,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      department: department ?? this.department,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
    );
  }

  @override
  String toString() {
    return 'Person(id: $id, name: $name, email: $email, department: $department, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Person && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
