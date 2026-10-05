import 'dart:convert';
import 'dart:io';

import '../logging/logging_service.dart';

final _log = gameLogger('ConfigurationService');

/// Central game configuration loaded from cambric.manifest.json.
///
/// This is build/developer configuration — NOT player settings.
/// Player settings live in SettingsService.
class ConfigurationService {
  factory ConfigurationService() => _instance;
  ConfigurationService._internal();

  static final ConfigurationService _instance =
      ConfigurationService._internal();

  Map<String, dynamic> _manifest = {};
  bool _loaded = false;

  // ── Game configuration ─────────────────────────────────────────────────
  String get gameName => _get<String>('product.name', 'Cambric Game');
  String get gameId => _get<String>('product.id', 'cambric-game');
  String get gameVersion => _get<String>('product.version', '0.1.0');
  String get releaseChannel =>
      _get<String>('product.releaseChannel', 'stable');
  String get repository => _get<String>('product.repository', '');

  List<String> get supportedPlatforms =>
      List<String>.from(_manifest['platforms'] as List? ?? []);

  List<String> get supportedLocales =>
      List<String>.from(_manifest['locales'] as List? ?? ['en']);

  String get gameType => _get<String>('gameType', '2d');
  String get orientation => _get<String>('orientation', 'landscape');

  // ── Capabilities ───────────────────────────────────────────────────────
  Map<String, dynamic> get capabilities =>
      Map<String, dynamic>.from(
        _manifest['capabilities'] as Map? ?? {},
      );

  bool get offlineCapable => capabilities['offline'] as bool? ?? true;
  bool get touchCapable => capabilities['touch'] as bool? ?? true;
  bool get keyboardCapable => capabilities['keyboard'] as bool? ?? true;
  bool get mouseCapable => capabilities['mouse'] as bool? ?? true;
  bool get gamepadCapable => capabilities['gamepad'] as bool? ?? true;

  bool get isLoaded => _loaded;

  // ── Load ───────────────────────────────────────────────────────────────

  Future<void> loadFromManifest(String manifestJson) async {
    try {
      _manifest = jsonDecode(manifestJson) as Map<String, dynamic>;
      _loaded = true;
      _log.info('Configuration loaded: $gameName v$gameVersion');
    } catch (e, st) {
      _log.severe('Failed to parse manifest', e, st);
    }
  }

  Future<void> loadFromFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        _log.warning('Manifest not found at $path, using defaults');
        return;
      }
      final content = await file.readAsString();
      await loadFromManifest(content);
    } catch (e, st) {
      _log.severe('Failed to load manifest from file', e, st);
    }
  }

  // ── Typed getter ───────────────────────────────────────────────────────
  T _get<T>(String dotPath, T defaultValue) {
    final parts = dotPath.split('.');
    dynamic current = _manifest;
    for (final part in parts) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return defaultValue;
      }
    }
    return current is T ? current : defaultValue;
  }
}
