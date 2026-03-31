import 'package:flutter/foundation.dart';

@immutable
class NPSSurveySubmit {
  final int score;
  final String? comment;

  const NPSSurveySubmit({
    required this.score,
    this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      if (comment != null) 'comment': comment,
    };
  }
}

class NPSSummary {
  final int totalResponses;
  final double npsScore;
  final int promoters;
  final int passives;
  final int detractors;
  final double averageScore;
  final List<Map<String, dynamic>> recentComments;

  const NPSSummary({
    required this.totalResponses,
    required this.npsScore,
    required this.promoters,
    required this.passives,
    required this.detractors,
    required this.averageScore,
    required this.recentComments,
  });

  factory NPSSummary.fromJson(Map<String, dynamic> json) {
    return NPSSummary(
      totalResponses: json['total_responses'] as int? ?? 0,
      npsScore: (json['nps_score'] as num?)?.toDouble() ?? 0.0,
      promoters: json['promoters'] as int? ?? 0,
      passives: json['passives'] as int? ?? 0,
      detractors: json['detractors'] as int? ?? 0,
      averageScore: (json['average_score'] as num?)?.toDouble() ?? 0.0,
      recentComments: (json['recent_comments'] as List?)?.cast<Map<String, dynamic>>() ?? [],
    );
  }
}
