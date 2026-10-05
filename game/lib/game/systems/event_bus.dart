import '../../core/logging/logging_service.dart';

final _log = gameLogger('EventBus');

/// Base class for all game events.
abstract class GameEvent {
  GameEvent() : timestamp = DateTime.now();
  final DateTime timestamp;
}

// ── Built-in events ──────────────────────────────────────────────────────────

class GamePausedEvent extends GameEvent {
  GamePausedEvent();
}

class GameResumedEvent extends GameEvent {
  GameResumedEvent();
}

class SceneChangedEvent extends GameEvent {
  SceneChangedEvent(this.sceneName);
  final String sceneName;
}

class EntityDiedEvent extends GameEvent {
  EntityDiedEvent(this.entityId);
  final String entityId;
}

class SaveCompletedEvent extends GameEvent {
  SaveCompletedEvent(this.slotId);
  final String slotId;
}

class SaveFailedEvent extends GameEvent {
  SaveFailedEvent(this.slotId, this.reason);
  final String slotId;
  final String reason;
}

// ── Event bus ────────────────────────────────────────────────────────────────

/// Typed event bus for game-wide communication.
///
/// Events are dispatched synchronously. Listeners must not modify
/// the listener list during dispatch (will be deferred safely).
///
/// Usage:
/// ```dart
/// EventBus().subscribe<GamePausedEvent>(_onPaused);
/// EventBus().publish(GamePausedEvent());
/// // Later:
/// EventBus().unsubscribe<GamePausedEvent>(_onPaused);
/// ```
class EventBus {
  EventBus._();
  static final EventBus _instance = EventBus._();
  factory EventBus() => _instance;

  final Map<Type, List<void Function(GameEvent)>> _listeners = {};
  bool _dispatching = false;
  final List<_PendingOp> _pending = [];

  /// Subscribe [handler] to events of type [T].
  void subscribe<T extends GameEvent>(void Function(T) handler) {
    final wrapped = (GameEvent e) {
      if (e is T) handler(e);
    };
    if (_dispatching) {
      _pending.add(_PendingOp.add(T, wrapped));
    } else {
      _listeners.putIfAbsent(T, () => []).add(wrapped);
    }
  }

  /// Unsubscribe all handlers for type [T].
  /// Note: individual handler removal requires keeping the wrapped reference.
  /// For simplicity, call unsubscribeAll<T>() to remove all handlers for a type.
  void unsubscribeAll<T extends GameEvent>() {
    if (_dispatching) {
      _pending.add(_PendingOp.removeAll(T));
    } else {
      _listeners.remove(T);
    }
  }

  /// Publish an event to all subscribers.
  void publish(GameEvent event) {
    _dispatching = true;
    final handlers = _listeners[event.runtimeType];
    if (handlers != null) {
      for (final handler in List.of(handlers)) {
        try {
          handler(event);
        } catch (e, st) {
          _log.severe(
            'EventBus handler threw for ${event.runtimeType}',
            e,
            st,
          );
        }
      }
    }
    _dispatching = false;

    // Apply pending operations
    for (final op in _pending) {
      if (op.isAdd) {
        _listeners.putIfAbsent(op.type, () => []).add(op.handler!);
      } else {
        _listeners.remove(op.type);
      }
    }
    _pending.clear();
  }

  /// Remove all listeners. Call on game shutdown.
  void dispose() {
    _listeners.clear();
    _pending.clear();
  }
}

class _PendingOp {
  const _PendingOp.add(this.type, this.handler) : isAdd = true;
  const _PendingOp.removeAll(this.type)
      : isAdd = false,
        handler = null;

  final Type type;
  final void Function(GameEvent)? handler;
  final bool isAdd;
}
