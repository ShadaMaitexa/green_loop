/// A basic representation of the authenticated user's core identity.
/// This model isolates the Auth package from the main application User models.
class AuthUser {
  final String id;
  final String email;
  final String username;
  final String name;
  final String role;
  final bool isProfileCompleted;

  const AuthUser({
    required this.id,
    required this.email,
    required this.username,
    required this.name,
    required this.role,
    this.isProfileCompleted = false,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ?? json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? json['username']?.toString() ?? json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'resident',
      isProfileCompleted: json['is_profile_completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'name': name,
      'role': role,
      'is_profile_completed': isProfileCompleted,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          username == other.username &&
          name == other.name &&
          role == other.role;

  @override
  int get hashCode => id.hashCode ^ email.hashCode ^ username.hashCode ^ name.hashCode ^ role.hashCode;
}
