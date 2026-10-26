import 'package:flutter/material.dart';

import 'design_tokens.dart';
import 'game_palette.dart';

/// Material themes for the Cambric game shell.
///
/// The game canvas keeps its own colours; this theme styles every Flutter
/// surface above it (menu, settings, saves, dialogs). Games default to dark,
/// and players can switch to light in Settings.
abstract final class GameTheme {
  static ThemeData get dark => _build(GamePalette.dark, Brightness.dark);
  static ThemeData get light => _build(GamePalette.light, Brightness.light);

  static ThemeData _build(GamePalette p, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      primaryContainer: p.primary.withValues(alpha: 0.16),
      onPrimaryContainer: p.text,
      secondary: p.accent,
      onSecondary: p.onPrimary,
      secondaryContainer: p.accent.withValues(alpha: 0.16),
      onSecondaryContainer: p.text,
      error: p.danger,
      onError: Colors.white,
      surface: p.surface,
      onSurface: p.text,
      surfaceContainerHighest: p.raised,
      onSurfaceVariant: p.secondary,
      outline: p.border,
      outlineVariant: p.border,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: p.text,
      onInverseSurface: p.bg,
      inversePrimary: p.primary,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.bg,
      // InkSparkle's shader animation never settles on CI. A standard ripple
      // is cheaper and behaves the same on desktop and Android.
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
    );

    final text = base.textTheme
        .apply(bodyColor: p.text, displayColor: p.text)
        .copyWith(
          displayLarge: TextStyle(
            color: p.text,
            fontSize: 60,
            height: 1.02,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.6,
          ),
          displayMedium: TextStyle(
            color: p.text,
            fontSize: 42,
            height: 1.05,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
          headlineMedium: TextStyle(
            color: p.text,
            fontSize: 28,
            height: 1.15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
          titleLarge: TextStyle(
            color: p.text,
            fontSize: 20,
            height: 1.2,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: TextStyle(
            color: p.text,
            fontSize: 16,
            height: 1.3,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(color: p.text, fontSize: 16, height: 1.5),
          bodyMedium: TextStyle(color: p.secondary, fontSize: 14, height: 1.5),
          bodySmall: TextStyle(color: p.muted, fontSize: 12.5, height: 1.45),
          labelLarge: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GameRadii.button),
    );
    const buttonSize = Size(0, GameSizes.buttonHeight);

    return base.copyWith(
      extensions: [p],
      textTheme: text,
      primaryTextTheme: text,
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: p.secondary, size: 20),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          disabledBackgroundColor: p.raised,
          disabledForegroundColor: p.muted,
          shape: buttonShape,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          backgroundColor: p.raised,
          foregroundColor: p.text,
          disabledBackgroundColor: p.raised,
          disabledForegroundColor: p.muted,
          side: BorderSide(color: p.border),
          shape: buttonShape,
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: buttonSize,
          foregroundColor: p.secondary,
          disabledForegroundColor: p.muted,
          shape: buttonShape,
          textStyle: text.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(GameSizes.iconButton, GameSizes.iconButton),
          foregroundColor: p.text,
          backgroundColor: p.raised,
          disabledForegroundColor: p.muted,
          side: BorderSide(color: p.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GameRadii.button),
          ),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: p.primary,
        inactiveTrackColor: p.border,
        thumbColor: p.primary,
        overlayColor: p.primary.withValues(alpha: 0.14),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.onPrimary : p.muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.primary : p.border,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.primary : p.border,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.raised,
        contentTextStyle: TextStyle(color: p.text, fontSize: 14),
        actionTextColor: p.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GameRadii.button),
          side: BorderSide(color: p.border),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: p.raised,
          border: Border.all(color: p.border),
          borderRadius: BorderRadius.circular(GameRadii.chip),
        ),
        textStyle: TextStyle(color: p.text, fontSize: 12),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.primary),
    );
  }
}
