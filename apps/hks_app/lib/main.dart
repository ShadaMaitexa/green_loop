import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth/auth.dart';
import 'package:network/network.dart';
import 'package:core/core.dart';
import 'package:ui_kit/ui_kit.dart';
import 'features/route_map/route_map_screen.dart';
import 'features/route_map/route_map_state.dart';
import 'features/attendance/attendance_dashboard.dart';
import 'features/attendance/attendance_state.dart';
import 'features/sync/sync_manager.dart';
import 'features/resources/resources_screen.dart';

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
        if (user != null && user.role != 'hks') {
          // For demo, we just show a lock screen or similar if roles don't match
        }
        return const HksHome();
      case AuthStatus.loading:
      case AuthStatus.unauthenticated:
      case AuthStatus.otpRequested:
      case AuthStatus.error:
        return const HksLoginPlaceholder();
    }
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

  static const _tabs = [
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
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [
          RouteMapScreen(),
          AttendanceDashboard(),
          HksResourcesScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        destinations: _tabs,
        onDestinationSelected: (i) => setState(() => _tab = i),
      ),
    );
  }
}

class HksLoginPlaceholder extends StatelessWidget {
  const HksLoginPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cleaning_services_rounded, size: 64, color: Colors.green),
            const SizedBox(height: GLSpacing.md),
            const Text('HKS Worker Login'),
            const SizedBox(height: GLSpacing.lg),
            GLButton(
              text: 'Request OTP (Email)',
              onPressed: () {
                // In a full implementation, this uses the OTP flow
              },
            ),
          ],
        ),
      ),
    );
  }
}
