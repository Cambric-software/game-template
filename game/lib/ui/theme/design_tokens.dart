/// Spacing, radii and sizing shared by every Cambric game interface.
///
/// The values match the app and web templates. Use them instead of
/// inventing one-off numbers so screens stay visually consistent.
abstract final class GameSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

abstract final class GameRadii {
  static const double chip = 6;
  static const double input = 8;
  static const double button = 11;
  static const double card = 14;
  static const double panel = 20;
  static const double sheet = 28;
}

abstract final class GameSizes {
  /// Minimum tappable control. Games run on phones as well as desktops.
  static const double touchTarget = 48;
  static const double buttonHeight = 48;
  static const double iconButton = 44;
  static const double menuPanel = 360;
  static const double content = 1080;
  static const double reading = 760;
  static const double dialog = 460;
}

abstract final class GameBreakpoints {
  static const double compact = 620;
  static const double wide = 940;
}
