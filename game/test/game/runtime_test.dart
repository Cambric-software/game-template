import 'package:cambric_game/game/runtime/cambric_game.dart';
import 'package:cambric_game/game/scenes/cambric_scene.dart';
import 'package:cambric_game/game/state/game_state_manager.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestScene extends CambricScene {
  @override
  String get sceneName => 'Test';
}

void main() {
  test('scene manager is ready before the GameWidget mounts', () {
    final game = CambricGame();

    game.sceneManager.register('test', _TestScene.new);

    expect(game.sceneManager.registeredScenes, contains('test'));
  });

  test('pause and resume are no-ops outside a live session', () {
    final game = CambricGame();

    expect(game.stateManager.current, GameState.boot);

    game.pause();
    expect(game.stateManager.current, GameState.boot);

    game.resume();
    expect(game.stateManager.current, GameState.boot);
  });
}
