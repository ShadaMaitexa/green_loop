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
  Future<void> logAttendance({
    required double latitude,
    required double longitude,
    required String ppePhotoUrl,
  }) async {
    try {
      await _apiClient.post(_attendancePath, data: {
        'latitude': latitude,
        'longitude': longitude,
        'ppe_photo_url': ppePhotoUrl,
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
        'qr_token': qrToken,
        'latitude': latitude,
        'longitude': longitude,
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
        'qr_token': qrToken,
        'photo_url': photoUrl,
        'classification': classification,
        'confidence_score': confidence,
        'weight': weight,
        'latitude': latitude,
        'longitude': longitude,
        'override_note': overrideNote,
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
          'pickup_id': pickupId,
          'amount': amount,
          'payment_mode': paymentMode == PaymentMode.upi ? 'upi' : 'cash',
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
