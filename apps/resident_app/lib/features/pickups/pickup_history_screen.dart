import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:core/core.dart';
import 'package:data_models/data_models.dart';
import 'package:intl/intl.dart';

class PickupHistoryScreen extends StatefulWidget {
  const PickupHistoryScreen({super.key});

  @override
  State<PickupHistoryScreen> createState() => _PickupHistoryScreenState();
}

class _PickupHistoryScreenState extends State<PickupHistoryScreen> {
  late Future<List<PickupResponse>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    final repo = context.read<PickupRepository>();
    _historyFuture = repo.getPickups();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pickup History'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: FutureBuilder<List<PickupResponse>>(
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
                      Text('Failed to load history: ${snapshot.error}', textAlign: TextAlign.center),
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
            }

            final pickups = snapshot.data ?? [];
            
            final upcomingPickups = pickups.where((p) {
              final status = p.status.toLowerCase();
              return status == 'scheduled' || status == 'pending' || status == 'accepted';
            }).toList();

            final completedPickups = pickups.where((p) {
              final status = p.status.toLowerCase();
              return status == 'completed' || status == 'cancelled' || status == 'missed';
            }).toList();

            return TabBarView(
              children: [
                _buildList(upcomingPickups, 'No upcoming pickups booked.'),
                _buildList(completedPickups, 'No earlier pickups found.'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(List<PickupResponse> items, String emptyMessage) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _loadHistory();
          });
          await _historyFuture;
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(GLSpacing.xl),
          children: [
            const SizedBox(height: 80),
            const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: GLSpacing.md),
            Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _loadHistory();
        });
        await _historyFuture;
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(GLSpacing.md),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final pickup = items[index];
          final date = DateTime.tryParse(pickup.scheduledDate) ?? DateTime.now();
          return Card(
            margin: const EdgeInsets.only(bottom: GLSpacing.sm),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: pickup.isInstant ? Colors.orange.withValues(alpha: 0.1) : _getStatusColor(pickup.status).withValues(alpha: 0.1),
                child: pickup.isInstant 
                    ? const Icon(Icons.bolt, color: Colors.orange)
                    : Icon(Icons.recycling, color: _getStatusColor(pickup.status)),
              ),
              title: Text(pickup.wasteType.label),
              subtitle: Text('Date: ${DateFormat('EEE, MMM d, yyyy').format(date)}\n${pickup.bookingType}${pickup.isInstant ? '' : ' - ${pickup.slot}'}'),
              isThreeLine: true,
              trailing: Chip(
                label: Text(
                  pickup.status.toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
                backgroundColor: _getStatusColor(pickup.status).withValues(alpha: 0.1),
                side: BorderSide(color: _getStatusColor(pickup.status)),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Colors.green;
      case 'scheduled':
      case 'pending':
      case 'accepted':
        return Colors.blue;
      case 'cancelled': return Colors.red;
      case 'missed': return Colors.orange;
      default: return Colors.grey;
    }
  }
}

