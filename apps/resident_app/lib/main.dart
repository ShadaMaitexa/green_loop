import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:auth/auth.dart';
import 'package:network/network.dart';
import 'package:ui_kit/ui_kit.dart';
import 'features/auth/login_screen.dart';
import 'features/profile_setup/profile_setup_screen.dart';
import 'features/nps/nps_service.dart';
import 'features/nps/nps_state.dart';
import 'features/home/home_screen.dart';
import 'features/home/home_state.dart';
import 'features/rewards/rewards_state.dart';

void main() {
  final environment = Environment.dev;
  final apiClient = ApiClient(environment: environment);
  final authRepository = AuthRepository(apiClient: apiClient);
  final pickupRepository = PickupRepository(apiClient: apiClient);
  final complaintRepository = ComplaintRepository(apiClient: apiClient);
  final scheduleRepository = ScheduleRepository(apiClient: apiClient);
  final rewardRepository = RewardRepository(apiClient: apiClient);
  final npsService = NpsService(apiClient: apiClient);

  runApp(
    MultiProvider(
      providers: [
        Provider<PickupRepository>.value(value: pickupRepository),
        Provider<ComplaintRepository>.value(value: complaintRepository),
        Provider<ScheduleRepository>.value(value: scheduleRepository),
        Provider<RewardRepository>.value(value: rewardRepository),
        Provider<NpsService>.value(value: npsService),
        ChangeNotifierProvider(
          create: (_) => AuthState(repository: authRepository)..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => HomeState(
            pickupRepository: pickupRepository,
            rewardRepository: rewardRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => RewardsState(repository: rewardRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => NpsState(service: npsService),
        ),
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
      case AuthStatus.checking:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.authenticated:
        if (user != null && !user.isProfileCompleted) {
          return const ProfileSetupScreen();
        }
        return const HomeScreen();
      case AuthStatus.loading:
      case AuthStatus.unauthenticated:
      case AuthStatus.otpRequested:
      case AuthStatus.error:
        return const LoginScreen();
    }
  }
}

