import 'package:flame/components.dart';

/// Standard gamepad buttons.
enum GamepadButton {
  a, b, x, y,
  lb, rb,
  lt, rt,
  start, select,
  dpadUp, dpadDown, dpadLeft, dpadRight,
  leftStickPress, rightStickPress,
}

/// Live state of a connected gamepad.
///
/// Analog values (sticks, triggers) are normalized to [-1, 1] or [0, 1].
class GamepadState {
  GamepadState();

  final Map<GamepadButton, bool> _pressed = {};

  /// Left analog stick position, normalized [-1, 1] per axis.
  Vector2 leftStick = Vector2.zero();

  /// Right analog stick position, normalized [-1, 1] per axis.
  Vector2 rightStick = Vector2.zero();

  /// Left trigger, normalized [0, 1].
  double lt = 0;

  /// Right trigger, normalized [0, 1].
  double rt = 0;

  bool isPressed(GamepadButton button) => _pressed[button] ?? false;

  /// For platform-specific gamepad backends to set button state.
  void setPressed(GamepadButton button, bool pressed) {
    _pressed[button] = pressed;
  }

  void reset() {
    _pressed.clear();
    leftStick.setZero();
    rightStick.setZero();
    lt = 0;
    rt = 0;
  }
}

/// Manager for gamepad connection and state.
///
/// ## Platform implementation note
///
/// Flutter does not have a built-in gamepad API for all platforms.
/// On Windows, gamepad input requires XInput via FFI or a plugin such
/// as `flutter_gamepad`. On Android, use Android's `InputDevice` API.
///
/// This class is the abstraction layer. To wire up real gamepad input:
/// 1. Create a platform-specific class that implements polling
/// 2. Call [GamepadManager().state.setPressed(button, true/false)] from it
/// 3. Set [GamepadManager().connected = true] when a gamepad is detected
///
/// Until a platform implementation is wired in, [connected] is always false
/// and [state] always returns zero/false for all inputs.
class GamepadManager {
  GamepadManager._();
  static final GamepadManager _instance = GamepadManager._();
  factory GamepadManager() => _instance;

  bool connected = false;
  final GamepadState state = GamepadState();

  void onConnected() {
    connected = true;
    state.reset();
  }

  void onDisconnected() {
    connected = false;
    state.reset();
  }
}
