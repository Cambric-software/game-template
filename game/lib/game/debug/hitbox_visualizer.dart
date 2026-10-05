import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/features/feature_flags.dart';
import '../scenes/scene_manager.dart';

/// Development-only component that draws colored outlines around every
/// [ShapeHitbox] found in the currently active scene.
///
/// Color coding:
/// - Green  — [RectangleHitbox] (solid rectangular hitboxes)
/// - Blue   — [CircleHitbox]    (circular hitboxes)
/// - Yellow — trigger hitboxes  ([CollisionType.passive]; sensor zones that
///                               detect overlaps but are not pushed back)
/// - White  — any other [ShapeHitbox] subtype (polygon, composite, etc.)
///
/// Only active when [FeatureFlags.showHitboxes] is `true`. Add this
/// component to the game's root (not a scene) in debug mode so it
/// survives scene transitions:
///
/// ```dart
/// if (kDebugMode && FeatureFlags.showHitboxes) {
///   add(HitboxVisualizer(sceneManager: sceneManager));
/// }
/// ```
///
/// The component re-scans the scene tree every frame so newly spawned
/// entities are picked up automatically. The scan cost is O(n) on the
/// component count of the active scene, which is acceptable for debug
/// builds only.
class HitboxVisualizer extends Component {
  HitboxVisualizer({required this.sceneManager}) : super(priority: 9998);

  final SceneManager sceneManager;

  // Pre-allocated paints to avoid per-frame allocations.
  static final Paint _rectPaint = _stroke(const Color(0xFF00FF44));   // green
  static final Paint _circlePaint = _stroke(const Color(0xFF44AAFF)); // blue
  static final Paint _triggerPaint = _stroke(const Color(0xFFFFFF00)); // yellow
  static final Paint _otherPaint = _stroke(const Color(0xFFFFFFFF));   // white

  static Paint _stroke(Color color) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  // ── Render ─────────────────────────────────────────────────────────────

  @override
  void render(Canvas canvas) {
    if (!FeatureFlags.showHitboxes) return;

    final scene = sceneManager.activeScene;
    if (scene == null) return;

    _drawHitboxes(canvas, scene);
  }

  /// Recursively walk [root]'s children and draw every [ShapeHitbox].
  void _drawHitboxes(Canvas canvas, Component root) {
    for (final child in root.children) {
      if (child is ShapeHitbox) {
        _drawHitbox(canvas, child);
      }
      // Recurse into non-hitbox children (entities, groups, etc.).
      if (child.children.isNotEmpty) {
        _drawHitboxes(canvas, child);
      }
    }
  }

  void _drawHitbox(Canvas canvas, ShapeHitbox hitbox) {
    // Determine the absolute position by walking the parent chain.
    // ShapeHitbox extends ShapeComponent which extends PositionComponent,
    // so absolutePosition is available.
    final absPos = hitbox.absolutePosition;

    if (hitbox.collisionType == CollisionType.passive) {
      // Trigger / sensor zone — yellow regardless of shape.
      _drawShape(canvas, hitbox, absPos, _triggerPaint);
      return;
    }

    if (hitbox is RectangleHitbox) {
      _drawShape(canvas, hitbox, absPos, _rectPaint);
    } else if (hitbox is CircleHitbox) {
      _drawShape(canvas, hitbox, absPos, _circlePaint);
    } else {
      _drawShape(canvas, hitbox, absPos, _otherPaint);
    }
  }

  void _drawShape(
    Canvas canvas,
    ShapeHitbox hitbox,
    Vector2 absPos,
    Paint paint,
  ) {
    if (hitbox is RectangleHitbox) {
      // Draw the bounding rectangle, rotated if needed.
      final size = hitbox.size;
      final angle = hitbox.absoluteAngle;

      canvas.save();
      canvas.translate(absPos.x, absPos.y);
      canvas.rotate(angle);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        paint,
      );
      canvas.restore();
      return;
    }

    if (hitbox is CircleHitbox) {
      final radius = hitbox.radius;
      canvas.drawCircle(
        Offset(absPos.x + radius, absPos.y + radius),
        radius,
        paint,
      );
      return;
    }

    // Fallback: draw a bounding-box rectangle for unknown shapes.
    final size = hitbox.size;
    final angle = hitbox.absoluteAngle;
    canvas.save();
    canvas.translate(absPos.x, absPos.y);
    canvas.rotate(angle);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      paint,
    );
    canvas.restore();
  }
}
