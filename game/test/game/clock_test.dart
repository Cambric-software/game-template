import 'package:test/test.dart';

import 'package:cambric_game/game/loop/game_clock.dart';

void main() {
  group('FakeClock', () {
    test('starts at given initial time', () {
      final start = DateTime(2026, 1, 15, 12, 0, 0);
      final clock = FakeClock(initialNow: start);
      expect(clock.now, equals(start));
    });

    test('starts with zero game time', () {
      final clock = FakeClock();
      expect(clock.gameTime, equals(Duration.zero));
    });

    test('advance() moves both now and gameTime', () {
      final clock = FakeClock();
      clock.advance(const Duration(seconds: 5));
      expect(clock.gameTime.inSeconds, equals(5));
    });

    test('tick() advances gameTime when not paused', () {
      final clock = FakeClock();
      clock.tick(1.0); // 1 second
      expect(clock.gameTime.inSeconds, equals(1));
    });

    test('tick() does NOT advance gameTime when paused', () {
      final clock = FakeClock();
      clock.pause();
      clock.tick(1.0);
      expect(clock.gameTime, equals(Duration.zero));
    });

    test('isPaused returns true after pause()', () {
      final clock = FakeClock();
      expect(clock.isPaused, isFalse);
      clock.pause();
      expect(clock.isPaused, isTrue);
    });

    test('isPaused returns false after resume()', () {
      final clock = FakeClock();
      clock.pause();
      clock.resume();
      expect(clock.isPaused, isFalse);
    });

    test('resumes from paused state and advances again', () {
      final clock = FakeClock();
      clock.tick(2.0); // 2s
      clock.pause();
      clock.tick(10.0); // should not advance
      clock.resume();
      clock.tick(3.0); // 3s more
      // Total should be 5 seconds
      expect(clock.gameTime.inSeconds, equals(5));
    });

    test('multiple ticks accumulate', () {
      final clock = FakeClock();
      clock.tick(0.016);
      clock.tick(0.016);
      clock.tick(0.016);
      // 3 frames at 16ms each ≈ 48ms
      expect(clock.gameTime.inMilliseconds, closeTo(48, 5));
    });
  });

  group('RealGameClock', () {
    test('starts not paused', () {
      final clock = RealGameClock();
      expect(clock.isPaused, isFalse);
    });

    test('now returns a recent time', () {
      final clock = RealGameClock();
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final after = DateTime.now().add(const Duration(seconds: 1));
      expect(clock.now.isAfter(before), isTrue);
      expect(clock.now.isBefore(after), isTrue);
    });

    test('tick advances gameTime', () {
      final clock = RealGameClock();
      clock.tick(1.0);
      expect(clock.gameTime.inSeconds, equals(1));
    });
  });
}
