import 'package:cambric_game/ui/screens/main_menu_screen.dart';
import 'package:cambric_game/ui/theme/game_palette.dart';
import 'package:cambric_game/ui/theme/game_theme.dart';
import 'package:cambric_game/ui/widgets/game_surfaces.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/ui_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('menu shows every action and explains a disabled Continue',
      (tester) async {
    await setSurface(tester, const Size(1280, 720));
    await loadEnglish();

    var newGame = 0;
    var continueTapped = 0;

    await tester.pumpWidget(
      wrapApp(
        MainMenuScreen(
          hasSaves: false,
          onNewGame: () => newGame++,
          onContinue: () => continueTapped++,
          onSaveFiles: () {},
          onSettings: () {},
          onQuit: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('New Game'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Save Files'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Exit'), findsOneWidget);
    expect(
      find.text('No save files yet. New Game starts a session.'),
      findsOneWidget,
    );

    final continueButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Continue'),
    );
    expect(continueButton.onPressed, isNull);

    final panel = tester.getRect(find.byType(GamePanel));
    expect(panel.left, greaterThanOrEqualTo(0));
    expect(panel.right, lessThanOrEqualTo(1280));
    expect(panel.top, greaterThanOrEqualTo(0));
    expect(panel.bottom, lessThanOrEqualTo(720));

    await tester.tap(find.text('New Game'));
    await tester.pumpAndSettle();
    expect(newGame, 1);
    expect(continueTapped, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Continue enables when a save exists', (tester) async {
    await setSurface(tester, const Size(1280, 720));
    await loadEnglish();

    var continueTapped = 0;
    await tester.pumpWidget(
      wrapApp(
        MainMenuScreen(
          hasSaves: true,
          onNewGame: () {},
          onContinue: () => continueTapped++,
          onSaveFiles: () {},
          onSettings: () {},
          onQuit: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final continueButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Continue'),
    );
    expect(continueButton.onPressed, isNotNull);
    expect(
      find.text('No save files yet. New Game starts a session.'),
      findsNothing,
    );

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(continueTapped, 1);
  });

  testWidgets('menu fits a 390 px phone without overflow', (tester) async {
    await setSurface(tester, const Size(390, 844));
    await loadEnglish();

    await tester.pumpWidget(
      wrapApp(
        MainMenuScreen(
          hasSaves: false,
          onNewGame: () {},
          onContinue: () {},
          onSaveFiles: () {},
          onSettings: () {},
          onQuit: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('New Game'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('menu renders in Arabic and right-to-left', (tester) async {
    await setSurface(tester, const Size(1280, 720));
    await loadArabic();

    await tester.pumpWidget(
      wrapApp(
        MainMenuScreen(
          hasSaves: true,
          onNewGame: () {},
          onContinue: () {},
          onSaveFiles: () {},
          onSettings: () {},
          onQuit: () {},
        ),
        direction: TextDirection.rtl,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('لعبة جديدة'), findsOneWidget);
    expect(find.text('ملفات الحفظ'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await loadEnglish();
  });

  test('both themes expose the shared palette', () {
    final dark = GameTheme.dark.extension<GamePalette>();
    final light = GameTheme.light.extension<GamePalette>();

    expect(dark, isNotNull);
    expect(light, isNotNull);
    expect(dark!.bg, const Color(0xFF0E1116));
    expect(light!.bg, const Color(0xFFF6F8FC));
    expect(dark.primary, const Color(0xFF7FA8FF));
    expect(light.primary, const Color(0xFF3B6FE0));
  });
}
