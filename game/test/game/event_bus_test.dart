import 'package:test/test.dart';

import 'package:cambric_game/game/systems/event_bus.dart';

void main() {
  setUp(() {
    // Reset the singleton between tests
    EventBus().dispose();
  });

  group('EventBus', () {
    test('subscriber receives published event', () {
      GameEvent? received;
      EventBus().subscribe<GamePausedEvent>((e) => received = e);
      EventBus().publish(GamePausedEvent());
      expect(received, isA<GamePausedEvent>());
    });

    test('subscriber only receives its own event type', () {
      GameEvent? received;
      EventBus().subscribe<GameResumedEvent>((e) => received = e);
      EventBus().publish(GamePausedEvent()); // different type
      expect(received, isNull);
    });

    test('SceneChangedEvent carries scene name', () {
      String? name;
      EventBus().subscribe<SceneChangedEvent>((e) => name = e.sceneName);
      EventBus().publish(SceneChangedEvent('Level01'));
      expect(name, equals('Level01'));
    });

    test('EntityDiedEvent carries entity id', () {
      String? id;
      EventBus().subscribe<EntityDiedEvent>((e) => id = e.entityId);
      EventBus().publish(EntityDiedEvent('player-123'));
      expect(id, equals('player-123'));
    });

    test('unsubscribeAll removes all handlers for type', () {
      var callCount = 0;
      EventBus().subscribe<GamePausedEvent>((_) => callCount++);
      EventBus().publish(GamePausedEvent());
      expect(callCount, equals(1));

      EventBus().unsubscribeAll<GamePausedEvent>();
      EventBus().publish(GamePausedEvent());
      expect(callCount, equals(1)); // not incremented
    });

    test('multiple subscribers all receive the event', () {
      var count = 0;
      EventBus().subscribe<GameResumedEvent>((_) => count++);
      EventBus().subscribe<GameResumedEvent>((_) => count++);
      EventBus().publish(GameResumedEvent());
      expect(count, equals(2));
    });

    test('handler exception does not prevent other handlers', () {
      var secondCalled = false;
      EventBus().subscribe<GamePausedEvent>((_) => throw Exception('oops'));
      EventBus().subscribe<GamePausedEvent>((_) => secondCalled = true);
      expect(
        () => EventBus().publish(GamePausedEvent()),
        returnsNormally,
      );
      expect(secondCalled, isTrue);
    });

    test('event timestamp is set to recent time', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      GameEvent? received;
      EventBus().subscribe<SaveCompletedEvent>((e) => received = e);
      EventBus().publish(SaveCompletedEvent('slot_1'));
      expect(received!.timestamp.isAfter(before), isTrue);
    });

    test('dispose clears all listeners', () {
      var called = false;
      EventBus().subscribe<GamePausedEvent>((_) => called = true);
      EventBus().dispose();
      EventBus().publish(GamePausedEvent());
      expect(called, isFalse);
    });
  });
}
