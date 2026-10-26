import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame_audio/flame_audio.dart';

import '../../core/logging/logging_service.dart';

final _log = gameLogger('AssetLoader');

/// Central asset loader for the Cambric game runtime.
///
/// Wraps Flame's asset loading APIs and tracks what is loaded.
/// Assets are released when their scene is disposed.
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

  /// Load a sprite animation from a sprite sheet image.
  ///
  /// [cols] and [rows] define how many frames are in the sheet.
  /// Each frame is [cols × rows] cells, read left-to-right, top-to-bottom.
  Future<SpriteAnimation> loadSpriteAnimation(
    String path, {
    required int cols,
    required int rows,
    required double stepTime,
    bool loop = true,
  }) async {
    try {
      final image = await Flame.images.load(path);
      _loadedImages.add(path);
      final frameWidth = (image.width / cols).toDouble();
      final frameHeight = (image.height / rows).toDouble();
      final sprites = <Sprite>[];

      for (var row = 0; row < rows; row++) {
        for (var col = 0; col < cols; col++) {
          sprites.add(Sprite(
            image,
            srcPosition: Vector2(col * frameWidth, row * frameHeight),
            srcSize: Vector2(frameWidth, frameHeight),
          ));
        }
      }

      _log.fine('Sprite animation loaded: $path (${cols * rows} frames)');
      return SpriteAnimation.spriteList(sprites, stepTime: stepTime, loop: loop);
    } catch (e, st) {
      _log.severe('Failed to load sprite animation: $path', e, st);
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

  bool isImageLoaded(String path) => _loadedImages.contains(path);
  bool isAudioLoaded(String path) => _loadedAudio.contains(path);

  /// Release all assets loaded through this loader.
  /// Call when the owning scene is disposed.
  void unloadAll() {
    Flame.images.clearCache();
    _loadedImages.clear();
    _loadedAudio.clear();
    _log.fine('All assets unloaded');
  }

  List<String> get loadedImages => List.unmodifiable(_loadedImages);
  List<String> get loadedAudio => List.unmodifiable(_loadedAudio);
  int get totalLoaded => _loadedImages.length + _loadedAudio.length;
}
