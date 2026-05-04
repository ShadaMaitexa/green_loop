import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:core/core.dart';
import 'package:data_models/data_models.dart';
import 'package:intl/intl.dart';
import 'complaint_detail_screen.dart';
import 'complaint_submission_screen.dart';

class ComplaintHistoryScreen extends StatefulWidget {
  const ComplaintHistoryScreen({super.key});

  @override
  State<ComplaintHistoryScreen> createState() => _ComplaintHistoryScreenState();
}

class _ComplaintHistoryScreenState extends State<ComplaintHistoryScreen> {
  late Future<List<ComplaintModel>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    final repo = context.read<ComplaintRepository>();
    // API GET /api/v1/complaints/ natively filters by the logged-in resident's user token.
    _historyFuture = repo.getComplaints();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Complaints'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ComplaintSubmissionScreen()),
          ).then((_) => _loadHistory());
        },
        icon: const Icon(Icons.add),
        label: const Text('New Complaint'),
      ),
      body: FutureBuilder<List<ComplaintModel>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(GLSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: GLSpacing.md),
                    Text('Failed to load complaints: ${snapshot.error}', textAlign: TextAlign.center),
                    const SizedBox(height: GLSpacing.lg),
                    GLButton(
                      text: 'Retry',
                      onPressed: () {
                        setState(() {
                          _loadHistory();
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(GLSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                    const SizedBox(height: GLSpacing.md),
                    Text('No complaints filed yet.', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey)),
                  ],
                ),
              ),
            );
          }

          final complaints = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _loadHistory();
              });
              await _historyFuture;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(GLSpacing.md),
              itemCount: complaints.length,
              itemBuilder: (context, index) {
                final complaint = complaints[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: GLSpacing.sm),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ComplaintDetailScreen(complaintId: complaint.id)),
                      ).then((_) {
                         setState(() => _loadHistory());
                      });
                    },
                    leading: CircleAvatar(
                      backgroundColor: complaint.status.color.withValues(alpha: 0.1),
                      child: Icon(complaint.status.icon, color: complaint.status.color),
                    ),
                    title: Text(complaint.type, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      'Filed: ${DateFormat('MMM d, yyyy').format(complaint.createdAt)}\n${complaint.description}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    isThreeLine: true,
                    trailing: Chip(
                      label: Text(
                        complaint.status.label.toUpperCase(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: complaint.status.color.withValues(alpha: 0.1),
                      side: BorderSide(color: complaint.status.color),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
