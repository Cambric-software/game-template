import 'package:cambric_game/core/localization/localization_service.dart';
import 'package:cambric_game/settings/settings_service.dart';
import 'package:cambric_game/ui/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/ui_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SettingsService settings;
  late LocalizationService l10n;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = SettingsService();
    await settings.initialize();
    await settings.resetToDefaults();
    l10n = LocalizationService();
    await l10n.load('en');
  });

  tearDown(() async {
    await l10n.load('en');
    await settings.resetToDefaults();
  });

  testWidgets('settings persist theme and language choices', (tester) async {
    await setSurface(tester, const Size(1280, 720));

    String? theme;
    var languageChanges = 0;

    await tester.pumpWidget(
      wrapApp(
        SettingsScreen(
          settings: settings,
          l10n: l10n,
          onThemeChanged: (value) => theme = value,
          onLanguageChanged: (value) async {
            languageChanges++;
            await l10n.load(value);
          },
          onBack: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AUDIO'), findsOneWidget);
    expect(find.text('INTERFACE'), findsOneWidget);
    expect(find.text('ABOUT'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('العربية'), findsOneWidget);

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(theme, 'light');
    expect(settings.uiTheme, 'light');

    await tester.tap(find.text('العربية'));
    await tester.pumpAndSettle();
    expect(languageChanges, 1);
    expect(settings.language, 'ar');
    expect(l10n.currentLocale, 'ar');
    expect(find.text('الواجهة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings fit a phone and scroll', (tester) async {
    await setSurface(tester, const Size(390, 844));

    await tester.pumpWidget(
      wrapApp(
        SettingsScreen(
          settings: settings,
          l10n: l10n,
          onThemeChanged: (_) {},
          onLanguageChanged: (value) => l10n.load(value),
          onBack: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AUDIO'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Reset to Defaults'), 200);
    expect(find.text('Reset to Defaults'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
