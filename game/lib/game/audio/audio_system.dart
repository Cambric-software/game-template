import 'package:flame_audio/flame_audio.dart';

import '../../core/logging/logging_service.dart';
import '../../settings/settings_service.dart';

final _log = gameLogger('AudioSystem');

/// Central audio system. All game audio goes through here.
///
/// Never call FlameAudio directly from game code.
/// This wrapper handles volume, mute, and pause-awareness.
class AudioSystem {
  AudioSystem();

  final SettingsService _settings = SettingsService();
  bool _initialized = false;
  bool _healthy = true;

  bool get isHealthy => _healthy;

  Future<void> initialize() async {
    try {
      FlameAudio.bgm.initialize();
      _initialized = true;
      _log.info('Audio system initialized');
    } catch (e, st) {
      _log.warning('Audio init failed — audio unavailable', e, st);
      _healthy = false;
    }
  }

  // ── Music ──────────────────────────────────────────────────────────────

  Future<void> playMusic(String filename, {bool loop = true}) async {
    if (!_initialized || !_healthy) return;
    try {
      if (loop) {
        await FlameAudio.bgm.play(filename, volume: _musicVol);
      } else {
        await FlameAudio.play(filename, volume: _musicVol);
      }
    } catch (e, st) {
      _log.warning('Failed to play music: $filename', e, st);
    }
  }

  Future<void> stopMusic() async {
    if (!_initialized || !_healthy) return;
    try {
      await FlameAudio.bgm.stop();
    } catch (e, st) {
      _log.warning('Failed to stop music', e, st);
    }
  }

  // ── SFX ───────────────────────────────────────────────────────────────

  Future<void> playSfx(String filename) async {
    if (!_initialized || !_healthy) return;
    if (_settings.audioMuted) return;
    try {
      await FlameAudio.play(filename, volume: _sfxVol);
    } catch (e, st) {
      _log.warning('Failed to play sfx: $filename', e, st);
    }
  }

  // ── Volume ────────────────────────────────────────────────────────────

  double get _musicVol {
    if (_settings.audioMuted) return 0;
    return _settings.masterVolume * _settings.musicVolume;
  }

  double get _sfxVol {
    if (_settings.audioMuted) return 0;
    return _settings.masterVolume * _settings.sfxVolume;
  }

  Future<void> applyVolumeSettings() async {
    if (!_initialized || !_healthy) return;
    try {
      FlameAudio.bgm.audioPlayer.setVolume(_musicVol);
    } catch (_) {}
  }

  // ── Pause / Resume ────────────────────────────────────────────────────

  void onGamePaused() {
    if (!_initialized || !_healthy) return;
    try {
      FlameAudio.bgm.pause();
    } catch (_) {}
  }

  void onGameResumed() {
    if (!_initialized || !_healthy) return;
    try {
      FlameAudio.bgm.resume();
    } catch (_) {}
  }

  // ── Cleanup ───────────────────────────────────────────────────────────

  Future<void> dispose() async {
    if (!_initialized || !_healthy) return;
    try {
      await FlameAudio.bgm.stop();
      FlameAudio.bgm.dispose();
      _initialized = false;
    } catch (e, st) {
      _log.warning('Error disposing audio system', e, st);
    }
  }
}
