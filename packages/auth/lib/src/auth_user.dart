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
    final role = json['role']?.toString() ?? 'resident';
    final registrationRequired = json['registration_required'] == true;
    
    // Check for explicit completion flag
    bool isCompleted = json['is_profile_completed'] as bool? ?? 
                       json['user']?['is_profile_completed'] as bool? ?? 
                       false;

    // Fallback detection: If the user has a ward, their profile is effectively setup
    final hasWard = json['ward'] != null || 
                   json['ward_id'] != null || 
                   json['user']?['ward'] != null ||
                   json['user']?['ward_id'] != null;

    // Logic: 
    // 1. Admins don't need profile setup screens.
    // 2. If registration was NOT required (already exists) AND they have a ward -> Completed.
    // 3. Otherwise rely on explicit isCompleted flag.
    final bool finalStatus = (role.toLowerCase() == 'admin') || 
                             isCompleted || 
                             (!registrationRequired && hasWard);

    return AuthUser(
      id: json['id']?.toString() ?? json['user']?['id']?.toString() ?? '',
      email: json['email']?.toString() ?? json['user']?['email']?.toString() ?? '',
      username: json['username']?.toString() ?? json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? json['username']?.toString() ?? '',
      role: role,
      isProfileCompleted: finalStatus,
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
