import 'package:flutter/material.dart';

/// Colours for the Cambric game interface.
///
/// These are the same values as the app and web templates, so a player
/// moving between Cambric products sees one family of surfaces, borders
/// and accents. Do not introduce a colour outside this file; add a token.
@immutable
class GamePalette extends ThemeExtension<GamePalette> {
  const GamePalette({
    required this.bg,
    required this.surface,
    required this.raised,
    required this.border,
    required this.text,
    required this.secondary,
    required this.muted,
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.success,
    required this.warning,
    required this.danger,
  });

  final Color bg;
  final Color surface;
  final Color raised;
  final Color border;
  final Color text;
  final Color secondary;
  final Color muted;
  final Color primary;
  final Color onPrimary;
  final Color accent;
  final Color success;
  final Color warning;
  final Color danger;

  static const GamePalette dark = GamePalette(
    bg: Color(0xFF0E1116),
    surface: Color(0xFF161B23),
    raised: Color(0xFF1D232D),
    border: Color(0xFF262E3A),
    text: Color(0xFFEDF0F6),
    secondary: Color(0xFFA8B2C6),
    muted: Color(0xFF737E92),
    primary: Color(0xFF7FA8FF),
    onPrimary: Color(0xFF071226),
    accent: Color(0xFF35D0BC),
    success: Color(0xFF43C79A),
    warning: Color(0xFFE8A33C),
    danger: Color(0xFFF0736B),
  );

  static const GamePalette light = GamePalette(
    bg: Color(0xFFF6F8FC),
    surface: Color(0xFFFFFFFF),
    raised: Color(0xFFFAFBFE),
    border: Color(0xFFE2E6EF),
    text: Color(0xFF101828),
    secondary: Color(0xFF5A6478),
    muted: Color(0xFF8A94A6),
    primary: Color(0xFF3B6FE0),
    onPrimary: Color(0xFFFFFFFF),
    accent: Color(0xFF12A594),
    success: Color(0xFF12855F),
    warning: Color(0xFFB26A00),
    danger: Color(0xFFC63A34),
  );

  bool get isDark => bg.computeLuminance() < 0.2;

  @override
  GamePalette copyWith({
    Color? bg,
    Color? surface,
    Color? raised,
    Color? border,
    Color? text,
    Color? secondary,
    Color? muted,
    Color? primary,
    Color? onPrimary,
    Color? accent,
    Color? success,
    Color? warning,
    Color? danger,
  }) {
    return GamePalette(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      raised: raised ?? this.raised,
      border: border ?? this.border,
      text: text ?? this.text,
      secondary: secondary ?? this.secondary,
      muted: muted ?? this.muted,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      accent: accent ?? this.accent,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
    );
  }

  @override
  GamePalette lerp(covariant GamePalette? other, double t) {
    if (other == null) return this;
    return GamePalette(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      raised: Color.lerp(raised, other.raised, t)!,
      border: Color.lerp(border, other.border, t)!,
      text: Color.lerp(text, other.text, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

extension GamePaletteContext on BuildContext {
  /// The active palette. Falls back to dark so a missing extension
  /// never produces an invisible interface during development.
  GamePalette get palette =>
      Theme.of(this).extension<GamePalette>() ?? GamePalette.dark;
}
