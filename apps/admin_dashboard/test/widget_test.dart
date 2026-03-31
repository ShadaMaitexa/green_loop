import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:auth/auth.dart';
import 'package:network/network.dart';

import 'package:admin_dashboard/main.dart';

void main() {
  testWidgets('App initialization smoke test', (WidgetTester tester) async {
    final environment = Environment.dev;
    final apiClient = ApiClient(environment: environment);
    final authRepository = AuthRepository(apiClient: apiClient);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: authRepository),
          ChangeNotifierProvider(
            create: (_) => AuthState(repository: authRepository),
          ),
        ],
        child: const AdminApp(),
      ),
    );

    // Verify that we start with a loading indicator (AuthStatus.initial)
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
