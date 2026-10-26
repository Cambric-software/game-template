import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../../core/logging/logging_service.dart';
import 'input_action.dart';

final _log = gameLogger('TouchInputHandler');

/// Maps touch/tap/drag events to [InputAction] values for Android.
///
/// Add to [CambricGame] after load and wire [onAction]/[onRelease]:
/// ```dart
/// final touch = TouchInputHandler(
///   onAction: (a) => game.inputState.press(a),
///   onRelease: (a) => game.inputState.release(a),
/// );
/// add(touch);
/// ```
class TouchInputHandler extends PositionComponent
    with TapCallbacks, DragCallbacks {
  TouchInputHandler({
    this.onAction,
    this.onRelease,
  }) : super(priority: 100);

  void Function(InputAction action)? onAction;
  void Function(InputAction action)? onRelease;

  final Map<String, _TouchRegion> _regions = {};

  /// Register a screen region that fires [action] when tapped.
  void setRegion(
    String id,
    Vector2 topLeft,
    Vector2 size,
    InputAction action,
  ) {
    _regions[id] = _TouchRegion(topLeft: topLeft, size: size, action: action);
  }

  // ── TapCallbacks ──────────────────────────────────────────────────────────

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    final action = _actionForPosition(event.localPosition);
    if (action != null) {
      _log.fine('Touch tap → $action');
      onAction?.call(action);
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    final action = _actionForPosition(event.localPosition);
    if (action != null) {
      onRelease?.call(action);
    }
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    super.onTapCancel(event);
    for (final region in _regions.values) {
      onRelease?.call(region.action);
    }
  }

  // ── DragCallbacks ─────────────────────────────────────────────────────────

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    const threshold = 8.0;
    final delta = event.localDelta;

    if (delta.x.abs() > threshold && delta.x.abs() > delta.y.abs()) {
      onAction?.call(
        delta.x > 0 ? InputAction.moveRight : InputAction.moveLeft,
      );
    } else if (delta.y.abs() > threshold && delta.y.abs() > delta.x.abs()) {
      onAction?.call(
        delta.y > 0 ? InputAction.moveDown : InputAction.moveUp,
      );
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    onRelease?.call(InputAction.moveLeft);
    onRelease?.call(InputAction.moveRight);
    onRelease?.call(InputAction.moveUp);
    onRelease?.call(InputAction.moveDown);
  }

  InputAction? _actionForPosition(Vector2 pos) {
    for (final region in _regions.values) {
      if (pos.x >= region.topLeft.x &&
          pos.x <= region.topLeft.x + region.size.x &&
          pos.y >= region.topLeft.y &&
          pos.y <= region.topLeft.y + region.size.y) {
        return region.action;
      }
    }
    return null;
  }

  @override
  bool containsLocalPoint(Vector2 point) => true;
}

class _TouchRegion {
  const _TouchRegion({
    required this.topLeft,
    required this.size,
    required this.action,
  });
  final Vector2 topLeft;
  final Vector2 size;
  final InputAction action;
}
