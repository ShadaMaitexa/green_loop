import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_kit/ui_kit.dart';
import 'attendance_state.dart';
import 'selfie_capture_screen.dart';
import 'ppe_checklist_screen.dart';
import 'attendance_history_screen.dart';

/// Main attendance dashboard widget. Intended to be embedded in the HKS home
/// navigation or shown as a sheet from the Route Map. Shows:
///   • Today's check-in/check-out status
///   • Action button (Check In → selfie → PPE / Check Out)
///   • Quick link to monthly history
class AttendanceDashboard extends StatefulWidget {
  const AttendanceDashboard({super.key});

  @override
  State<AttendanceDashboard> createState() => _AttendanceDashboardState();
}

class _AttendanceDashboardState extends State<AttendanceDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceState>().fetchTodayAttendance();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'History',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AttendanceHistoryScreen()),
            ),
          ),
        ],
      ),
      body: Consumer<AttendanceState>(
        builder: (context, state, _) {
          if (state.loading && state.today == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusCard(context, state),
                const SizedBox(height: 24),
                _buildTimeline(context, state),
                const SizedBox(height: 32),
                _buildActions(context, state),
                const SizedBox(height: 24),
                _buildHistoryTeaser(context),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Status Card ───────────────────────────────────────────────────────────

  Widget _buildStatusCard(BuildContext context, AttendanceState state) {
    final theme = Theme.of(context);
    final today = state.today;
    final isIn = today?.isCheckedIn ?? false;
    final isOut = today?.isCheckedOut ?? false;

    Color gradientStart;
    Color gradientEnd;
    String headline;
    String subline;
    IconData icon;

    if (!isIn) {
      gradientStart = Colors.blueGrey.shade700;
      gradientEnd = Colors.blueGrey.shade400;
      headline = 'Not Checked In';
      subline = 'Start your shift by checking in with a PPE selfie.';
      icon = Icons.schedule_rounded;
    } else if (isIn && !isOut) {
      gradientStart = Colors.green.shade700;
      gradientEnd = Colors.green.shade400;
      headline = 'Shift In Progress';
      subline = 'Checked in at ${_formatTime(today!.checkInTime!)}';
      icon = Icons.work_rounded;
    } else {
      gradientStart = Colors.teal.shade700;
      gradientEnd = Colors.teal.shade400;
      headline = 'Shift Complete';
      subline = 'Great work today! You\'re checked out.';
      icon = Icons.celebration_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [gradientStart, gradientEnd], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: gradientStart.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(headline, style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subline, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Timeline ──────────────────────────────────────────────────────────────

  Widget _buildTimeline(BuildContext context, AttendanceState state) {
    final theme = Theme.of(context);
    final today = state.today;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Today's Record", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _timelineItem(
          icon: Icons.login_rounded,
          label: 'Check-In',
          value: today?.checkInTime != null ? _formatTime(today!.checkInTime!) : 'Not yet',
          color: Colors.green,
          isDone: today?.isCheckedIn ?? false,
        ),
        _timelineLine(),
        _timelineItem(
          icon: Icons.verified_user_rounded,
          label: 'PPE Confirmed',
          value: today?.ppeConfirmed == true ? 'All items checked' : '—',
          color: Colors.blue,
          isDone: today?.ppeConfirmed ?? false,
        ),
        _timelineLine(),
        _timelineItem(
          icon: Icons.logout_rounded,
          label: 'Check-Out',
          value: today?.checkOutTime != null ? _formatTime(today!.checkOutTime!) : 'Pending',
          color: Colors.teal,
          isDone: today?.isCheckedOut ?? false,
        ),
      ],
    );
  }

  Widget _timelineItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDone,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDone ? color.withOpacity(0.1) : Colors.grey[100],
            shape: BoxShape.circle,
            border: Border.all(color: isDone ? color : Colors.grey[300]!, width: 2),
          ),
          child: Icon(icon, color: isDone ? color : Colors.grey, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ],
        ),
      ],
    );
  }

  Widget _timelineLine() {
    return Padding(
      padding: const EdgeInsets.only(left: 19),
      child: Container(width: 2, height: 20, color: Colors.grey[200]),
    );
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  Widget _buildActions(BuildContext context, AttendanceState state) {
    final today = state.today;
    final isIn = today?.isCheckedIn ?? false;
    final isOut = today?.isCheckedOut ?? false;

    if (state.error != null && !state.loading) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(child: Text(state.error!, style: const TextStyle(color: Colors.red))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: GLButton(
              text: 'Retry',
              variant: GLButtonVariant.outline,
              icon: Icons.refresh_rounded,
              onPressed: () => state.fetchTodayAttendance(),
            ),
          ),
        ],
      );
    }

    if (isOut) {
      return const SizedBox.shrink(); // Shift complete, no more actions
    }

    if (isIn) {
      return SizedBox(
        width: double.infinity,
        child: GLButton(
          text: 'End Shift (Check-Out)',
          icon: Icons.logout_rounded,
          variant: GLButtonVariant.outline,
          isLoading: state.loading,
          onPressed: () => _handleCheckOut(context, state),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: GLButton(
        text: 'Start Check-In',
        icon: Icons.camera_alt_rounded,
        onPressed: () => _startCheckInFlow(context, state),
      ),
    );
  }

  Widget _buildHistoryTeaser(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AttendanceHistoryScreen()),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.calendar_month_rounded, color: Colors.grey),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Monthly Attendance', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('View your full attendance history', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }

  // ─── Flow Handlers ─────────────────────────────────────────────────────────

  Future<void> _startCheckInFlow(BuildContext context, AttendanceState state) async {
    // Step 1: Open selfie camera
    final selfieFile = await Navigator.push<File?>(
      context,
      MaterialPageRoute(builder: (_) => const SelfieCaptureScreen()),
    );

    if (selfieFile == null || !context.mounted) return;

    state.setSelfie(selfieFile);
    state.resetChecklist();

    // Step 2: PPE checklist + GPS submit
    final checkedIn = await Navigator.push<bool?>(
      context,
      MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(
        value: state,
        child: const PpeChecklistScreen(),
      )),
    );

    if (checkedIn == true && context.mounted) {
      _showSuccessSnack(context, 'Checked in successfully! Have a safe shift. 👷');
    }
  }

  Future<void> _handleCheckOut(BuildContext context, AttendanceState state) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Your Shift?'),
        content: const Text('This will record your check-out time for today. Are you ready to finish your shift?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not Yet')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Check Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final success = await state.submitCheckOut();
    if (success && context.mounted) {
      _showSuccessSnack(context, 'Checked out! Great work today. 🌿');
    }
  }

  void _showSuccessSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour < 12 ? 'AM' : 'PM';
      return '$h:$m $ampm';
    } catch (_) {
      return iso;
    }
  }
}
