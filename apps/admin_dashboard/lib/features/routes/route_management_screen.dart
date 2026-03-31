import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_kit/ui_kit.dart';
import 'route_state.dart';

class RouteManagementScreen extends StatefulWidget {
  const RouteManagementScreen({super.key});

  @override
  State<RouteManagementScreen> createState() => _RouteManagementScreenState();
}

class _RouteManagementScreenState extends State<RouteManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RouteState>().loadRoutes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RouteState>();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(GLSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Route Management', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text('Monitor and optimize waste collection routes.', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                ],
              ),
              GLButton(
                text: 'Create Route',
                onPressed: () => _showCreateRouteDialog(context),
                icon: Icons.add_rounded,
              ),
            ],
          ),
          const SizedBox(height: GLSpacing.xl),
          Expanded(
            child: state.isLoading && state.routes.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.routes.isEmpty
                    ? const Center(child: Text('No routes found. Create one to begin.'))
                    : ListView.separated(
                        itemCount: state.routes.length,
                        separatorBuilder: (context, index) => const SizedBox(height: GLSpacing.md),
                        itemBuilder: (context, index) {
                          final route = state.routes[index];
                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.route_rounded)),
                              title: Text('Route: ${route.id.substring(0, 8)}'),
                              subtitle: Text('Status: ${route.status.toUpperCase()} | Assigned to: ${route.hksWorker?.name ?? "Unassigned"}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.auto_fix_high_rounded, color: Colors.blue),
                                    onPressed: () => state.optimizeRoute(route.id),
                                    tooltip: 'Optimize',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                    onPressed: () => state.deleteRoute(route.id),
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showCreateRouteDialog(BuildContext context) {
    // Basic dialog for demonstration. In a real app, you'd select workers/wards.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Route'),
        content: const Text('New route will be automatically generated for tomorrow based on pending pickups.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          GLButton(
            text: 'Generate',
            onPressed: () async {
              final success = await context.read<RouteState>().createRoute({
                'route_date': DateTime.now().add(const Duration(days: 1)).toIso8601String().substring(0, 10),
              });
              if (success && mounted && context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
