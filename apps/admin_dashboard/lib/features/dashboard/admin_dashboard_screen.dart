import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';
import 'widgets/admin_app_bar.dart';
import 'widgets/sidebar_drawer.dart';
import '../monitoring/live_map_screen.dart';
import '../users/user_management_screen.dart';
import '../wards/ward_management_screen.dart';
import '../complaints/complaint_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final List<DashboardSection> _sections = [
    DashboardSection(title: 'Live Tracking', icon: Icons.live_tv_rounded),
    DashboardSection(title: 'Dashboard', icon: Icons.dashboard_rounded),
    DashboardSection(title: 'Users', icon: Icons.people_rounded),
    DashboardSection(title: 'Wards', icon: Icons.map_rounded),
    DashboardSection(title: 'Routes', icon: Icons.route_rounded),
    DashboardSection(title: 'Pickups', icon: Icons.local_shipping_rounded),
    DashboardSection(title: 'Complaints', icon: Icons.report_problem_rounded),
    DashboardSection(title: 'Reports', icon: Icons.analytics_rounded),
    DashboardSection(title: 'Settings', icon: Icons.settings_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final isTablet = MediaQuery.of(context).size.width >= 768;

    return Builder(
      builder: (context) => Scaffold(
        appBar: AdminAppBar(
          showMenuButton: !isTablet,
          onMenuPressed: () => Scaffold.of(context).openDrawer(),
        ),
        drawer: isTablet
            ? null
            : SidebarDrawer(
                sections: _sections,
                selectedIndex: _selectedIndex,
                onSectionSelected: (index) {
                  setState(() => _selectedIndex = index);
                  if (mounted && context.mounted) Navigator.pop(context); // Close drawer
                },
              ),
        body: Row(
          children: [
            if (isDesktop)
              Container(
                width: 280,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
                  ),
                ),
                child: SidebarDrawer(
                  sections: _sections,
                  selectedIndex: _selectedIndex,
                  onSectionSelected: (index) => setState(() => _selectedIndex = index),
                  isPersistent: true,
                ),
              )
            else if (isTablet)
              NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) => setState(() => _selectedIndex = index),
                labelType: NavigationRailLabelType.selected,
                destinations: _sections
                    .map((s) => NavigationRailDestination(
                          icon: Icon(s.icon),
                          label: Text(s.title),
                        ))
                    .toList(),
              ),
            Expanded(
              child: Container(
                color: theme.scaffoldBackgroundColor.withOpacity(0.95),
                child: _buildSectionContent(_sections[_selectedIndex]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContent(DashboardSection section) {
    if (section.title == 'Live Tracking') {
      return const LiveMapScreen();
    }
    if (section.title == 'Users') {
      return const UserManagementScreen();
    }
    if (section.title == 'Wards') {
      return const WardManagementScreen();
    }
    if (section.title == 'Complaints') {
      return const ComplaintManagementScreen();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(GLSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: GLSpacing.xs),
              Text(
                'Manage your ${section.title.toLowerCase()} here',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Center(
            child: Text(
              '${section.title} Content coming soon...',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
      ],
    );
  }
}

class DashboardSection {
  final String title;
  final IconData icon;

  DashboardSection({required this.title, required this.icon});
}
