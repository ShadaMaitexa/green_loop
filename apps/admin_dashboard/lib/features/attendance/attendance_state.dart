import 'package:flutter/foundation.dart';
import 'package:data_models/data_models.dart';
import 'attendance_service.dart';

class AttendanceState extends ChangeNotifier {
  final AttendanceService _service;

  List<AttendanceRecord> _records = [];
  bool _isLoading = false;
  String? _error;

  AttendanceState({required AttendanceService service}) : _service = service;

  List<AttendanceRecord> get records => _records;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAttendance() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _records = await _service.getAttendance();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> markAttendance(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.submitAttendance(data);
      await loadAttendance();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAttendance(String id) async {
    try {
      await _service.deleteAttendance(id);
      await loadAttendance();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
