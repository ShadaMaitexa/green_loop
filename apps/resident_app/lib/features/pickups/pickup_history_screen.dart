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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickup History'),
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
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(GLSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                    const SizedBox(height: GLSpacing.md),
                    Text('No pickups found.', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey)),
                  ],
                ),
              ),
            );
          }

          final pickups = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _loadHistory();
              });
              await _historyFuture;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(GLSpacing.md),
              itemCount: pickups.length,
              itemBuilder: (context, index) {
                final pickup = pickups[index];
                final date = DateTime.tryParse(pickup.scheduledDate) ?? DateTime.now();
                return Card(
                  margin: const EdgeInsets.only(bottom: GLSpacing.sm),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(pickup.status).withOpacity(0.1),
                      child: Icon(Icons.recycling, color: _getStatusColor(pickup.status)),
                    ),
                    title: Text(pickup.wasteType.label),
                    subtitle: Text('Date: ${DateFormat('EEE, MMM d, yyyy').format(date)}\nSlot: ${pickup.slot}'),
                    isThreeLine: true,
                    trailing: Chip(
                      label: Text(
                        pickup.status.toUpperCase(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: _getStatusColor(pickup.status).withOpacity(0.1),
                      side: BorderSide(color: _getStatusColor(pickup.status)),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Colors.green;
      case 'scheduled': return Colors.blue;
      case 'cancelled': return Colors.red;
      case 'missed': return Colors.orange;
      default: return Colors.grey;
    }
  }
}
