import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Abstracts platform-specific behavior.
///
/// Game code must never call [Platform.isAndroid] or similar
/// directly — use this service so platform logic is centralized
/// and testable.
class PlatformService {
  static final PlatformService _instance = PlatformService._internal();
  factory PlatformService() => _instance;
  PlatformService._internal();

  // ── Platform detection ─────────────────────────────────────────────────
  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool get isWindows => !kIsWeb && Platform.isWindows;
  bool get isLinux => !kIsWeb && Platform.isLinux;
  bool get isMacOS => !kIsWeb && Platform.isMacOS;
  bool get isWeb => kIsWeb;
  bool get isDesktop => isWindows || isLinux || isMacOS;
  bool get isMobile => isAndroid;

  /// Human-readable platform name for diagnostics.
  String get platformName {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    if (Platform.isMacOS) return 'macos';
    return 'unknown';
  }

  // ── Paths ──────────────────────────────────────────────────────────────

  /// Returns the application data directory for the given game ID.
  /// Structure: <appDocuments>/Cambric/Games/<gameId>
  Future<Directory> getGameDataDirectory(String gameId) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/Cambric/Games/$gameId');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Returns a named subdirectory under the game data directory.
  Future<Directory> getGameSubDirectory(String gameId, String sub) async {
    final base = await getGameDataDirectory(gameId);
    final dir = Directory('${base.path}/$sub');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> getSavesDirectory(String gameId) =>
      getGameSubDirectory(gameId, 'saves');

  Future<Directory> getSettingsDirectory(String gameId) =>
      getGameSubDirectory(gameId, 'settings');

  Future<Directory> getCacheDirectory(String gameId) =>
      getGameSubDirectory(gameId, 'cache');

  Future<Directory> getLogsDirectory(String gameId) =>
      getGameSubDirectory(gameId, 'logs');

  Future<Directory> getBackupsDirectory(String gameId) =>
      getGameSubDirectory(gameId, 'backups');

  Future<Directory> getUpdatesDirectory(String gameId) =>
      getGameSubDirectory(gameId, 'updates');

  Future<Directory> getTempDirectory() async =>
      getTemporaryDirectory();

  // ── Capabilities ───────────────────────────────────────────────────────

  /// Whether the platform supports physical keyboard input.
  bool get supportsKeyboard => isDesktop;

  /// Whether the platform supports mouse input.
  bool get supportsMouse => isDesktop;

  /// Whether the platform supports touch input.
  bool get supportsTouch => isMobile;

  /// Whether atomic file rename is available (true on all supported platforms).
  bool get supportsAtomicRename => true;

  /// Returns OS version string for diagnostics.
  String get osVersion {
    if (kIsWeb) return 'web';
    return Platform.operatingSystemVersion;
  }
}
