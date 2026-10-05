import 'dart:math' as math;

import 'package:flame/camera.dart';
import 'package:flame/components.dart';

import '../../core/logging/logging_service.dart';

final _log = gameLogger('GameCamera');

/// Camera system wrapping Flame's CameraComponent.
///
/// Provides a clean Cambric API over Flame's camera primitives:
/// follow, zoom, shake, bounds clamping, and smooth movement.
class GameCamera {
  GameCamera({CameraComponent? flameCamera}) {
    camera = flameCamera ?? CameraComponent();
  }

  late final CameraComponent camera;

  PositionComponent? _followTarget;
  Vector2? _followOffset;

  double _zoom = 1.0;
  double _targetZoom = 1.0;
  double _zoomSpeed = 2.0;

  double _shakeIntensity = 0;
  double _shakeRemaining = 0;
  final math.Random _rng = math.Random();

  Rect? bounds;

  // ── Follow ────────────────────────────────────────────────────────────

  /// Camera will follow [target] each frame.
  void follow(PositionComponent target, {Vector2? offset}) {
    _followTarget = target;
    _followOffset = offset;
    camera.follow(target, horizontalOnly: false);
    _log.fine('Camera following entity');
  }

  void stopFollowing() {
    _followTarget = null;
    _followOffset = null;
    camera.stop();
    _log.fine('Camera stopped following');
  }

  // ── Position ──────────────────────────────────────────────────────────

  /// Instantly move camera to [position].
  void snapTo(Vector2 position) {
    camera.moveTo(position);
  }

  // ── Zoom ──────────────────────────────────────────────────────────────

  double get zoom => _zoom;

  set zoom(double value) {
    _zoom = value.clamp(0.1, 10.0);
    _targetZoom = _zoom;
    camera.viewfinder.zoom = _zoom;
  }

  /// Smoothly animate zoom to [target] over time.
  void zoomTo(double target, {double speed = 2.0}) {
    _targetZoom = target.clamp(0.1, 10.0);
    _zoomSpeed = speed;
  }

  // ── Shake ─────────────────────────────────────────────────────────────

  /// Shake the camera for [durationSeconds] with [intensity] pixels.
  void shake(double intensity, double durationSeconds) {
    _shakeIntensity = intensity;
    _shakeRemaining = durationSeconds;
    _log.fine('Camera shake: ${intensity}px for ${durationSeconds}s');
  }

  // ── Update ────────────────────────────────────────────────────────────

  void update(double dt) {
    // Smooth zoom
    if ((_zoom - _targetZoom).abs() > 0.01) {
      _zoom += (_targetZoom - _zoom) * _zoomSpeed * dt;
      camera.viewfinder.zoom = _zoom;
    }

    // Shake
    if (_shakeRemaining > 0) {
      _shakeRemaining -= dt;
      final ox = (_rng.nextDouble() * 2 - 1) * _shakeIntensity;
      final oy = (_rng.nextDouble() * 2 - 1) * _shakeIntensity;
      camera.viewfinder.position = Vector2(ox, oy);
      if (_shakeRemaining <= 0) {
        camera.viewfinder.position = Vector2.zero();
        _shakeIntensity = 0;
      }
    }
  }
}
