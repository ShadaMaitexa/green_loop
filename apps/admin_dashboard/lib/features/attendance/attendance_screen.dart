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
                              leading: const Icon(Icons.person_outline),
                              title: Text('Worker ID: ${record['worker']}'),
                              subtitle: Text('Date: ${record['date']} | Status: ${record['status']}'),
                              trailing: Text(record['time_logged']?.toString() ?? ''),
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
