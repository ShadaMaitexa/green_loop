import 'ward.dart';

enum UserRole {
  resident,
  hksWorker,
  admin,
  recycler;

  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'hks_worker':
        return UserRole.hksWorker;
      case 'admin':
        return UserRole.admin;
      case 'recycler':
        return UserRole.recycler;
      case 'resident':
      default:
        return UserRole.resident;
    }
  }

  String toJson() {
    switch (this) {
      case UserRole.hksWorker:
        return 'hks_worker';
      case UserRole.admin:
        return 'admin';
      case UserRole.recycler:
        return 'recycler';
      case UserRole.resident:
        return 'resident';
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
  final String id;
  final String email;
  final String? phone;
  final String name;
  final UserRole role;
  final bool isActive;
  final Ward? assignedWard; // For HKS workers

  const PlatformUser({
    required this.id,
    required this.email,
    this.phone,
    required this.name,
    required this.role,
    this.isActive = true,
    this.assignedWard,
  });

  factory PlatformUser.fromJson(Map<String, dynamic> json) {
    return PlatformUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      name: json['name']?.toString() ?? json['username']?.toString() ?? 'User',
      role: UserRole.fromString(json['role']?.toString() ?? 'resident'),
      isActive: json['is_active'] as bool? ?? true,
      assignedWard: json['ward'] != null ? Ward.fromJson(json['ward'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'name': name,
      'role': role.toJson(),
      'is_active': isActive,
      if (assignedWard != null) 'ward_id': assignedWard!.id,
    };
  }
}
