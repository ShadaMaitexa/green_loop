class RouteModel {
  final String id;
  final String status;
  final String? date;
  final WorkerInfo? hksWorker;

  RouteModel({
    required this.id,
    required this.status,
    this.date,
    this.hksWorker,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      date: json['route_date']?.toString(),
      hksWorker: json['hks_worker'] != null 
          ? WorkerInfo.fromJson(json['hks_worker'] as Map<String, dynamic>) 
          : null,
    );
  }
}

class WorkerInfo {
  final String id;
  final String name;

  WorkerInfo({required this.id, required this.name});

  factory WorkerInfo.fromJson(Map<String, dynamic> json) {
    return WorkerInfo(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
    );
  }
}
