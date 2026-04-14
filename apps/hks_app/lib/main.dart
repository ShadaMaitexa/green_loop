import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth/auth.dart';
import 'package:network/network.dart';
import 'package:core/core.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:geo/geo.dart';
import 'features/route_map/route_map_screen.dart';
import 'features/route_map/route_map_state.dart';
import 'features/attendance/attendance_dashboard.dart';
import 'features/attendance/attendance_state.dart';
import 'features/sync/sync_manager.dart';
import 'features/resources/resources_screen.dart';
import 'features/auth/hks_login_screen.dart';
import 'features/dashboard/hks_dashboard_screen.dart';

void main() {
  final environment = Environment.dev;
  final apiClient = ApiClient(environment: environment);
  final authRepository = AuthRepository(apiClient: apiClient);
  final hksRepository = HksRouteRepository(apiClient: apiClient);
  final attendanceRepository = AttendanceRepository(apiClient: apiClient);
  final complaintRepository = ComplaintRepository(apiClient: apiClient);

  runApp(
    MultiProvider(
      providers: [
        Provider<HksRouteRepository>.value(value: hksRepository),
        Provider<AttendanceRepository>.value(value: attendanceRepository),
        Provider<ComplaintRepository>.value(value: complaintRepository),
        ChangeNotifierProvider(
          create: (_) => SyncManager()
            ..initialize(
              baseUrl: environment.baseUrl,
            ),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthState(repository: authRepository)..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => RouteMapState(repository: hksRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => AttendanceState(repository: attendanceRepository),
        ),
      ],
      child: const HksApp(),
    ),
  );
}

class HksApp extends StatelessWidget {
  const HksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GreenLoop HKS',
      theme: GreenLeafTheme.light(),
      darkTheme: GreenLeafTheme.dark(),
      themeMode: ThemeMode.system,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.select<AuthState, AuthStatus>((s) => s.status);
    final user = context.select<AuthState, AuthUser?>((s) => s.user);

    switch (status) {
      case AuthStatus.initial:
      case AuthStatus.checking:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.authenticated:
        final role = user?.role.toLowerCase() ?? '';
        final isWorker = role.contains('hks') || 
                         role.contains('worker') || 
                         role.contains('staff') ||
                         role.contains('collector') ||
                         role.contains('agent') ||
                         role.contains('official') ||
                         role.contains('supervisor') ||
                         role == 'admin' ||
                         (role.isNotEmpty && role != 'resident' && role != 'recycler');

        if (user != null && !isWorker) {
          return InvalidRolePlaceholder(role: user.role);
        }
        return const HksHome();
      case AuthStatus.loading:
      case AuthStatus.unauthenticated:
      case AuthStatus.otpRequested:
      case AuthStatus.error:
        return const HksLoginScreen();
    }
  }
}

class InvalidRolePlaceholder extends StatelessWidget {
  final String role;
  const InvalidRolePlaceholder({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(GLSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_person_rounded, size: 64, color: Colors.orange),
              ),
              const SizedBox(height: GLSpacing.xl),
              Text(
                'Access Denied',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: GLSpacing.sm),
              const Text(
                'This account does not have HKS Worker permissions.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: GLSpacing.lg),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(GLRadius.md),
                ),
                child: Text(
                  'Detected Role: ${role.toUpperCase()}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.grey[700],
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: GLSpacing.xxl),
              SizedBox(
                width: 200,
                child: GLButton(
                  text: 'LOGOUT',
                  onPressed: () => context.read<AuthState>().logout(),
                ),
              ),
              const SizedBox(height: GLSpacing.md),
              TextButton(
                onPressed: () => context.read<AuthState>().initialize(),
                child: const Text('RETRY CHECK'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom-nav home for HKS workers — Route Map + Attendance tabs.
class HksHome extends StatefulWidget {
  const HksHome({super.key});

  @override
  State<HksHome> createState() => _HksHomeState();
}

class _HksHomeState extends State<HksHome> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _fetchInitialData();
  }

  void _fetchInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AttendanceState>().fetchTodayAttendance();
        context.read<RouteMapState>().fetchRoute();
      }
    });
  }

  Future<void> _requestLocationPermission() async {
    try {
      final locationService = LocationService();
      await locationService.getCurrentPosition();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable location services so residents can track the truck.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  static const _tabs = [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard_rounded),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.map_outlined),
      selectedIcon: Icon(Icons.map_rounded),
      label: 'Route',
    ),
    NavigationDestination(
      icon: Icon(Icons.badge_outlined),
      selectedIcon: Icon(Icons.badge_rounded),
      label: 'Attendance',
    ),
    NavigationDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book_rounded),
      label: 'Resources',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isWide = !GLResponsive.isMobile(context);

    return Scaffold(
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              selectedIndex: _tab,
              onDestinationSelected: (i) => setState(() => _tab = i),
              labelType: NavigationRailLabelType.all,
              destinations: _tabs
                  .map((t) => NavigationRailDestination(
                        icon: t.icon,
                        selectedIcon: t.selectedIcon,
                        label: Text(t.label),
                      ))
                  .toList(),
            ),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: const [
                HksDashboardScreen(),
                RouteMapScreen(),
                AttendanceDashboard(),
                HksResourcesScreen(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _tab,
              destinations: _tabs,
              onDestinationSelected: (i) => setState(() => _tab = i),
            ),
    );
  }
}
