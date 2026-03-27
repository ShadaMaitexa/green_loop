import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:data_models/data_models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'complaint_state.dart';
import 'package:intl/intl.dart';

class ComplaintManagementScreen extends StatefulWidget {
  const ComplaintManagementScreen({super.key});

  @override
  State<ComplaintManagementScreen> createState() => _ComplaintManagementScreenState();
}

class _ComplaintManagementScreenState extends State<ComplaintManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ComplaintState>().loadComplaints();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ComplaintState>();
    final theme = Theme.of(context);

    return Column(
      children: [
        _buildHeader(context, state, theme),
        const Divider(height: 1),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildQueue(context, state, theme),
              _buildHeatmap(context, state),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ComplaintState state, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(GLSpacing.xl),
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Complaints Management', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text('Process and resolve platform-wide citizen complaints.', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                ],
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Queue'),
                  Tab(text: 'Heatmap'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQueue(BuildContext context, ComplaintState state, ThemeData theme) {
    if (state.isLoading && state.complaints.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.complaints.isEmpty) {
      return const Center(child: Text('No complaints in queue.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(GLSpacing.lg),
      itemCount: state.complaints.length,
      separatorBuilder: (context, index) => const SizedBox(height: GLSpacing.md),
      itemBuilder: (context, index) {
        final complaint = state.complaints[index];
        return _buildComplaintCard(context, state, theme, complaint);
      },
    );
  }

  Widget _buildComplaintCard(BuildContext context, ComplaintState state, ThemeData theme, ComplaintModel complaint) {
    final dateFormat = DateFormat('MMM d, h:mm a');
    final ageHours = DateTime.now().difference(complaint.createdAt).inHours;
    final isEscalated = ageHours >= 48 || complaint.isEscalated;

    return Card(
      elevation: isEscalated ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GLSpacing.md),
        side: isEscalated ? BorderSide(color: Colors.red.withOpacity(0.3), width: 1.5) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(GLSpacing.lg),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPriorityBadge(complaint.priority),
                const SizedBox(width: GLSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(complaint.type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const Spacer(),
                          Text(dateFormat.format(complaint.createdAt), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: GLSpacing.xs),
                      Text(complaint.description, style: TextStyle(color: Colors.grey[800])),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: GLSpacing.lg),
            const Divider(),
            const SizedBox(height: GLSpacing.sm),
            Row(
              children: [
                _buildStatusChip(complaint.status),
                const SizedBox(width: GLSpacing.md),
                if (complaint.assignedTo != null) ...[
                  const Icon(Icons.person_outline_rounded, size: 16, color: Colors.grey),
                  const SizedBox(width: GLSpacing.xs),
                  Text('Assigned: UserID ${complaint.assignedTo}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
                const Spacer(),
                if (complaint.status == ComplaintStatus.submitted)
                  GLButton(
                    text: 'Assign',
                    size: GLButtonSize.small,
                    onPressed: () => _showAssignDialog(context, state, complaint),
                    icon: Icons.person_add_rounded,
                  )
                else if (complaint.status != ComplaintStatus.closed)
                  GLButton(
                    text: _getNextStatusLabel(complaint.status),
                    size: GLButtonSize.small,
                    onPressed: () => state.advanceStatus(complaint),
                    icon: Icons.arrow_forward_rounded,
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    textColor: Colors.blue,
                  ),
              ],
            ),
            if (isEscalated) ...[
              const SizedBox(height: GLSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 14),
                  const SizedBox(width: GLSpacing.xs),
                  Text('Escalated: ${ageHours}h unresolved', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(ComplaintPriority priority) {
    Color color;
    switch (priority) {
      case ComplaintPriority.low: color = Colors.green; break;
      case ComplaintPriority.medium: color = Colors.orange; break;
      case ComplaintPriority.high: color = Colors.red; break;
      case ComplaintPriority.critical: color = Colors.purple; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withOpacity(0.5))),
      child: Text(priority.label.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatusChip(ComplaintStatus status) {
    Color color;
    switch (status) {
      case ComplaintStatus.submitted: color = Colors.grey; break;
      case ComplaintStatus.assigned: color = Colors.blue; break;
      case ComplaintStatus.inProgress: color = Colors.amber; break;
      case ComplaintStatus.resolved: color = Colors.green; break;
      case ComplaintStatus.closed: color = Colors.purple; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(backgroundColor: color, radius: 4),
          const SizedBox(width: GLSpacing.xs),
          Text(status.label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  String _getNextStatusLabel(ComplaintStatus current) {
    switch (current) {
      case ComplaintStatus.assigned: return 'Start Workflow';
      case ComplaintStatus.inProgress: return 'Mark Resolved';
      case ComplaintStatus.resolved: return 'Close Issue';
      default: return 'Advance';
    }
  }

  void _showAssignDialog(BuildContext context, ComplaintState state, ComplaintModel complaint) {
    String? selectedUserId;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Complaint'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose an HKS worker or staff member to handle this issue.'),
            const SizedBox(height: GLSpacing.md),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Select Staff'),
              items: state.potentialAssignees.map((user) => DropdownMenuItem(value: user.id, child: Text('${user.name} (${user.role.label})'))).toList(),
              onChanged: (value) => selectedUserId = value,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          GLButton(
            text: 'Assign',
            onPressed: () {
              if (selectedUserId != null) {
                state.assignComplaint(complaint.id, selectedUserId!);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmap(BuildContext context, ComplaintState state) {
    // Note: To show a real "heatmap" in google_maps_flutter, one might use circles with gradients or markers.
    // For this implementation, we will use Circles representing clusters from KMeans.
    
    return GoogleMap(
      initialCameraPosition: const CameraPosition(target: LatLng(11.2588, 75.7804), zoom: 12),
      onMapCreated: (_) => state.loadHeatmap(),
      circles: state.heatmapData.map((cluster) {
        return Circle(
          circleId: CircleId('cluster_${cluster['id']}'),
          center: LatLng(cluster['latitude'], cluster['longitude']),
          radius: cluster['density'] * 50.0, // Scale radius by cluster weight
          fillColor: Colors.red.withOpacity(0.3 + (cluster['weight'] * 0.4)),
          strokeWidth: 0,
        );
      }).toSet(),
    );
  }
}
