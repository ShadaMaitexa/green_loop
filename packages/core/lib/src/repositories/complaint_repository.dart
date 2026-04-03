import 'dart:io';
import 'package:dio/dio.dart';
import 'package:network/network.dart';
import 'package:data_models/data_models.dart';

class ComplaintRepository {
  final ApiClient _apiClient;

  static const String _complaintsPath = '/api/v1/complaints/';

  ComplaintRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetches a list of complaints for the current user.
  /// API returns a GeoJSON FeatureCollection.
  Future<List<ComplaintModel>> getComplaints() async {
    try {
      final response = await _apiClient.get(_complaintsPath);
      final data = response.data;

      // GeoJSON FeatureCollection: { type: "FeatureCollection", features: [...] }
      if (data is Map && data['type'] == 'FeatureCollection') {
        final features = data['features'] as List? ?? [];
        return features
            .map((e) => ComplaintModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Fallback: flat list
      if (data is List) {
        return data
            .map((e) => ComplaintModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      return [];
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Fetches details for a single complaint.
  /// API returns a GeoJSON Feature.
  Future<ComplaintModel> getComplaintDetails(String id) async {
    try {
      final response = await _apiClient.get('$_complaintsPath$id/');
      return ComplaintModel.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Advances a complaint to the next status (HKS Worker action).
  Future<ComplaintModel> advanceStatus(String id) async {
    try {
      final response = await _apiClient.post(
        '$_complaintsPath$id/advance_status/',
        data: {},
      );
      return ComplaintModel.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Assigns a complaint to a worker (Admin action).
  Future<ComplaintModel> assignComplaint(String id, String workerId) async {
    try {
      final response = await _apiClient.post(
        '$_complaintsPath$id/assign/',
        data: {
          'type': 'Feature',
          'geometry': null,
          'properties': {'assigned_to': workerId},
        },
      );
      return ComplaintModel.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Handles complaint creation with optional image attachment.
  /// Sends as multipart/form-data so the image is submitted inline with the complaint.
  Future<ComplaintModel> submitComplaint({
    required ComplaintRequest request,
    File? imageFile,
  }) async {
    try {
      final Map<String, dynamic> fields = {
        'category': request.type,
        'description': request.description,
        // Django REST Framework GIS field accepts JSON string for location
        'location': '{"type":"Point","coordinates":[${request.longitude},${request.latitude}]}',
      };

      dynamic postData;

      if (imageFile != null) {
        // Use multipart form if image is attached
        final multipartFile = await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split(RegExp(r'[/\\]')).last,
        );
        postData = FormData.fromMap({
          ...fields,
          'image': multipartFile,
        });
      } else {
        // Plain JSON if no image
        postData = fields;
      }

      final response = await _apiClient.post(_complaintsPath, data: postData);
      return ComplaintModel.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Rate a resolved complaint.
  Future<void> rateComplaint(String id, int rating) async {
    try {
      await _apiClient.post(
        '$_complaintsPath$id/rate/',
        data: {'rating': rating},
      );
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Update an existing complaint.
  Future<ComplaintModel> updateComplaint(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.patch('$_complaintsPath$id/', data: data);
      return ComplaintModel.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Replace an existing complaint.
  Future<ComplaintModel> replaceComplaint(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put('$_complaintsPath$id/', data: data);
      return ComplaintModel.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Delete a complaint.
  Future<void> deleteComplaint(String id) async {
    try {
      await _apiClient.delete('$_complaintsPath$id/');
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Fetch complaint heatmap for admins.
  Future<List<Map<String, dynamic>>> getHeatmap() async {
    try {
      final res = await _apiClient.get('/api/v1/complaints/heatmap/');
      if (res.data is Map && res.data['type'] == 'FeatureCollection') {
        final features = res.data['features'] as List? ?? [];
        return features.map((e) => e as Map<String, dynamic>).toList();
      }
      return (res.data as List).map((e) => e as Map<String, dynamic>).toList();
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }
}
