import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_kit/ui_kit.dart';
import 'attendance_state.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceState>().loadAttendance();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AttendanceState>();

    return Padding(
      padding: const EdgeInsets.all(GLSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance Records',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            'View daily worker attendance logs',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: GLSpacing.xl),
          Expanded(
            child: Card(
              child: state.isLoading && state.records.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.records.isEmpty
                      ? const Center(child: Text('No attendance records found'))
                      : ListView.builder(
                          itemCount: state.records.length,
                          itemBuilder: (context, index) {
                            final record = state.records[index];
                            return ListTile(
                              leading: record.selfieUrl != null 
                                ? CircleAvatar(backgroundImage: NetworkImage(record.selfieUrl!))
                                : const CircleAvatar(child: Icon(Icons.person)),
                              title: Text('Date: ${record.date}'),
                              subtitle: Text('Status: ${record.status.toUpperCase()}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (record.checkInTime != null && record.checkInTime!.length >= 16)
                                        Text('In: ${record.checkInTime!.substring(11, 16)}', style: const TextStyle(fontSize: 12)),
                                      if (record.checkOutTime != null && record.checkOutTime!.length >= 16)
                                        Text('Out: ${record.checkOutTime!.substring(11, 16)}', style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                  const SizedBox(width: GLSpacing.md),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => context.read<AttendanceState>().deleteAttendance(record.id),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
