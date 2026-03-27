import 'package:flutter/foundation.dart';
import 'package:data_models/data_models.dart';
import 'complaint_service.dart';

enum ComplaintSortBy { createdAt, priority, status }

class ComplaintState extends ChangeNotifier {
  final ComplaintService _service;

  List<ComplaintModel> _complaints = [];
  List<PlatformUser> _potentialAssignees = [];
  List<Map<String, dynamic>> _heatmapData = [];
  bool _isLoading = false;
  String? _error;

  ComplaintSortBy _currentSort = ComplaintSortBy.createdAt;

  ComplaintState({required ComplaintService service}) : _service = service;

  List<ComplaintModel> get complaints {
    // Front-end sorting for reactive updates
    final sortedList = List<ComplaintModel>.from(_complaints);
    sortedList.sort((a, b) {
      if (_currentSort == ComplaintSortBy.priority) {
        return b.priority.index.compareTo(a.priority.index); // Critical first
      } else if (_currentSort == ComplaintSortBy.status) {
        return a.status.index.compareTo(b.status.index);
      }
      // Default: By Created At (oldest first as per US-ADMIN-04)
      return a.createdAt.compareTo(b.createdAt);
    });
    return sortedList;
  }

  List<PlatformUser> get potentialAssignees => _potentialAssignees;
  List<Map<String, dynamic>> get heatmapData => _heatmapData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ComplaintSortBy get currentSort => _currentSort;

  /// Load complaints and potential assignees.
  Future<void> loadComplaints() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getComplaints(),
        _service.getPotentialAssignees(),
      ]);
      _complaints = results[0] as List<ComplaintModel>;
      _potentialAssignees = results[1] as List<PlatformUser>;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load heatmap data specifically.
  Future<void> loadHeatmap() async {
    _isLoading = true;
    notifyListeners();
    try {
      _heatmapData = await _service.getHeatmapData();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Assign complaint to user.
  Future<void> assignComplaint(String complaintId, String userId) async {
    try {
      final updated = await _service.assignComplaint(complaintId, userId);
      final index = _complaints.indexWhere((c) => c.id == complaintId);
      if (index != -1) {
        _complaints[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Advance to next status lifecycle.
  Future<void> advanceStatus(ComplaintModel complaint) async {
    final nextStatus = _getNextStatus(complaint.status);
    if (nextStatus == null) return;

    try {
      final updated = await _service.updateStatus(complaint.id, nextStatus);
      final index = _complaints.indexWhere((c) => c.id == complaint.id);
      if (index != -1) {
        _complaints[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  ComplaintStatus? _getNextStatus(ComplaintStatus current) {
    switch (current) {
      case ComplaintStatus.submitted:
        return ComplaintStatus.assigned;
      case ComplaintStatus.assigned:
        return ComplaintStatus.inProgress;
      case ComplaintStatus.inProgress:
        return ComplaintStatus.resolved;
      case ComplaintStatus.resolved:
        return ComplaintStatus.closed;
      case ComplaintStatus.closed:
        return null; // Terminal state
    }
  }

  void setSort(ComplaintSortBy sort) {
    _currentSort = sort;
    notifyListeners();
  }
}
