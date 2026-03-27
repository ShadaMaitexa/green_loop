/// Model representing a redeemable reward in the GreenLeaf system.
class Reward {
  final String id;
  final String name;
  final String description;
  final int pointCost;
  final String? imageUrl;
  final bool isAvailable;

  const Reward({
    required this.id,
    required this.name,
    required this.description,
    required this.pointCost,
    this.imageUrl,
    this.isAvailable = true,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'].toString(),
      name: json['name'] as String,
      description: json['description'] as String,
      pointCost: json['point_cost'] as int,
      imageUrl: json['image_url'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'point_cost': pointCost,
      'image_url': imageUrl,
      'is_available': isAvailable,
    };
  }
}
