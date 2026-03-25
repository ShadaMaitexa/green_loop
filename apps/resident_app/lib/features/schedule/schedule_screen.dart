import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:data_models/data_models.dart';
import 'package:core/core.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  bool _isLoading = true;
  WardSchedule? _wardSchedule;
  List<PickupResponse> _myPickups = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final repo = context.read<ScheduleRepository>();
      
      // Normally we'd use the user's wardId from their resident profile.
      // Assuming wardId 1 for demo purposes if not available in current token.
      final results = await Future.wait([
        repo.getWardSchedule(1), 
        repo.getMyUpcomingPickups(),
      ]);

      setState(() {
        _wardSchedule = results[0] as WardSchedule;
        _myPickups = results[1] as List<PickupResponse>;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load schedule: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final today = DateTime.now();
    final weekDates = List.generate(7, (i) => today.add(Duration(days: i)));

    return Scaffold(
      appBar: AppBar(title: const Text('Waste Collection Schedule')),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: GLSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildLegend(),
              const SizedBox(height: GLSpacing.lg),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: weekDates.length,
                itemBuilder: (context, index) {
                  final date = weekDates[index];
                  return _buildDayCard(date, today);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: GLSpacing.xl),
      child: Row(
        children: WasteType.values.map((t) => Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Row(
            children: [
              Icon(t.icon, size: 16, color: t.color),
              const SizedBox(width: 4),
              Text(t.label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildDayCard(DateTime date, DateTime today) {
    final dayName = DateFormat('EEEE').format(date);
    final isToday = date.day == today.day && date.month == today.month && date.year == today.year;
    
    // Find recurring collection for this day
    final recurringDays = _wardSchedule?.days.where((d) => d.dayOfWeek == dayName).toList() ?? [];
    
    // Find personal bookings for this date
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final personalBookings = _myPickups.where((p) => p.scheduledDate == dateStr).toList();

    if (recurringDays.isEmpty && personalBookings.isEmpty) {
       return _buildEmptyDay(date, isToday);
    }

    return GLCard(
      margin: const EdgeInsets.symmetric(horizontal: GLSpacing.xl, vertical: GLSpacing.sm),
      variant: isToday ? GLCardVariant.elevated : GLCardVariant.outlined,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isToday ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.transparent,
              border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isToday ? 'TODAY' : dayName.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isToday ? Theme.of(context).colorScheme.primary : Colors.grey,
                    fontSize: 12,
                  ),
                ),
                Text(DateFormat('MMM d').format(date), style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          ...recurringDays.map((d) => _buildScheduleItem(d.wasteType, d.timeText, 'WARD RECURRING')),
          ...personalBookings.map((p) => _buildScheduleItem(p.wasteType, p.slot, 'MY BOOKING', isPersonal: true)),
        ],
      ),
    );
  }

  Widget _buildEmptyDay(DateTime date, bool isToday) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: GLSpacing.xl, vertical: GLSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
               Text(
                 DateFormat('EEE, MMM d').format(date), 
                 style: TextStyle(color: Colors.grey, fontWeight: isToday ? FontWeight.bold : FontWeight.normal),
               ),
               const SizedBox(width: 8),
               const Text('— No scheduled collections', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const Divider(height: 24),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(WasteType type, String time, String label, {bool isPersonal = false}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: type.color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(type.icon, color: type.color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(type.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPersonal ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        label, 
                        style: TextStyle(fontSize: 9, color: isPersonal ? Colors.blue : Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                Text(time, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          if (isPersonal) const Icon(Icons.qr_code_2_rounded, size: 20, color: Colors.blue),
        ],
      ),
    );
  }
}
