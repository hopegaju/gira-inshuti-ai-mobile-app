enum UserRole { user, counselor, admin }

class User {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final DateTime createdAt;
  final bool isActive;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
    this.isActive = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${json['role']}',
        orElse: () => UserRole.user,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  String get roleDisplayName {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.counselor:
        return 'Counselor';
      case UserRole.user:
        return 'User';
    }
  }
}