import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth/auth.dart';
import 'package:network/network.dart';
import 'package:ui_kit/ui_kit.dart';
import 'features/auth/admin_login_screen.dart';
import 'features/dashboard/admin_dashboard_screen.dart';
import 'features/monitoring/monitoring_service.dart';
import 'features/monitoring/monitoring_state.dart';
import 'features/users/user_management_service.dart';
import 'features/users/user_management_state.dart';
import 'features/wards/ward_service.dart';
import 'features/wards/ward_state.dart';
import 'features/complaints/complaint_service.dart';
import 'features/complaints/complaint_state.dart';
import 'features/dashboard/dashboard_service.dart';
import 'features/dashboard/dashboard_state.dart';
import 'package:core/core.dart';
import 'features/rewards/reward_settings_state.dart';
import 'features/reports/reports_service.dart';
import 'features/reports/reports_state.dart';
import 'features/attendance/attendance_service.dart';
import 'features/attendance/attendance_state.dart';
import 'features/pickup_slots/pickup_slots_service.dart';
import 'features/pickup_slots/pickup_slots_state.dart';
import 'features/payments/payment_service.dart';
import 'features/payments/payment_state.dart';
import 'features/pickups/pickup_service.dart';
import 'features/pickups/pickup_state.dart';

void main() {
  final environment = Environment.dev;
  final apiClient = ApiClient(environment: environment);
  final authRepository = AuthRepository(apiClient: apiClient);

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: authRepository),
        ChangeNotifierProvider(
          create: (_) => AuthState(repository: authRepository)..initialize(),
        ),
        Provider(create: (_) => MonitoringService(apiClient: apiClient)),
        ChangeNotifierProvider(
          create: (context) => MonitoringState(
            service: context.read<MonitoringService>(),
          )..initializeMap(),
        ),
        Provider(create: (_) => UserManagementService(apiClient: apiClient)),
        ChangeNotifierProvider(
          create: (context) => UserManagementState(
            service: context.read<UserManagementService>(),
          ),
        ),
        Provider(create: (_) => WardService(apiClient: apiClient)),
        ChangeNotifierProvider(
          create: (context) => WardState(
            service: context.read<WardService>(),
          ),
        ),
        Provider(create: (_) => ComplaintService(apiClient: apiClient)),
        ChangeNotifierProvider(
          create: (context) => ComplaintState(
            service: context.read<ComplaintService>(),
          ),
        ),
        Provider(create: (_) => AttendanceService(apiClient: apiClient)),
        ChangeNotifierProvider(
          create: (context) => AttendanceState(
            service: context.read<AttendanceService>(),
          ),
        ),
        Provider(create: (_) => PickupSlotsService(apiClient: apiClient)),
        ChangeNotifierProvider(
          create: (context) => PickupSlotsState(
            service: context.read<PickupSlotsService>(),
          ),
        ),
        Provider(create: (_) => PaymentService(apiClient: apiClient)),
        ChangeNotifierProvider(
          create: (context) => PaymentState(
            service: context.read<PaymentService>(),
          ),
        ),
        Provider(create: (_) => DashboardService(apiClient: apiClient)),
        ChangeNotifierProvider(
          create: (context) => DashboardState(
            service: context.read<DashboardService>(),
          ),
        ),
        Provider(create: (_) => RewardRepository(apiClient: apiClient)),
        ChangeNotifierProvider(
          create: (context) => RewardSettingsState(
            repository: context.read<RewardRepository>(),
          ),
        ),
        Provider(create: (_) => ReportsService(apiClient: apiClient)),
        ChangeNotifierProvider(
          create: (context) => ReportsState(
            service: context.read<ReportsService>(),
          ),
        ),
        Provider(create: (_) => PickupService(apiClient: apiClient)),
        ChangeNotifierProvider(
          create: (context) => PickupState(
            service: context.read<PickupService>(),
          ),
        ),
      ],
      child: const AdminApp(),
    ),
  );
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GreenLoop Admin',
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

    switch (status) {
      case AuthStatus.initial:
      case AuthStatus.checking:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.authenticated:
        return const AdminDashboardScreen();
      case AuthStatus.loading:
      case AuthStatus.unauthenticated:
      case AuthStatus.otpRequested:
      case AuthStatus.error:
        return const AdminLoginScreen();
    }
  }
}

class InvalidRolePlaceholder extends StatelessWidget {
  const InvalidRolePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_rounded, size: 64, color: Colors.red),
            const SizedBox(height: GLSpacing.md),
            const Text('Access Denied. Admin privileges required.'),
            const SizedBox(height: GLSpacing.lg),
            GLButton(
              text: 'Logout',
              onPressed: () => context.read<AuthState>().logout(),
            ),
          ],
        ),
      ),
    );
  }
}
