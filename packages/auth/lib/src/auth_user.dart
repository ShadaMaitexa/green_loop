/// A basic representation of the authenticated user's core identity.
/// This model isolates the Auth package from the main application User models.
class AuthUser {
  final String id;
  final String email;
  final String username;
  final String name;
  final String role;
  final bool isProfileCompleted;
  
  // Profile specific fields
  final String? nameEn;
  final String? nameMl;
  final int? wardId;
  final String? address;
  final double? latitude;
  final double? longitude;
  final int? pointsBalance;

  const AuthUser({
    required this.id,
    required this.email,
    required this.username,
    required this.name,
    required this.role,
    this.isProfileCompleted = false,
    this.nameEn,
    this.nameMl,
    this.wardId,
    this.address,
    this.latitude,
    this.longitude,
    this.pointsBalance,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final role = json['role']?.toString() ?? 
                 json['user']?['role']?.toString() ?? 
                 'resident';
    
    // Extract profile details using a fallback hierarchy
    // Priority: 
    // 1. Root level (per updated documentation)
    // 2. 'profile' key
    // 3. 'resident_profile' key
    final root = json;
    final prefProfile = json['profile'] as Map<String, dynamic>? ?? 
                         json['resident_profile'] as Map<String, dynamic>? ?? 
                         {};

    // Ward handling: prioritize root 'ward' or 'ward_id' (Legacy)
    int? extractedWardId;
    final rawWard = root['ward'] ?? root['ward_id'] ?? prefProfile['ward_id'] ?? prefProfile['ward'];
    if (rawWard is int) {
      extractedWardId = rawWard;
    } else if (rawWard is Map) {
      extractedWardId = rawWard['id'] as int?;
    } else if (rawWard is String) {
      extractedWardId = int.tryParse(rawWard);
    }

    // Check for explicit completion flag
    bool isCompleted = root['is_profile_completed'] as bool? ?? 
                       prefProfile['is_profile_completed'] as bool? ??
                       root['user']?['is_profile_completed'] as bool? ??
                       false;

    // Fallback detection: If the user has a ward, their profile is effectively setup
    final hasWard = extractedWardId != null;

    final bool finalStatus = (role.toLowerCase() == 'admin') || 
                             isCompleted || 
                             hasWard;

    return AuthUser(
      id: root['id']?.toString() ?? root['user']?['id']?.toString() ?? '',
      email: root['email']?.toString() ?? root['user']?['email']?.toString() ?? '',
      username: root['username']?.toString() ?? root['email']?.toString() ?? '',
      name: root['name']?.toString() ?? root['username']?.toString() ?? '',
      role: role,
      isProfileCompleted: finalStatus,
      nameEn: root['name_en']?.toString() ?? prefProfile['name_en']?.toString(),
      nameMl: root['name_ml']?.toString() ?? prefProfile['name_ml']?.toString(),
      wardId: extractedWardId,
      address: root['address']?.toString() ?? prefProfile['address']?.toString(),
      latitude: (root['latitude'] as num?)?.toDouble() ?? (prefProfile['latitude'] as num?)?.toDouble(),
      longitude: (root['longitude'] as num?)?.toDouble() ?? (prefProfile['longitude'] as num?)?.toDouble(),
      pointsBalance: int.tryParse(root['points_balance']?.toString() ?? '') ?? 
                    int.tryParse(prefProfile['points_balance']?.toString() ?? '') ??
                    (root['points_balance'] is int ? root['points_balance'] as int : null) ??
                    (prefProfile['points_balance'] is int ? prefProfile['points_balance'] as int : null),
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
      'name_en': nameEn,
      'name_ml': nameMl,
      'ward_id': wardId,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'points_balance': pointsBalance,
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
          role == other.role &&
          isProfileCompleted == other.isProfileCompleted &&
          nameEn == other.nameEn &&
          nameMl == other.nameMl &&
          wardId == other.wardId &&
          address == other.address &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          pointsBalance == other.pointsBalance;

  @override
  int get hashCode => 
      id.hashCode ^ 
      email.hashCode ^ 
      username.hashCode ^ 
      name.hashCode ^ 
      role.hashCode ^ 
      isProfileCompleted.hashCode ^
      nameEn.hashCode ^
      nameMl.hashCode ^
      wardId.hashCode ^
      address.hashCode ^
      latitude.hashCode ^
      longitude.hashCode ^
      pointsBalance.hashCode;
}
