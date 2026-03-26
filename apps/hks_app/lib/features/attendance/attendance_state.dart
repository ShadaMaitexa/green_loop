import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:data_models/data_models.dart';
import 'package:core/core.dart';

/// State management for the Attendance module.
class AttendanceState extends ChangeNotifier {
  final AttendanceRepository _repository;

  AttendanceRecord? _today;
  AttendanceRecord? get today => _today;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  // In-progress check-in data
  File? _selfieFile;
  File? get selfieFile => _selfieFile;

  List<PpeItem> _ppeItems = PpeItem.defaultChecklist();
  List<PpeItem> get ppeItems => _ppeItems;

  bool get allPpeChecked => _ppeItems.every((item) => item.isChecked);

  // Monthly history cache: key = "YYYY-MM"
  final Map<String, List<AttendanceRecord>> _historyCache = {};

  AttendanceState({required AttendanceRepository repository})
      : _repository = repository;

  // ─────────────────────────────────────────────────────────────────────────
  // Initialisation
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> fetchTodayAttendance() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _today = await _repository.getTodayAttendance();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Selfie Capture
  // ─────────────────────────────────────────────────────────────────────────

  void setSelfie(File file) {
    _selfieFile = file;
    _error = null;
    notifyListeners();
  }

  void resetSelfie() {
    _selfieFile = null;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PPE Checklist
  // ─────────────────────────────────────────────────────────────────────────

  void togglePpe(String id) {
    final item = _ppeItems.firstWhere((e) => e.id == id);
    item.isChecked = !item.isChecked;
    notifyListeners();
  }

  void resetChecklist() {
    _ppeItems = PpeItem.defaultChecklist();
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Check-In
  // ─────────────────────────────────────────────────────────────────────────

  Future<bool> submitCheckIn() async {
    if (_selfieFile == null || !allPpeChecked) {
      _error = 'Please complete all steps before checking in.';
      notifyListeners();
      return false;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Get GPS
      final position = await _getGps();

      // Simulate selfie upload — replace with real upload in production
      final mockSelfieUrl =
          'https://storage.greenloop.app/attendance/${DateTime.now().millisecondsSinceEpoch}_selfie.jpg';

      _today = await _repository.checkIn(
        selfieUrl: mockSelfieUrl,
        latitude: position.latitude,
        longitude: position.longitude,
        ppeConfirmed: true,
      );

      _selfieFile = null;
      _ppeItems = PpeItem.defaultChecklist();
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Check-Out
  // ─────────────────────────────────────────────────────────────────────────

  Future<bool> submitCheckOut() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _today = await _repository.checkOut();
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Monthly History
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<AttendanceRecord>> fetchMonthHistory(DateTime month) async {
    final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    if (_historyCache.containsKey(key)) return _historyCache[key]!;

    try {
      final records = await _repository.getMonthlyHistory(key);
      _historyCache[key] = records;
      notifyListeners();
      return records;
    } catch (e) {
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GPS Helper
  // ─────────────────────────────────────────────────────────────────────────

  Future<Position> _getGps() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      throw Exception('Location permission is required to check in.');
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }
}
