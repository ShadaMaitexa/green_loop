import 'ward.dart';

/// Aligns with GET /api/v1/users/{id}/ response:
/// { id (uuid), email, name, role, ward (int), is_active, created_at, points_balance }

enum UserRole {
  resident,
  hksWorker,
  admin,
  recycler;

  static UserRole fromString(String value) {
    switch (value.toUpperCase()) {
      case 'HKS_WORKER':
      case 'WORKER':
        return UserRole.hksWorker;
      case 'ADMIN':
        return UserRole.admin;
      case 'RECYCLER':
        return UserRole.recycler;
      case 'RESIDENT':
      default:
        return UserRole.resident;
    }
  }

  String toJson() {
    switch (this) {
      case UserRole.hksWorker:
        return 'HKS_WORKER';
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.recycler:
        return 'RECYCLER';
      case UserRole.resident:
        return 'RESIDENT';
    }
  }

  String get label {
    switch (this) {
      case UserRole.hksWorker:
        return 'HKS Worker';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.recycler:
        return 'Recycler';
      case UserRole.resident:
        return 'Resident';
    }
  }
}

class PlatformUser {
  final String id;          // UUID
  final String email;
  final String? phone;
  final String name;
  final UserRole role;
  final bool isActive;
  final int? wardId;        // API returns ward as integer ID
  final String? pointsBalance; // API returns as string e.g. "500.00"
  final DateTime? createdAt;

  /// Compatibility getter for UI components that expect a Ward object.
  /// Note: Only contains ID and a placeholder name 'Ward X'.
  Ward? get assignedWard => wardId != null ? Ward(id: wardId!, name: 'Ward $wardId') : null;

  // Backwards compat — some screens check role as string
  String get roleName => role.toJson();

  const PlatformUser({
    required this.id,
    required this.email,
    this.phone,
    required this.name,
    required this.role,
    this.isActive = true,
    this.wardId,
    this.pointsBalance,
    this.createdAt,
  });

  factory PlatformUser.fromJson(Map<String, dynamic> json) {
    return PlatformUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      name: json['name']?.toString() ?? json['username']?.toString() ?? 'User',
      role: UserRole.fromString(json['role']?.toString() ?? 'RESIDENT'),
      isActive: json['is_active'] as bool? ?? true,
      // API returns ward as int when present
      wardId: json['ward'] is int ? json['ward'] as int : int.tryParse(json['ward']?.toString() ?? ''),
      pointsBalance: json['points_balance']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      if (phone != null) 'phone': phone,
      'name': name,
      'role': role.toJson(),
      'is_active': isActive,
      if (wardId != null) 'ward': wardId,
    };
  }
}
