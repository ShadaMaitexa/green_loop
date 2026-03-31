import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:data_models/data_models.dart';
import 'pickup_state.dart';

class PickupManagementScreen extends StatefulWidget {
  const PickupManagementScreen({super.key});

  @override
  State<PickupManagementScreen> createState() => _PickupManagementScreenState();
}

class _PickupManagementScreenState extends State<PickupManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PickupState>().fetchPickups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PickupState>();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(GLSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pickup Management',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              GLButton(
                text: 'Refresh',
                icon: Icons.refresh_rounded,
                variant: GLButtonVariant.outline,
                onPressed: () => context.read<PickupState>().fetchPickups(),
              ),
            ],
          ),
          const SizedBox(height: GLSpacing.lg),
          if (state.isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (state.error != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: GLSpacing.md),
                    Text(state.error!),
                  ],
                ),
              ),
            )
          else if (state.pickups.isEmpty)
            const Expanded(
              child: Center(child: Text('No pickups found.')),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: state.pickups.length,
                separatorBuilder: (context, index) => const SizedBox(height: GLSpacing.md),
                itemBuilder: (context, index) {
                  final pickup = state.pickups[index];
                  return _PickupCard(pickup: pickup);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _PickupCard extends StatelessWidget {
  final PickupResponse pickup;

  const _PickupCard({required this.pickup});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(GLRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(GLSpacing.lg),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(GLSpacing.md),
              decoration: BoxDecoration(
                color: pickup.wasteType.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(GLRadius.md),
              ),
              child: Icon(
                pickup.wasteType.icon,
                color: pickup.wasteType.color,
              ),
            ),
            const SizedBox(width: GLSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${pickup.wasteType.label} Waste Pickup',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Scheduled: ${pickup.scheduledDate} (${pickup.slot})',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            _StatusBadge(status: pickup.status),
            const SizedBox(width: GLSpacing.md),
            if (pickup.status != 'cancelled' && pickup.status != 'completed')
              IconButton(
                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                onPressed: () => _showCancelDialog(context),
              ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (innerContext) => AlertDialog(
        title: const Text('Cancel Pickup'),
        content: const Text('Are you sure you want to cancel this pickup?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(innerContext),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(innerContext);
              context.read<PickupState>().cancelPickup(int.parse(pickup.id));
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      default:
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
