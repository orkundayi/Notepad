class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final DateTime? lastLogin;

  AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.lastLogin,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'],
      lastLogin:
          json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    DateTime? lastLogin,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
