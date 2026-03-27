import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:auth/auth.dart';
import 'package:network/network.dart';
import 'package:ui_kit/ui_kit.dart';
import 'features/auth/login_screen.dart';
import 'features/profile_setup/profile_setup_screen.dart';
import 'features/pickups/booking_screen.dart';
import 'features/complaints/complaint_submission_screen.dart';
import 'features/schedule/schedule_screen.dart';
import 'features/rewards/rewards_screen.dart';
import 'features/rewards/rewards_state.dart';

void main() {
  final environment = Environment.dev;
  final apiClient = ApiClient(environment: environment);
  final authRepository = AuthRepository(apiClient: apiClient);
  final pickupRepository = PickupRepository(apiClient: apiClient);
  final complaintRepository = ComplaintRepository(apiClient: apiClient);
  final scheduleRepository = ScheduleRepository(apiClient: apiClient);
  final rewardRepository = RewardRepository(apiClient: apiClient);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthState(repository: authRepository)..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => RewardsState(repository: rewardRepository),
        ),
        Provider<PickupRepository>.value(value: pickupRepository),
        Provider<ComplaintRepository>.value(value: complaintRepository),
        Provider<ScheduleRepository>.value(value: scheduleRepository),
        Provider<RewardRepository>.value(value: rewardRepository),
      ],
      child: const ResidentApp(),
    ),
  );
}

class ResidentApp extends StatelessWidget {
  const ResidentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GreenLoop Resident',
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
      case AuthStatus.loading:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.authenticated:
        if (user != null && !user.isProfileCompleted) {
          return const ProfileSetupScreen();
        }
        return const HomeScreenPlaceholder();
      case AuthStatus.unauthenticated:
      case AuthStatus.otpRequested:
      case AuthStatus.error:
        return const LoginScreen();
    }
  }
}

class HomeScreenPlaceholder extends StatelessWidget {
  const HomeScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthState, AuthUser?>((s) => s.user);

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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(GLSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.dashboard_outlined, size: 64, color: Colors.green),
              const SizedBox(height: GLSpacing.lg),
              Text(
                'Welcome, ${user?.email ?? "Resident"}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: GLSpacing.md),
              const Text('Welcome to GreenLoop!'),
              const SizedBox(height: GLSpacing.xl),
              GLButton(
                text: 'Book a Pickup',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BookingScreen()),
                ),
              ),
              const SizedBox(height: GLSpacing.md),
              GLButton(
                text: 'File a Complaint',
                variant: GLButtonVariant.outline,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ComplaintSubmissionScreen()),
                ),
              ),
              const SizedBox(height: GLSpacing.md),
              GLButton(
                text: 'Weekly Schedule',
                variant: GLButtonVariant.outline,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScheduleScreen()),
                ),
              ),
              const SizedBox(height: GLSpacing.md),
              GLButton(
                text: 'Rewards & Points',
                variant: GLButtonVariant.outline,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RewardsScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
