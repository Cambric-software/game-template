import 'package:cambric_game/core/localization/localization_service.dart';
import 'package:cambric_game/ui/theme/game_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> setSurface(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> loadEnglish() => LocalizationService().load('en');

Future<void> loadArabic() => LocalizationService().load('ar');

Widget wrapApp(
  Widget home, {
  ThemeData? theme,
  TextDirection direction = TextDirection.ltr,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme ?? GameTheme.dark,
    builder: (context, child) => Directionality(
      textDirection: direction,
      child: child ?? const SizedBox.shrink(),
    ),
    home: Material(
      type: MaterialType.transparency,
      child: home,
    ),
  );
}
