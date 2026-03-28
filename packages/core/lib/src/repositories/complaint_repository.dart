import 'dart:io';
import 'package:dio/dio.dart';
import 'package:network/network.dart';
import 'package:data_models/data_models.dart';

class ComplaintRepository {
  final ApiClient _apiClient;
  final Dio _uploadDio;

  static const String _complaintsPath = '/api/v1/complaints/';
  static const String _presignedUrlPath = '/api/v1/complaints/presigned-url/';

  ComplaintRepository({required ApiClient apiClient})
      : _apiClient = apiClient,
        _uploadDio = Dio();

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

  /// Handles the multi-step image upload and complaint creation.
  /// Sends as GeoJSON Feature to match POST /api/v1/complaints/ schema.
  Future<ComplaintModel> submitComplaint({
    required ComplaintRequest request,
    File? imageFile,
  }) async {
    String? finalImageUrl;

    if (imageFile != null) {
      finalImageUrl = await _uploadImageToS3(imageFile);
    }

    try {
      final payload = request.toJson();
      if (finalImageUrl != null) {
        (payload['properties'] as Map<String, dynamic>)['image'] = finalImageUrl;
      }

      final response = await _apiClient.post(_complaintsPath, data: payload);
      return ComplaintModel.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Helper to get pre-signed URL and PUT the file to S3.
  Future<String> _uploadImageToS3(File file) async {
    try {
      final fileName = file.path.split('/').last;
      final response = await _apiClient.get(
        _presignedUrlPath,
        queryParameters: {'file_name': fileName},
      );

      final uploadUrl = response.data['upload_url'] as String;
      final downloadUrl = response.data['download_url'] as String;

      final fileBytes = await file.readAsBytes();
      await _uploadDio.put(
        uploadUrl,
        data: Stream.fromIterable([fileBytes]),
        options: Options(
          headers: {
            Headers.contentLengthHeader: fileBytes.length,
            'Content-Type': 'image/jpeg',
          },
        ),
      );

      return downloadUrl;
    } on ApiException catch (e) {
      throw Exception('Failed to get upload URL: ${e.message}');
    } catch (e) {
      throw Exception('S3 Upload failed: $e');
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
}
