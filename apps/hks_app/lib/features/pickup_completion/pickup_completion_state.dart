import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:core/core.dart';
import 'package:network/network.dart';
import 'package:data_models/data_models.dart';
import 'services/ai_classification_service.dart';
import '../sync/sync_manager.dart';

/// State management for the Pickup Completion Flow.
class PickupCompletionState extends ChangeNotifier {
  final HksRouteRepository _repository;
  final AiClassificationService _aiService;
  final SyncManager _syncManager;
  final HksPickup pickup;

  PickupCompletionState({
    required HksRouteRepository repository,
    required AiClassificationService aiService,
    required SyncManager syncManager,
    required this.pickup,
  }) : _repository = repository, _aiService = aiService, _syncManager = syncManager;

  int _currentStep = 0;
  int get currentStep => _currentStep;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  // Flow Data
  String? _qrToken;
  File? _wastePhoto;
  ClassificationResult? _classification;
  double? _weight;
  Position? _lastValidatedPosition;
  String? _overrideNote;

  String? get qrToken => _qrToken;
  File? get wastePhoto => _wastePhoto;
  ClassificationResult? get classification => _classification;
  double? get weight => _weight;
  String? get overrideNote => _overrideNote;

  bool get isWithinDistance {
    if (_lastValidatedPosition == null) return true; // Default to true until checked
    final distance = Geolocator.distanceBetween(
      _lastValidatedPosition!.latitude,
      _lastValidatedPosition!.longitude,
      pickup.latitude,
      pickup.longitude,
    );
    return distance <= 100.0;
  }

  void nextStep() {
    _currentStep++;
    notifyListeners();
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  /// Validates QR code and GPS distance.
  Future<bool> validateQr(String qrToken) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final position = await Geolocator.getCurrentPosition();
      _lastValidatedPosition = position;
      
      if (_syncManager.status == SyncStatus.offline) {
        // Mock validation for offline mode
        _qrToken = qrToken;
        _lastValidatedPosition = await Geolocator.getCurrentPosition();
        _loading = false;
        notifyListeners();
        return true;
      }

      await _repository.validateQr(
        pickupId: pickup.id,
        qrToken: qrToken,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      _qrToken = qrToken;
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

  /// Sets the waste photo and triggers AI analysis.
  Future<void> setWastePhoto(File photo) async {
    _wastePhoto = photo;
    _loading = true;
    notifyListeners();

    try {
      _classification = await _aiService.classifyWaste(photo);
      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = 'AI Analysis failed: $e';
      _loading = false;
      notifyListeners();
    }
  }

  void setWeight(double? value) {
    _weight = value;
    notifyListeners();
  }

  void setOverrideNote(String note) {
    _overrideNote = note;
    notifyListeners();
  }

  /// Resets the waste photo so the worker can retake.
  void resetPhoto() {
    _wastePhoto = null;
    _classification = null;
    _error = null;
    notifyListeners();
  }

  /// Finalizes the pickup completion.
  Future<bool> completePickup() async {
    if (_qrToken == null || _wastePhoto == null || _classification == null) {
      _error = 'Incomplete data.';
      notifyListeners();
      return false;
    }

    if (!isWithinDistance && (_overrideNote == null || _overrideNote!.isEmpty)) {
      _error = 'GPS distance exceeded. Note required.';
      notifyListeners();
      return false;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      if (_syncManager.status == SyncStatus.offline) {
        throw const NetworkException(message: 'Offline');
      }

      // In a real app, upload the file first then send the URL
      // Upload task simulated here:
      final mockPhotoUrl = 'https://storage.greenloop.app/pickups/${pickup.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _repository.completePickup(
        pickupId: pickup.id,
        qrToken: _qrToken!,
        photoUrl: mockPhotoUrl,
        classification: _classification!.label,
        confidence: _classification!.confidence,
        weight: _weight,
        latitude: _lastValidatedPosition!.latitude,
        longitude: _lastValidatedPosition!.longitude,
        overrideNote: _overrideNote,
      );

      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (e is NetworkException || _syncManager.status == SyncStatus.offline) {
        // Save to offline sync queue
        await _syncManager.enqueuePickup(
          pickupId: pickup.id,
          qrToken: _qrToken!,
          photoPath: _wastePhoto!.path,
          classification: _classification!.label,
          confidence: _classification!.confidence,
          weight: _weight,
          latitude: _lastValidatedPosition!.latitude,
          longitude: _lastValidatedPosition!.longitude,
          overrideNote: _overrideNote,
        );
        _loading = false;
        notifyListeners();
        return true; // Return true because it's "completed" (just queued)
      }
      _error = e.toString().replaceFirst('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }
}
