import 'package:flutter/services.dart';

/// Named input actions. Physical keys/touches/buttons map to these.
///
/// Game logic only reacts to InputActions, never to physical key codes.
/// This is the complete canonical list for the template. Game-specific
/// actions should be added here when extending the template.
enum InputAction {
  // ── Movement ────────────────────────────────────────────────────────
  moveLeft,
  moveRight,
  moveUp,
  moveDown,

  // ── Core gameplay ────────────────────────────────────────────────────
  jump,
  attack,
  interact,
  dash,
  block,

  // ── UI / system ─────────────────────────────────────────────────────
  pause,
  confirm,
  cancel,
  inventory,
  map,

  // ── Debug (dev-only) ────────────────────────────────────────────────
  debugToggleOverlay,
  debugSpeedUp,
  debugSlowDown,
}

/// Represents a physical input source that can trigger an [InputAction].
abstract class InputBinding {
  const InputBinding();
}

/// A keyboard key binding.
class KeyBinding extends InputBinding {
  const KeyBinding(this.key);

  final LogicalKeyboardKey key;

  @override
  String toString() => 'Key(${key.keyLabel})';
}

/// The default keyboard input bindings.
/// Players can override these; the overrides are stored in SettingsService.
const Map<InputAction, List<KeyBinding>> kDefaultKeyBindings = {
  InputAction.moveLeft: [
    KeyBinding(LogicalKeyboardKey.arrowLeft),
    KeyBinding(LogicalKeyboardKey.keyA),
  ],
  InputAction.moveRight: [
    KeyBinding(LogicalKeyboardKey.arrowRight),
    KeyBinding(LogicalKeyboardKey.keyD),
  ],
  InputAction.moveUp: [
    KeyBinding(LogicalKeyboardKey.arrowUp),
    KeyBinding(LogicalKeyboardKey.keyW),
  ],
  InputAction.moveDown: [
    KeyBinding(LogicalKeyboardKey.arrowDown),
    KeyBinding(LogicalKeyboardKey.keyS),
  ],
  InputAction.jump: [
    KeyBinding(LogicalKeyboardKey.space),
    KeyBinding(LogicalKeyboardKey.arrowUp),
  ],
  InputAction.attack: [
    KeyBinding(LogicalKeyboardKey.keyX),
    KeyBinding(LogicalKeyboardKey.keyJ),
  ],
  InputAction.interact: [
    KeyBinding(LogicalKeyboardKey.keyE),
    KeyBinding(LogicalKeyboardKey.enter),
  ],
  InputAction.pause: [
    KeyBinding(LogicalKeyboardKey.escape),
    KeyBinding(LogicalKeyboardKey.keyP),
  ],
  InputAction.confirm: [
    KeyBinding(LogicalKeyboardKey.enter),
    KeyBinding(LogicalKeyboardKey.space),
  ],
  InputAction.cancel: [
    KeyBinding(LogicalKeyboardKey.escape),
    KeyBinding(LogicalKeyboardKey.backspace),
  ],
  InputAction.debugToggleOverlay: [
    KeyBinding(LogicalKeyboardKey.f1),
  ],
};
