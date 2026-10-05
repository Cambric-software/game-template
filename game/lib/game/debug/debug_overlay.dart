import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../game/input/input_mapper.dart';
import '../../game/scenes/scene_manager.dart';
import '../../game/state/game_state_manager.dart';
import 'performance_monitor.dart';

enum _OverlayMode { hidden, minimal, full }

/// Development-only debug overlay.
///
/// Cycles through three modes with F1:
///   hidden → minimal (FPS only) → full (all metrics)
///
/// Only added to the component tree when FeatureFlags.debugOverlay is true.
/// Cannot accidentally ship enabled in production.
class DebugOverlay extends PositionComponent {
  DebugOverlay({
    required this.gameRef,
    required this.stateManager,
    required this.sceneManager,
    this.inputState,
  }) : super(priority: 9999);

  final dynamic gameRef;
  final GameStateManager stateManager;
  final SceneManager sceneManager;
  final InputState? inputState;

  _OverlayMode _mode = _OverlayMode.full;
  final PerformanceMonitor _perf = PerformanceMonitor();

  late TextComponent _line1;
  late TextComponent _line2;
  late TextComponent _line3;

  static const _style = TextStyle(
    color: Color(0xFF00FF00),
    fontSize: 11,
    fontFamily: 'monospace',
    shadows: [Shadow(color: Color(0xFF000000), blurRadius: 2)],
  );

  @override
  Future<void> onLoad() async {
    final renderer = TextPaint(style: _style);
    _line1 = TextComponent(text: '', textRenderer: renderer, position: Vector2(8, 6));
    _line2 = TextComponent(text: '', textRenderer: renderer, position: Vector2(8, 19));
    _line3 = TextComponent(text: '', textRenderer: renderer, position: Vector2(8, 32));
    add(_line1);
    add(_line2);
    add(_line3);
  }

  /// Cycle through overlay modes. Bound to F1 by default.
  void toggle() {
    _mode = switch (_mode) {
      _OverlayMode.hidden => _OverlayMode.minimal,
      _OverlayMode.minimal => _OverlayMode.full,
      _OverlayMode.full => _OverlayMode.hidden,
    };
  }

  @override
  void update(double dt) {
    _perf.recordFrame(dt);

    if (_mode == _OverlayMode.hidden) {
      _line1.text = '';
      _line2.text = '';
      _line3.text = '';
      return;
    }

    final fps = _perf.fps.toStringAsFixed(1);
    final ms = _perf.frameTime.toStringAsFixed(1);
    _line1.text = 'FPS: $fps  Frame: ${ms}ms';

    if (_mode == _OverlayMode.minimal) {
      _line2.text = '';
      _line3.text = '';
      return;
    }

    // Full mode
    _line2.text =
        'Scene: ${sceneManager.activeSceneName}  '
        'Entities: ${sceneManager.activeEntityCount}  '
        'State: ${stateManager.current.name}';

    final pressed = inputState?.pressedActions ?? {};
    final inputStr = pressed.isEmpty
        ? 'none'
        : pressed.map((a) => a.name).join(', ');
    _line3.text = 'Input: $inputStr  Mem: N/A';
  }

  @override
  void render(Canvas canvas) {
    if (_mode == _OverlayMode.hidden) return;

    final height = switch (_mode) {
      _OverlayMode.minimal => 22.0,
      _OverlayMode.full => 50.0,
      _OverlayMode.hidden => 0.0,
    };

    final bgPaint = Paint()..color = const Color(0x88000000);
    canvas.drawRect(Rect.fromLTWH(4, 2, 380, height), bgPaint);
    super.render(canvas);
  }
}
