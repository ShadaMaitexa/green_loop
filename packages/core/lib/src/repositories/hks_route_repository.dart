import 'package:network/network.dart';
import 'package:data_models/data_models.dart';

/// Repository for handling HKS worker-specific route and attendance data.
class HksRouteRepository {
  final ApiClient _apiClient;

  static const String _todayRoutePath = '/api/v1/hks/routes/today/';
  static const String _attendancePath = '/api/v1/hks/attendance/';

  HksRouteRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetches the assigned route for the logged-in worker for today.
  Future<HksRoute> getTodayRoute() async {
    try {
      final response = await _apiClient.get(_todayRoutePath);
      return HksRoute.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw Exception('No route assigned for today');
      }
      throw Exception(e.message);
    }
  }

  /// Logs attendance with GPS validation and PPE proof.
  /// Backend expects GeoJSON Feature.
  Future<void> logAttendance({
    required double latitude,
    required double longitude,
    required String ppePhotoUrl,
  }) async {
    try {
      await _apiClient.post(_attendancePath, data: {
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [longitude, latitude], // GeoJSON [lng, lat]
        },
        'properties': {
          'date': DateTime.now().toIso8601String().split('T')[0],
          'ppe_photo_url': ppePhotoUrl,
          'has_gloves': true,
          'has_mask': true,
          'has_vest': true,
          'has_boots': true,
          'status': 'PRESENT',
        },
      });
    } on ApiException catch (e) {
      // Re-throw if validation failed (ST_Within check on backend)
      throw Exception(e.message);
    }
  }

  /// Validates a scanned QR code with backend logic.
  Future<void> validateQr({
    required String pickupId,
    required String qrToken,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _apiClient.post('/api/v1/hks/pickups/$pickupId/validate-qr/', data: {
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [longitude, latitude],
        },
        'properties': {
          'qr_token': qrToken,
        },
      });
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Submits the completed pickup data to the backend.
  Future<void> completePickup({
    required String pickupId,
    required String qrToken,
    required String photoUrl,
    required String classification,
    required double confidence,
    double? weight,
    required double latitude,
    required double longitude,
    String? overrideNote,
  }) async {
    try {
      await _apiClient.post('/api/v1/hks/pickups/$pickupId/complete/', data: {
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [longitude, latitude],
        },
        'properties': {
          'qr_token': qrToken,
          'photo_url': photoUrl,
          'classification': classification,
          'confidence_score': confidence,
          'weight': weight?.toString(), // Decimal string
          'override_note': overrideNote,
        },
      });
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Submits fee collection info and returns the updated/created FeeCollection.
  Future<FeeCollection> collectFee({
    required String pickupId,
    required double amount,
    required PaymentMode paymentMode,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/hks/fee/',
        data: {
          'type': 'Feature',
          'geometry': null,
          'properties': {
            'pickup_id': pickupId,
            'amount': amount.toString(),
            'payment_method': paymentMode == PaymentMode.upi ? 'UPI' : 'CASH',
            'payment_date': DateTime.now().toIso8601String().split('T')[0],
          },
        },
      );
      return FeeCollection.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Retrieves the daily fee collection summary for the current worker.
  Future<DailyFeeSummary> getFeeSummary() async {
    try {
      final response = await _apiClient.get('/api/v1/hks/fee/summary/today/');
      return DailyFeeSummary.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }
}
