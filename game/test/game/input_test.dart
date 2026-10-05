import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cambric_game/game/input/input_action.dart';
import 'package:cambric_game/game/input/input_mapper.dart';

void main() {
  group('InputMapper', () {
    late InputMapper mapper;

    setUp(() => mapper = InputMapper());

    test('arrow left maps to moveLeft action', () {
      final actions = mapper.actionsForKey(LogicalKeyboardKey.arrowLeft);
      expect(actions, contains(InputAction.moveLeft));
    });

    test('A key maps to moveLeft action (default binding)', () {
      final actions = mapper.actionsForKey(LogicalKeyboardKey.keyA);
      expect(actions, contains(InputAction.moveLeft));
    });

    test('arrow right maps to moveRight action', () {
      final actions = mapper.actionsForKey(LogicalKeyboardKey.arrowRight);
      expect(actions, contains(InputAction.moveRight));
    });

    test('Escape maps to pause action', () {
      final actions = mapper.actionsForKey(LogicalKeyboardKey.escape);
      expect(actions, contains(InputAction.pause));
    });

    test('unmapped key returns empty set', () {
      final actions = mapper.actionsForKey(LogicalKeyboardKey.f12);
      expect(actions, isEmpty);
    });

    test('Space maps to jump and confirm', () {
      final actions = mapper.actionsForKey(LogicalKeyboardKey.space);
      expect(actions, contains(InputAction.jump));
      expect(actions, contains(InputAction.confirm));
    });
  });

  group('InputState', () {
    late InputState state;

    setUp(() => state = InputState());

    test('press() makes isPressed return true', () {
      state.press(InputAction.moveLeft);
      expect(state.isPressed(InputAction.moveLeft), isTrue);
    });

    test('release() makes isPressed return false', () {
      state.press(InputAction.moveLeft);
      state.release(InputAction.moveLeft);
      expect(state.isPressed(InputAction.moveLeft), isFalse);
    });

    test('isJustPressed returns true immediately after press', () {
      state.press(InputAction.jump);
      expect(state.isJustPressed(InputAction.jump), isTrue);
    });

    test('endFrame() clears justPressed set', () {
      state.press(InputAction.jump);
      state.endFrame();
      expect(state.isJustPressed(InputAction.jump), isFalse);
    });

    test('pressedActions includes all pressed actions', () {
      state.press(InputAction.moveLeft);
      state.press(InputAction.jump);
      final pressed = state.pressedActions;
      expect(pressed, contains(InputAction.moveLeft));
      expect(pressed, contains(InputAction.jump));
    });

    test('action not pressed is not in pressedActions', () {
      final pressed = state.pressedActions;
      expect(pressed, isNot(contains(InputAction.attack)));
    });
  });
}
