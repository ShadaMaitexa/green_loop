/// Detailed profile for a Resident, including name and location-based ward.
class ResidentProfile {
  final String? id;
  final String userId;
  final String nameEn;
  final String nameMl;
  final int wardId;
  final String address;
  final double latitude;
  final double longitude;
  final bool isVerified;

  const ResidentProfile({
    this.id,
    required this.userId,
    required this.nameEn,
    required this.nameMl,
    required this.wardId,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.isVerified = false,
  });

  factory ResidentProfile.fromJson(Map<String, dynamic> json) {
    return ResidentProfile(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString() ?? '',
      nameEn: json['name_en'] as String,
      nameMl: json['name_ml'] as String,
      wardId: json['ward_id'] as int,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isVerified: json['is_verified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name_en': nameEn,
      'name_ml': nameMl,
      'ward_id': wardId,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
