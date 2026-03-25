import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth/auth.dart';
import 'package:network/network.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  final environment = Environment.dev;
  final apiClient = ApiClient(environment: environment);
  final authRepository = AuthRepository(apiClient: apiClient);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthState(repository: authRepository)..initialize(),
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
      case AuthStatus.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.authenticated:
        if (user != null && user.role != 'hks') {
           // For demo, we just show a lock screen or similar if roles don't match
        }
        return const HksDashboardPlaceholder();
      case AuthStatus.unauthenticated:
      case AuthStatus.otpRequested:
      case AuthStatus.error:
        return const HksLoginPlaceholder();
    }
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
                // similar to resident_app
              },
            ),
          ],
        ),
      ),
    );
  }
}

class HksDashboardPlaceholder extends StatelessWidget {
  const HksDashboardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HKS Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => context.read<AuthState>().logout(),
          ),
        ],
      ),
      body: const Center(
        child: Text('Logged in as HKS Worker.'),
      ),
    );
  }
}
