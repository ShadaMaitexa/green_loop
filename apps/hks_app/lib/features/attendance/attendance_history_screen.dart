import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:data_models/data_models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'attendance_state.dart';

/// Monthly attendance history with a custom calendar grid and day detail sheet.
class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  DateTime _focusedMonth = DateTime.now();
  List<AttendanceRecord> _records = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadMonth(_focusedMonth);
  }

  Future<void> _loadMonth(DateTime month) async {
    setState(() => _loading = true);
    final state = context.read<AttendanceState>();
    final records = await state.fetchMonthHistory(month);
    if (mounted) setState(() { _records = records; _loading = false; });
  }

  AttendanceRecord? _recordForDay(int day) {
    final dateStr = '${_focusedMonth.year}-'
        '${_focusedMonth.month.toString().padLeft(2, '0')}-'
        '${day.toString().padLeft(2, '0')}';
    try {
      return _records.firstWhere((r) => r.date == dateStr);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysInMonth = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    final firstWeekday = DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday % 7; // 0=Sun

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance History')),
      body: Column(
        children: [
          // Month navigator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () {
                    final prev = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                    setState(() => _focusedMonth = prev);
                    _loadMonth(prev);
                  },
                ),
                Text(
                  _monthLabel(_focusedMonth),
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: _focusedMonth.year == DateTime.now().year &&
                          _focusedMonth.month == DateTime.now().month
                      ? null
                      : () {
                          final next = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                          setState(() => _focusedMonth = next);
                          _loadMonth(next);
                        },
                ),
              ],
            ),
          ),

          // Day-of-week headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Calendar grid
          _loading
              ? const Expanded(child: Center(child: CircularProgressIndicator()))
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio: 1,
                    ),
                    itemCount: firstWeekday + daysInMonth,
                    itemBuilder: (context, index) {
                      if (index < firstWeekday) return const SizedBox.shrink();
                      final day = index - firstWeekday + 1;
                      final record = _recordForDay(day);
                      final isToday = DateTime.now().day == day &&
                          DateTime.now().month == _focusedMonth.month &&
                          DateTime.now().year == _focusedMonth.year;

                      return _DayCell(
                        day: day,
                        record: record,
                        isToday: isToday,
                        onTap: record != null ? () => _showDayDetail(context, record) : null,
                      );
                    },
                  ),
                ),

          const SizedBox(height: 24),

          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _legend(Colors.green, 'Present'),
                _legend(Colors.orange, 'Partial'),
                _legend(Colors.grey[300]!, 'Absent'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Monthly summary
          _buildSummary(theme, daysInMonth),
        ],
      ),
    );
  }

  Widget _buildSummary(ThemeData theme, int daysInMonth) {
    final present = _records.where((r) => r.status == 'present').length;
    final partial = _records.where((r) => r.status == 'partial').length;
    final today = DateTime.now();
    final workingDaysPassed = _focusedMonth.month < today.month || _focusedMonth.year < today.year
        ? daysInMonth
        : today.day;
    final absent = workingDaysPassed - present - partial;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _statCard(theme, '$present', 'Present', Colors.green),
          const SizedBox(width: 12),
          _statCard(theme, '$partial', 'Partial', Colors.orange),
          const SizedBox(width: 12),
          _statCard(theme, '${absent < 0 ? 0 : absent}', 'Absent', Colors.red),
        ],
      ),
    );
  }

  Widget _statCard(ThemeData theme, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  void _showDayDetail(BuildContext context, AttendanceRecord record) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DayDetailSheet(record: record),
    );
  }

  String _monthLabel(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }
}

// ─── Day Cell Widget ──────────────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  final int day;
  final AttendanceRecord? record;
  final bool isToday;
  final VoidCallback? onTap;

  const _DayCell({
    required this.day,
    required this.record,
    required this.isToday,
    this.onTap,
  });

  Color get _statusColor {
    if (record == null) return Colors.transparent;
    switch (record!.status) {
      case 'present': return Colors.green;
      case 'partial': return Colors.orange;
      default: return Colors.red[200]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isInFuture = DateTime.now().isBefore(
      DateTime(DateTime.now().year, DateTime.now().month, day),
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isToday
              ? theme.colorScheme.primary.withOpacity(0.15)
              : record?.status == 'present'
                  ? Colors.green.withOpacity(0.12)
                  : record?.status == 'partial'
                      ? Colors.orange.withOpacity(0.12)
                      : null,
          shape: BoxShape.circle,
          border: isToday
              ? Border.all(color: theme.colorScheme.primary, width: 2)
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isInFuture && !isToday ? Colors.grey[300] : null,
              ),
            ),
            if (record != null)
              Positioned(
                bottom: 4,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(color: _statusColor, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Day Detail Bottom Sheet ──────────────────────────────────────────────────

class _DayDetailSheet extends StatelessWidget {
  final AttendanceRecord record;

  const _DayDetailSheet({required this.record});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 24),
          Text(record.date, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: record.status == 'present'
                  ? Colors.green.withOpacity(0.1)
                  : record.status == 'partial'
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              record.status.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: record.status == 'present'
                    ? Colors.green
                    : record.status == 'partial'
                        ? Colors.orange
                        : Colors.red,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Times
          _timeRow(Icons.login_rounded, 'Check-In', record.checkInTime ?? '—', Colors.green),
          const SizedBox(height: 12),
          _timeRow(Icons.logout_rounded, 'Check-Out', record.checkOutTime ?? '—', Colors.blue),

          // PPE status
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                record.ppeConfirmed ? Icons.verified_rounded : Icons.warning_rounded,
                color: record.ppeConfirmed ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                record.ppeConfirmed ? 'PPE Compliance Confirmed' : 'PPE Not Confirmed',
                style: TextStyle(
                  color: record.ppeConfirmed ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Selfie preview
          if (record.selfieUrl != null) ...[
            const SizedBox(height: 16),
            GLImage(
              imageUrl: record.selfieUrl!,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _timeRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ],
    );
  }
}
