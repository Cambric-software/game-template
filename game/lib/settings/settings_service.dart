import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/logging/logging_service.dart';

final _log = gameLogger('SettingsService');

/// Player-facing game settings, persisted locally via SharedPreferences.
///
/// Settings are separated from:
///   - game configuration (build-time, in ConfigurationService)
///   - save data (game progress, in SaveService)
///
/// These are player preferences that persist across play sessions.
class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _log.info('Settings loaded');
  }

  SharedPreferences get _p {
    assert(_prefs != null, 'SettingsService not initialized');
    return _prefs!;
  }

  // ── Audio ──────────────────────────────────────────────────────────────
  double get masterVolume => _p.getDouble('audio.masterVolume') ?? 1.0;
  set masterVolume(double v) =>
      _p.setDouble('audio.masterVolume', v.clamp(0, 1));

  double get musicVolume => _p.getDouble('audio.musicVolume') ?? 0.8;
  set musicVolume(double v) =>
      _p.setDouble('audio.musicVolume', v.clamp(0, 1));

  double get sfxVolume => _p.getDouble('audio.sfxVolume') ?? 1.0;
  set sfxVolume(double v) => _p.setDouble('audio.sfxVolume', v.clamp(0, 1));

  bool get audioMuted => _p.getBool('audio.muted') ?? false;
  set audioMuted(bool v) => _p.setBool('audio.muted', v);

  // ── Graphics ──────────────────────────────────────────────────────────
  bool get fullscreen => _p.getBool('graphics.fullscreen') ?? false;
  set fullscreen(bool v) => _p.setBool('graphics.fullscreen', v);

  bool get showFps => _p.getBool('graphics.showFps') ?? false;
  set showFps(bool v) => _p.setBool('graphics.showFps', v);

  String get qualityPreset =>
      _p.getString('graphics.qualityPreset') ?? 'high';
  set qualityPreset(String v) => _p.setString('graphics.qualityPreset', v);

  // ── Controls ──────────────────────────────────────────────────────────
  Map<String, String> getInputBindings() {
    final json = _p.getString('controls.bindings');
    if (json == null) return {};
    try {
      final raw = jsonDecode(json);
      if (raw is Map) {
        return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    } catch (_) {}
    return {};
  }

  Future<void> saveInputBindings(Map<String, String> bindings) async {
    await _p.setString('controls.bindings', jsonEncode(bindings));
  }

  // ── Language ──────────────────────────────────────────────────────────
  String get language => _p.getString('language') ?? 'en';
  set language(String v) => _p.setString('language', v);

  // ── Gameplay ──────────────────────────────────────────────────────────
  String get difficulty => _p.getString('gameplay.difficulty') ?? 'normal';
  set difficulty(String v) => _p.setString('gameplay.difficulty', v);

  bool get autosaveEnabled => _p.getBool('gameplay.autosave') ?? true;
  set autosaveEnabled(bool v) => _p.setBool('gameplay.autosave', v);

  // ── Accessibility ─────────────────────────────────────────────────────
  bool get reducedMotion =>
      _p.getBool('accessibility.reducedMotion') ?? false;
  set reducedMotion(bool v) => _p.setBool('accessibility.reducedMotion', v);

  double get uiScale => _p.getDouble('accessibility.uiScale') ?? 1.0;
  set uiScale(double v) =>
      _p.setDouble('accessibility.uiScale', v.clamp(0.75, 2.0));

  // ── Reset ─────────────────────────────────────────────────────────────

  Future<void> resetToDefaults() async {
    await _p.clear();
    _log.info('Settings reset to defaults');
  }
}
