import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandb_viewer/app.dart';
import 'package:wandb_viewer/providers/settings_provider.dart';

void main() {
  testWidgets('App renders and navigates to login', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
        ],
        child: const WandbViewerApp(),
      ),
    );

    expect(find.text('W&B Viewer'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
