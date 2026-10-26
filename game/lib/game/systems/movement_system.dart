import 'package:flame/components.dart';

import '../entities/game_entity.dart';
import '../physics/physics_body_component.dart';

/// Processes all [GameEntity] instances that carry a [PhysicsBodyComponent],
/// advancing their position by velocity × dt every frame.
///
/// Add one instance to your scene in [onSceneLoad]:
/// ```dart
/// add(MovementSystem());
/// ```
class MovementSystem extends Component {
  MovementSystem() : super(priority: 10);

  @override
  void update(double dt) {
    final entities =
        parent?.descendants().whereType<GameEntity>() ?? [];
    for (final entity in entities) {
      final body =
          entity.getComponent<PhysicsBodyComponent>('body');
      if (body == null || body.isStatic) continue;
      body.integrate(entity.position, dt);
    }
  }
}
