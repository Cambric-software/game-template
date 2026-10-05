import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame_audio/flame_audio.dart';

import '../../core/logging/logging_service.dart';

final _log = gameLogger('AssetLoader');

/// Central asset loader for the Cambric game runtime.
///
/// Wraps Flame's asset loading APIs and tracks what is loaded.
/// Assets are released when their scene is disposed.
///
/// Never load assets directly with Flame.images — go through here
/// so the template can track and clean up asset memory.
class AssetLoader {
  AssetLoader();

  final Set<String> _loadedImages = {};
  final Set<String> _loadedAudio = {};

  // ── Images / Sprites ───────────────────────────────────────────────────

  /// Load a sprite from assets/images/ or assets/sprites/.
  Future<Sprite> loadSprite(String path) async {
    try {
      final image = await Flame.images.load(path);
      _loadedImages.add(path);
      _log.fine('Sprite loaded: $path');
      return Sprite(image);
    } catch (e, st) {
      _log.severe('Failed to load sprite: $path', e, st);
      rethrow;
    }
  }

  /// Load a sprite sheet divided into [cols] × [rows] uniform frames.
  Future<SpriteSheet> loadSpriteSheet(
    String path, {
    required int cols,
    required int rows,
  }) async {
    try {
      final image = await Flame.images.load(path);
      _loadedImages.add(path);
      _log.fine('Sprite sheet loaded: $path (${cols}x$rows)');
      return SpriteSheet.fromColumnsAndRows(
        image: image,
        columns: cols,
        rows: rows,
      );
    } catch (e, st) {
      _log.severe('Failed to load sprite sheet: $path', e, st);
      rethrow;
    }
  }

  // ── Audio ──────────────────────────────────────────────────────────────

  /// Preload an audio file into FlameAudio's cache.
  Future<void> loadAudio(String path) async {
    try {
      await FlameAudio.audioCache.load(path);
      _loadedAudio.add(path);
      _log.fine('Audio preloaded: $path');
    } catch (e, st) {
      _log.warning('Failed to preload audio: $path', e, st);
      // Audio failures are non-fatal — game continues without sound
    }
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────

  /// Check if an image is currently loaded.
  bool isImageLoaded(String path) => _loadedImages.contains(path);

  /// Check if an audio file is currently loaded.
  bool isAudioLoaded(String path) => _loadedAudio.contains(path);

  /// Release a specific image from cache.
  void unloadImage(String path) {
    Flame.images.clearCache();
    _loadedImages.remove(path);
    _log.fine('Image unloaded: $path');
  }

  /// Release all assets loaded through this loader.
  /// Call when the owning scene is disposed.
  void unloadAll() {
    Flame.images.clearCache();
    _loadedImages.clear();
    _loadedAudio.clear();
    _log.fine('All assets unloaded');
  }

  /// All currently loaded image paths.
  List<String> get loadedImages => List.unmodifiable(_loadedImages);

  /// All currently loaded audio paths.
  List<String> get loadedAudio => List.unmodifiable(_loadedAudio);

  int get totalLoaded => _loadedImages.length + _loadedAudio.length;
}
