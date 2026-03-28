import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:provider/provider.dart';
import '../wards/ward_state.dart';
import '../users/user_management_state.dart';

class PilotReadinessScreen extends StatefulWidget {
  const PilotReadinessScreen({super.key});

  @override
  State<PilotReadinessScreen> createState() => _PilotReadinessScreenState();
}

class _PilotReadinessScreenState extends State<PilotReadinessScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WardState>().loadWards();
      context.read<UserManagementState>().loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final wardState = context.watch<WardState>();
    final userState = context.watch<UserManagementState>();
    final theme = Theme.of(context);

    final seededWards = wardState.wards.where((w) => w.boundary != null && w.boundary!.isNotEmpty).toList();
    final hksWorkers = userState.users.where((u) => u.role.name == 'HKS_WORKER' || u.role.name == 'hks').toList();
    final activeWorkers = hksWorkers.where((u) => u.isActive).toList();
    final residents = userState.users.where((u) => u.role.name == 'RESIDENT').toList();

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
                  Text('Pilot Launch Readiness', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text('Track progress for the initial GreenLoop pilot phase.', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                ],
              ),
              GLButton(
                text: 'Load Pilot Seeds',
                variant: GLButtonVariant.outline,
                icon: Icons.auto_fix_high_rounded,
                onPressed: () {
                  // Simulate manage.py seed_wards / pilot data
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Simulating pilot data seed...')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: GLSpacing.xxl),
          Expanded(
            child: GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : 1,
              childAspectRatio: 1.5,
              mainAxisSpacing: GLSpacing.lg,
              crossAxisSpacing: GLSpacing.lg,
              children: [
                _buildReadinessCard(
                  context,
                  title: 'Wards Configured',
                  current: seededWards.length,
                  target: 4,
                  icon: Icons.map_rounded,
                  color: Colors.blue,
                  details: '${seededWards.length} wards have polygon boundaries defined.',
                ),
                _buildReadinessCard(
                  context,
                  title: 'HKS Workers Active',
                  current: activeWorkers.length,
                  target: 12,
                  icon: Icons.badge_rounded,
                  color: Colors.orange,
                  details: '${activeWorkers.length} workers trained and accounts activated.',
                ),
                _buildReadinessCard(
                  context,
                  title: 'Residents Onboarded',
                  current: residents.length,
                  target: 50,
                  icon: Icons.people_rounded,
                  color: Colors.green,
                  details: '${residents.length} residents registered in system.',
                ),
              ],
            ),
          ),
          const SizedBox(height: GLSpacing.xl),
          _buildTrainingSection(context),
        ],
      ),
    );
  }

  Widget _buildReadinessCard(
    BuildContext context, {
    required String title,
    required int current,
    required int target,
    required IconData icon,
    required Color color,
    required String details,
  }) {
    final progress = (current / target).clamp(0.0, 1.0);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(GLSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(GLSpacing.sm),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(GLRadius.md)),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: GLSpacing.md),
                Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (progress >= 1.0)
                  const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$current / $target', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: color)),
                Text('${(progress * 100).toInt()}%', style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: GLSpacing.sm),
            LinearProgressIndicator(value: progress, backgroundColor: color.withOpacity(0.1), valueColor: AlwaysStoppedAnimation(color)),
            const SizedBox(height: GLSpacing.md),
            Text(details, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingSection(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(GLSpacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(GLRadius.xl),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.menu_book_rounded, size: 48, color: Colors.green),
          const SizedBox(width: GLSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Training Materials (Malayalam)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text(
                  'Distribute HKS operation guides and resident awareness posters in Malayalam for the pilot launch.',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          GLButton(
            text: 'View Materials',
            variant: GLButtonVariant.outline,
            onPressed: () {},
          ),
          const SizedBox(width: GLSpacing.md),
          GLButton(
            text: 'Distribute to Workers',
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Guides sent to all active HKS worker devices.'), backgroundColor: Colors.green),
              );
            },
          ),
        ],
      ),
    );
  }
}
