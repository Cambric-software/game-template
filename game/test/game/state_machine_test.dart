import 'package:test/test.dart';

import 'package:cambric_game/game/state/game_state_manager.dart';

void main() {
  late GameStateManager manager;

  setUp(() => manager = GameStateManager());

  group('GameStateManager', () {
    test('starts in boot state', () {
      expect(manager.current, equals(GameState.boot));
    });

    test('valid transition: boot → loading → mainMenu', () {
      manager.transition(GameState.loading);
      expect(manager.current, equals(GameState.loading));
      manager.transition(GameState.mainMenu);
      expect(manager.current, equals(GameState.mainMenu));
    });

    test('transition to same state does nothing', () {
      var callCount = 0;
      manager.addListener((from, to) => callCount++);
      manager.transition(GameState.boot);
      expect(callCount, equals(0));
    });

    test('isPlaying returns true only in playing state', () {
      manager.transition(GameState.loading);
      manager.transition(GameState.mainMenu);
      manager.transition(GameState.playing);
      expect(manager.isPlaying, isTrue);
      manager.transition(GameState.paused);
      expect(manager.isPlaying, isFalse);
    });

    test('isPaused returns true only in paused state', () {
      manager.transition(GameState.loading);
      manager.transition(GameState.mainMenu);
      manager.transition(GameState.playing);
      expect(manager.isPaused, isFalse);
      manager.transition(GameState.paused);
      expect(manager.isPaused, isTrue);
    });

    test('listener is called on valid transition', () {
      GameState? capturedFrom;
      GameState? capturedTo;

      manager.addListener((from, to) {
        capturedFrom = from;
        capturedTo = to;
      });

      manager.transition(GameState.loading);

      expect(capturedFrom, equals(GameState.boot));
      expect(capturedTo, equals(GameState.loading));
    });

    test('listener can be removed', () {
      var callCount = 0;
      void listener(GameState from, GameState to) => callCount++;

      manager.addListener(listener);
      manager.transition(GameState.loading);
      expect(callCount, equals(1));

      manager.removeListener(listener);
      manager.transition(GameState.mainMenu);
      expect(callCount, equals(1)); // not incremented
    });

    test('unexpected transition logs warning but does not throw', () {
      // boot → playing is not in allowed map but must not crash
      expect(
        () => manager.transition(GameState.playing),
        returnsNormally,
      );
      expect(manager.current, equals(GameState.playing));
    });
  });
}
