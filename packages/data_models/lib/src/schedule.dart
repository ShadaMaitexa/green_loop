import 'package:data_models/data_models.dart';

class WardSchedule {
  final int wardId;
  final List<CollectionDay> days;

  const WardSchedule({
    required this.wardId,
    required this.days,
  });

  factory WardSchedule.fromJson(Map<String, dynamic> json) {
    return WardSchedule(
      wardId: json['ward_id'] as int,
      days: (json['days'] as List)
          .map((e) => CollectionDay.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CollectionDay {
  final String dayOfWeek; // Monday, Tuesday...
  final WasteType wasteType;
  final String timeText; // e.g. "08:00 AM - 10:00 AM"
  final String slot; // Morning, Afternoon, Evening

  const CollectionDay({
    required this.dayOfWeek,
    required this.wasteType,
    required this.timeText,
    required this.slot,
  });

  factory CollectionDay.fromJson(Map<String, dynamic> json) {
    return CollectionDay(
      dayOfWeek: json['day_of_week'] as String,
      wasteType: WasteType.fromJson(json['waste_type'] as String),
      timeText: json['time_text'] as String,
      slot: json['slot'] as String,
    );
  }
}
