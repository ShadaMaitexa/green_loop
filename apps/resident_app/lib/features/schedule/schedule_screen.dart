import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:data_models/data_models.dart';
import 'package:core/core.dart';
import '../pickups/booking_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  bool _isLoading = true;
  WardSchedule? _wardSchedule;
  List<PickupResponse> _myPickups = [];
  Map<String, bool> _availabilityMap = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _cancelPickup(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Cancel Pickup'),
        content: const Text('Are you sure you want to cancel this scheduled pickup?'),
        actions: [
           TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('No')),
           TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Yes')),
        ],
      ),
    );
    if (confirm != true) return;
    
    setState(() => _isLoading = true);
    try {
      await context.read<PickupRepository>().cancelPickup(id);
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to cancel: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadData() async {
    try {
      final repo = context.read<ScheduleRepository>();
      final pickupRepo = context.read<PickupRepository>();
      
      // Normally we'd use the user's wardId from their resident profile.
      // Assuming wardId 1 for demo purposes if not available in current token.
      final today = DateTime.now();
      final dates = List.generate(7, (i) => today.add(Duration(days: i)));
      
      final availabilityFutures = dates.map((d) {
        final dateStr = DateFormat('yyyy-MM-dd').format(d);
        return pickupRepo.getAvailability(dateStr, 1)
          .then((slots) => MapEntry(dateStr, slots.any((s) => s.isAvailable)))
          .catchError((_) => MapEntry(dateStr, false));
      });

      final results = await Future.wait([
        repo.getWardSchedule(1), 
        repo.getMyUpcomingPickups(),
        Future.wait(availabilityFutures),
      ]);

      setState(() {
        _wardSchedule = results[0] as WardSchedule;
        _myPickups = results[1] as List<PickupResponse>;
        final availList = results[2] as List<MapEntry<String, bool>>;
        _availabilityMap = Map.fromEntries(availList);
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
    
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final personalBookings = _myPickups.where((p) => p.scheduledDate == dateStr).toList();
    final isAvailable = _availabilityMap[dateStr] ?? false;

    if (recurringDays.isEmpty && personalBookings.isEmpty) {
       return _buildEmptyDay(date, isToday, isAvailable);
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
                Row(
                  children: [
                    if (isAvailable) ...[
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.green, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingScreen())),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(DateFormat('MMM d').format(date), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          ...recurringDays.map((d) => _buildScheduleItem(d.wasteType, d.timeText, 'WARD RECURRING')),
          ...personalBookings.map((p) => _buildScheduleItem(p.wasteType, p.slot, 'MY BOOKING', isPersonal: true, pickup: p)),
        ],
      ),
    );
  }

  Widget _buildEmptyDay(DateTime date, bool isToday, bool isAvailable) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: GLSpacing.xl, vertical: GLSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
               Text(
                 DateFormat('EEE, MMM d').format(date), 
                 style: TextStyle(color: Colors.grey, fontWeight: isToday ? FontWeight.bold : FontWeight.normal),
               ),
               const SizedBox(width: 8),
               const Expanded(child: Text('— No scheduled collections', style: TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis)),
               if (isAvailable)
                 IconButton(
                   icon: const Icon(Icons.add_circle, color: Colors.green),
                   padding: EdgeInsets.zero,
                   constraints: const BoxConstraints(),
                   onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingScreen())),
                 ),
            ],
          ),
          const Divider(height: 24),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(WasteType type, String time, String label, {bool isPersonal = false, PickupResponse? pickup}) {
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
          if (isPersonal) ...[
            const Icon(Icons.qr_code_2_rounded, size: 20, color: Colors.blue),
            if (pickup != null && pickup.status.toLowerCase() != 'cancelled' && pickup.status.toLowerCase() != 'completed')
              IconButton(
                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                onPressed: () => _cancelPickup(pickup.id),
              ),
          ]
        ],
      ),
    );
  }
}
