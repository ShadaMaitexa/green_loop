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
import 'features/nps/nps_service.dart';
import 'features/nps/nps_state.dart';
import 'features/nps/nps_bottom_sheet.dart';

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
        ChangeNotifierProvider(
          create: (_) => AuthState(repository: authRepository)..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => RewardsState(repository: rewardRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => NpsState(service: npsService),
        ),
        Provider<PickupRepository>.value(value: pickupRepository),
        Provider<ComplaintRepository>.value(value: complaintRepository),
        Provider<ScheduleRepository>.value(value: scheduleRepository),
        Provider<RewardRepository>.value(value: rewardRepository),
        Provider<NpsService>.value(value: npsService),
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
        return const HomeScreenPlaceholder();
      case AuthStatus.loading:
      case AuthStatus.unauthenticated:
      case AuthStatus.otpRequested:
      case AuthStatus.error:
        return const LoginScreen();
    }
  }
}

class HomeScreenPlaceholder extends StatefulWidget {
  const HomeScreenPlaceholder({super.key});

  @override
  State<HomeScreenPlaceholder> createState() => _HomeScreenPlaceholderState();
}

class _HomeScreenPlaceholderState extends State<HomeScreenPlaceholder> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNps();
    });
  }

  Future<void> _checkNps() async {
    final npsState = context.read<NpsState>();
    await npsState.checkEligibility();
    
    if (npsState.isEligible && mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => const NpsBottomSheet(),
      );
      npsState.markAsShown();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthState, AuthUser?>((s) => s.user);
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(GLSpacing.xl),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
                const SizedBox(height: GLSpacing.xl),
                const Icon(Icons.dashboard_outlined, size: 64, color: Colors.green),
                const SizedBox(height: GLSpacing.lg),
                Text(
                  'Welcome, ${user?.email ?? "Resident"}',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: GLSpacing.md),
                const Text('What would you like to do today?'),
                const SizedBox(height: GLSpacing.xxl),
                
                // Responsive Grid/List of actions
                GLResponsive(
                  mobile: Column(
                    children: _buildActions(context),
                  ),
                  desktop: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: GLSpacing.lg,
                    crossAxisSpacing: GLSpacing.lg,
                    childAspectRatio: 3,
                    children: _buildActions(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    return [
      GLButton(
        text: 'Book a Pickup',
        icon: Icons.local_shipping_rounded,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BookingScreen()),
        ),
      ),
      if (GLResponsive.isMobile(context)) const SizedBox(height: GLSpacing.md),
      GLButton(
        text: 'File a Complaint',
        icon: Icons.report_problem_rounded,
        variant: GLButtonVariant.outline,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ComplaintSubmissionScreen()),
        ),
      ),
      if (GLResponsive.isMobile(context)) const SizedBox(height: GLSpacing.md),
      GLButton(
        text: 'Weekly Schedule',
        icon: Icons.calendar_month_rounded,
        variant: GLButtonVariant.outline,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ScheduleScreen()),
        ),
      ),
      if (GLResponsive.isMobile(context)) const SizedBox(height: GLSpacing.md),
      GLButton(
        text: 'Rewards & Points',
        icon: Icons.stars_rounded,
        variant: GLButtonVariant.outline,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RewardsScreen()),
        ),
      ),
    ];
  }
}
