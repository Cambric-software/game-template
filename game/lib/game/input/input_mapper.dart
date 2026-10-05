import 'package:flutter/services.dart';

import '../../core/logging/logging_service.dart';
import 'input_action.dart';

final _log = gameLogger('InputMapper');

/// Maps physical input events to [InputAction] values.
///
/// Loads default bindings and allows per-action overrides persisted
/// by SettingsService. Game logic never sees raw key codes.
class InputMapper {
  InputMapper() {
    _buildLookup(kDefaultKeyBindings);
  }

  /// Map from LogicalKeyboardKey → Set<InputAction>
  final Map<LogicalKeyboardKey, Set<InputAction>> _keyToActions = {};

  void _buildLookup(Map<InputAction, List<KeyBinding>> bindings) {
    _keyToActions.clear();
    for (final entry in bindings.entries) {
      for (final binding in entry.value) {
        _keyToActions.putIfAbsent(binding.key, () => {}).add(entry.key);
      }
    }
  }

  /// Override bindings with player-customized mappings.
  void applyCustomBindings(Map<InputAction, List<KeyBinding>> custom) {
    final merged = Map<InputAction, List<KeyBinding>>.from(kDefaultKeyBindings);
    merged.addAll(custom);
    _buildLookup(merged);
    _log.info('Input bindings updated with ${custom.length} custom entries');
  }

  /// Translate a keyboard key to zero or more input actions.
  Set<InputAction> actionsForKey(LogicalKeyboardKey key) =>
      _keyToActions[key] ?? const {};
}

/// Tracks the live state of all input actions (pressed / released).
class InputState {
  final Map<InputAction, bool> _pressed = {};

  /// Returns true if [action] is currently held down.
  bool isPressed(InputAction action) => _pressed[action] ?? false;

  /// Returns true if [action] was just pressed this frame.
  /// Requires calling [markConsumed] after reading.
  bool isJustPressed(InputAction action) =>
      _justPressed.contains(action);

  final Set<InputAction> _justPressed = {};
  final Set<InputAction> _justReleased = {};

  /// Mark action as pressed (called by InputSystem on key-down).
  void press(InputAction action) {
    if (!(_pressed[action] ?? false)) {
      _justPressed.add(action);
    }
    _pressed[action] = true;
  }

  /// Mark action as released (called by InputSystem on key-up).
  void release(InputAction action) {
    _pressed[action] = false;
    _justReleased.add(action);
  }

  /// Call at end of each frame to clear just-pressed/released sets.
  void endFrame() {
    _justPressed.clear();
    _justReleased.clear();
  }

  /// Returns all currently pressed actions.
  Set<InputAction> get pressedActions =>
      _pressed.entries.where((e) => e.value).map((e) => e.key).toSet();

  void markConsumed(InputAction action) {
    _justPressed.remove(action);
  }
}
