import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth/auth.dart';
import 'package:ui_kit/ui_kit.dart';
import '../route_map/route_map_state.dart';
import '../attendance/attendance_state.dart';
import '../sync/sync_status_badge.dart';
import '../attendance/attendance_dashboard.dart';
import '../attendance/attendance_history_screen.dart';
import '../route_map/route_map_screen.dart';
import '../issues/hks_issue_list_screen.dart';
import '../fee_collection/fee_summary_screen.dart';

class HksDashboardScreen extends StatelessWidget {
  const HksDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();
    final routeState = context.watch<RouteMapState>();
    final attendanceState = context.watch<AttendanceState>();
    final theme = Theme.of(context);
    final user = authState.user;

    final route = routeState.route;
    final totalPickups = route?.pickups.length ?? 0;
    final completedPickups = route?.pickups.where((p) => p.isCompleted).length ?? 0;

    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000), // Optimal width for readability
          child: CustomScrollView(
            slivers: [
              SliverAppBar.large(
                title: const Text('GreenLoop HKS'),
                centerTitle: GLResponsive.isMobile(context),
                actions: [
                  const SyncStatusBadge(),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded),
                    onPressed: () => context.read<AuthState>().logout(),
                    tooltip: 'Logout',
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: GLResponsive.isMobile(context) ? GLSpacing.lg : GLSpacing.xl,
                  vertical: GLSpacing.lg,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       _buildWelcomeHeader(context, user?.name ?? 'Worker'),
                       const SizedBox(height: GLSpacing.xl),
                       _buildAttendanceSummary(context, attendanceState),
                       const SizedBox(height: GLSpacing.xl),
                       Text(
                         'Today\'s Progress',
                         style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                       ),
                       const SizedBox(height: GLSpacing.md),
                       _buildProgressGrid(context, totalPickups, completedPickups),
                       const SizedBox(height: GLSpacing.xl),
                       _buildQuickActions(context),
                       const SizedBox(height: GLSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, String name) {
    final theme = Theme.of(context);
    final isMobile = GLResponsive.isMobile(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good morning,',
          style: (isMobile ? theme.textTheme.bodyLarge : theme.textTheme.headlineSmall)
              ?.copyWith(color: Colors.grey),
        ),
        Text(
          name,
          style: (isMobile ? theme.textTheme.headlineMedium : theme.textTheme.headlineLarge)
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildAttendanceSummary(BuildContext context, AttendanceState state) {
    final theme = Theme.of(context);
    final isIn = state.today?.isCheckedIn ?? false;
    final isMobile = GLResponsive.isMobile(context);

    return Container(
      padding: const EdgeInsets.all(GLSpacing.lg),
      decoration: BoxDecoration(
        color: isIn ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(GLRadius.lg),
        border: Border.all(
          color: isIn ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
        ),
      ),
      child: isMobile && !isIn 
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 32,
                  ),
                  const SizedBox(width: GLSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attendance Required',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Please log your attendance to start receiving requests.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GLSpacing.md),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.orange.withValues(alpha: 0.1),
                  ),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceDashboard()));
                  },
                  child: const Text('LOG NOW'),
                ),
              ),
            ],
          )
        : Row(
            children: [
              Icon(
                isIn ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                color: isIn ? Colors.green : Colors.orange,
                size: 32,
              ),
              const SizedBox(width: GLSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isIn ? 'Shift Active' : 'Attendance Required',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      isIn 
                        ? 'Check-in confirmed at ${state.today?.checkInTime ?? "N/A"}'
                        : 'Please log your attendance to start receiving requests.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (!isIn)
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceDashboard()));
                  },
                  child: const Text('LOG NOW'),
                ),
            ],
          ),
    );
  }

  Widget _buildProgressGrid(BuildContext context, int total, int completed) {
    final isMobile = GLResponsive.isMobile(context);
    
    final pickupCard = _buildProgressCard(
      context,
      'Pickups',
      '$completed/$total',
      completed / (total > 0 ? total : 1),
      Colors.blue,
    );
    
    final collectionsCard = _buildProgressCard(
      context,
      'Collections',
      '₹ 1,240', // Hardcoded for demo
      0.7,
      Colors.green,
    );

    if (isMobile) {
      return Column(
        children: [
          pickupCard,
          const SizedBox(height: GLSpacing.md),
          collectionsCard,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: pickupCard),
        const SizedBox(width: GLSpacing.md),
        Expanded(child: collectionsCard),
      ],
    );
  }

  Widget _buildProgressCard(
    BuildContext context, 
    String label, 
    String value, 
    double progress, 
    Color color
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(GLSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(GLRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: GLSpacing.md),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withValues(alpha: 0.1),
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = GLResponsive.isMobile(context);

    final actionItems = [
      _buildActionItem(context, Icons.map_rounded, 'View Route', Colors.blue, onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const RouteMapScreen()));
      }),
      _buildActionItem(context, Icons.report_problem_rounded, 'Report Issue', Colors.orange, onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const HksIssueListScreen()));
      }),
      _buildActionItem(context, Icons.account_balance_wallet_rounded, 'Collections', Colors.purple, onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const FeeSummaryScreen()));
      }),
      _buildActionItem(context, Icons.history_rounded, 'History', Colors.teal, onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceHistoryScreen()));
      }),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: GLSpacing.md),
        if (isMobile)
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: actionItems,
            ),
          )
        else
          Wrap(
            spacing: GLSpacing.xl,
            runSpacing: GLSpacing.xl,
            children: actionItems,
          ),
      ],
    );
  }

  Widget _buildActionItem(BuildContext context, IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: GLSpacing.md),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label, 
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
