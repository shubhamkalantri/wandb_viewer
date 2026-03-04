import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wandb_viewer/screens/login/login_screen.dart';

void main() {
  testWidgets('LoginScreen shows API key input and login button',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('W&B Viewer'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('Login button is disabled when API key is empty',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('Login button is enabled when API key is entered',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.enterText(find.byType(TextField), 'test-api-key');
    await tester.pump();

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
  });
}
