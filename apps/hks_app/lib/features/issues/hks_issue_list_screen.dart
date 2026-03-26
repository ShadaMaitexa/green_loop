import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:data_models/data_models.dart';
import 'package:core/core.dart';
import 'package:intl/intl.dart';

class HksIssueListScreen extends StatefulWidget {
  const HksIssueListScreen({super.key});

  @override
  State<HksIssueListScreen> createState() => _HksIssueListScreenState();
}

class _HksIssueListScreenState extends State<HksIssueListScreen> {
  bool _isLoading = true;
  List<ComplaintModel> _issues = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchIssues();
  }

  Future<void> _fetchIssues() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = context.read<ComplaintRepository>();
      final issues = await repo.getComplaints();
      if (mounted) {
        setState(() {
          _issues = issues;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Field Issues'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchIssues,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Could not load issues: $_error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 24),
              GLButton(text: 'Retry', onPressed: _fetchIssues),
            ],
          ),
        ),
      );
    }

    if (_issues.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_rounded, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No issues reported.', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchIssues,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _issues.length,
        itemBuilder: (context, index) {
          final issue = _issues[index];
          return _buildIssueCard(issue);
        },
      ),
    );
  }

  Widget _buildIssueCard(ComplaintModel issue) {
    Color statusColor;
    IconData statusIcon;

    switch (issue.status) {
      case ComplaintStatus.resolved:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        break;
      case ComplaintStatus.inProgress:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case ComplaintStatus.submitted:
        statusColor = Colors.blue;
        statusIcon = Icons.pending_actions_rounded;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    issue.type,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        issue.status.label,
                        style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              issue.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(issue.createdAt),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                const Spacer(),
                const Text('ID: #', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(issue.id.substring(issue.id.length > 8 ? issue.id.length - 8 : 0), style: TextStyle(color: Colors.grey[700], fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
