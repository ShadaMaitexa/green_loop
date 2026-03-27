import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:auth/auth.dart';
import 'package:network/network.dart';
import 'package:ui_kit/ui_kit.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/recycler_state.dart';

void main() {
  final environment = Environment.dev;
  final apiClient = ApiClient(environment: environment);
  final authRepository = AuthRepository(apiClient: apiClient);
  final recyclerRepository = RecyclerRepository(apiClient: apiClient);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthState(repository: authRepository)..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => RecyclerState(repository: recyclerRepository),
        ),
        Provider<RecyclerRepository>.value(value: recyclerRepository),
      ],
      child: const RecyclerApp(),
    ),
  );
}

class RecyclerApp extends StatelessWidget {
  const RecyclerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GreenLoop Recycler',
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
        if (user != null && user.role != 'recycler') {
          return const InvalidRolePlaceholder();
        }
        return const RecyclerDashboardScreen();
      case AuthStatus.unauthenticated:
      case AuthStatus.otpRequested:
      case AuthStatus.error:
        // Reuse login screen - but usually for recyclers it's same portal
        return const LoginScreen(); 
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
            const Icon(Icons.lock_rounded, size: 64, color: Colors.orange),
            const SizedBox(height: GLSpacing.md),
            const Text('Access Denied. Recycler account required.'),
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

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recycler Login')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(GLSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.recycling_rounded, size: 64, color: Colors.green),
              const SizedBox(height: GLSpacing.lg),
              const Text('Welcome to GreenLoop Recycler', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: GLSpacing.xxl),
              GLButton(
                text: 'Login with OTP',
                onPressed: () {
                  // Navigation simulation
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login logic shared with auth module.')));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
