import 'user_role.dart';

/// Represents an authenticated user identity in LINGUA AI.
class AuthUser {
  final String id;
  final String email;
  final UserRole role;
  final String status;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  const AuthUser({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
    this.createdAt,
    this.lastLoginAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: UserRoleExtension.fromName(json['role'] as String? ?? 'learner'),
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      lastLoginAt: json['last_login_at'] != null ? DateTime.tryParse(json['last_login_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'role': role.name,
        'status': status,
        'created_at': createdAt?.toIso8601String(),
        'last_login_at': lastLoginAt?.toIso8601String(),
      };
}
