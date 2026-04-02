import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:auth/auth.dart';
import 'package:intl/intl.dart';
import '../pickups/booking_screen.dart';
import '../complaints/complaint_submission_screen.dart';
import '../rewards/rewards_screen.dart';
import '../schedule/schedule_screen.dart';
import 'home_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeState>().fetchDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final homeState = context.watch<HomeState>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GreenLoop Resident'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => context.read<AuthState>().logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => homeState.fetchDashboard(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(GLSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Points & Streak Card
              if (homeState.isLoading) const Padding(
                padding: EdgeInsets.only(bottom: GLSpacing.md),
                child: LinearProgressIndicator(),
              ),
              _buildPointsCard(context, homeState),
              const SizedBox(height: GLSpacing.xl),

              // 2. Quick Actions
              Text('Quick Actions', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: GLSpacing.md),
              _buildQuickActions(context),
              const SizedBox(height: GLSpacing.xl),

              // 3. Recent Pickups
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Pickups', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      // Navigate to full list
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: GLSpacing.sm),
              _buildRecentPickups(context, homeState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPointsCard(BuildContext context, HomeState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(GLSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(GLRadius.xl),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Balance Points',
                    style: theme.textTheme.labelLarge?.copyWith(color: colorScheme.onPrimary.withOpacity(0.8)),
                  ),
                  Text(
                    '${state.pointsBalance}',
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: GLSpacing.md, vertical: GLSpacing.sm),
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.flash_on, color: Colors.orangeAccent, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      state.streakLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: GLSpacing.lg),
          GLButton(
            text: 'Redeem Prizes',
            variant: GLButtonVariant.secondary,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RewardsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: GLSpacing.md,
      crossAxisSpacing: GLSpacing.md,
      childAspectRatio: 1.5,
      children: [
        _ActionItem(
          label: 'Book Pickup',
          icon: Icons.local_shipping_outlined,
          color: Colors.green,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingScreen())),
        ),
        _ActionItem(
          label: 'File Complaint',
          icon: Icons.report_problem_outlined,
          color: Colors.orange,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComplaintSubmissionScreen())),
        ),
        _ActionItem(
          label: 'Schedule',
          icon: Icons.calendar_today_outlined,
          color: Colors.blue,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduleScreen())),
        ),
        _ActionItem(
          label: 'History',
          icon: Icons.history_edu_outlined,
          color: Colors.purple,
          onTap: () {
             // To be implemented
          },
        ),
      ],
    );
  }

  Widget _buildRecentPickups(BuildContext context, HomeState state) {
    if (state.recentPickups.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(GLSpacing.xxl),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(GLRadius.md),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: const Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
            SizedBox(height: GLSpacing.md),
            Text('No recent pickups found', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      children: state.recentPickups.map((pickup) {
        final date = DateTime.tryParse(pickup.scheduledDate) ?? DateTime.now();
        return Card(
          margin: const EdgeInsets.only(bottom: GLSpacing.sm),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(pickup.status).withOpacity(0.1),
              child: Icon(Icons.recycling, color: _getStatusColor(pickup.status)),
            ),
            title: Text(pickup.wasteType.label),
            subtitle: Text(DateFormat('EEE, MMM d').format(date)),
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
      }).toList(),
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

class _ActionItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(GLRadius.md),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(GLRadius.md),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: GLSpacing.sm),
            Text(label, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
