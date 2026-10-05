import 'package:flutter/widgets.dart';

import '../logging/logging_service.dart';

final _log = gameLogger('AppLifecycleService');

/// Coordinates app lifecycle events across all Cambric services.
///
/// Register listeners here — not in individual services — to keep
/// lifecycle handling centralized and deterministic.
class AppLifecycleService {
  AppLifecycleService._();
  static final AppLifecycleService _instance = AppLifecycleService._();
  factory AppLifecycleService() => _instance;

  final List<VoidCallback> _backgroundListeners = [];
  final List<VoidCallback> _foregroundListeners = [];
  final List<VoidCallback> _shutdownListeners = [];

  void addBackgroundListener(VoidCallback cb) =>
      _backgroundListeners.add(cb);
  void addForegroundListener(VoidCallback cb) =>
      _foregroundListeners.add(cb);
  void addShutdownListener(VoidCallback cb) =>
      _shutdownListeners.add(cb);

  void removeBackgroundListener(VoidCallback cb) =>
      _backgroundListeners.remove(cb);
  void removeForegroundListener(VoidCallback cb) =>
      _foregroundListeners.remove(cb);
  void removeShutdownListener(VoidCallback cb) =>
      _shutdownListeners.remove(cb);

  void notifyBackground() {
    _log.info('App lifecycle: background');
    for (final cb in List.of(_backgroundListeners)) {
      cb();
    }
  }

  void notifyForeground() {
    _log.info('App lifecycle: foreground');
    for (final cb in List.of(_foregroundListeners)) {
      cb();
    }
  }

  void notifyShutdown() {
    _log.info('App lifecycle: shutdown');
    for (final cb in List.of(_shutdownListeners)) {
      cb();
    }
  }

  void dispose() {
    _backgroundListeners.clear();
    _foregroundListeners.clear();
    _shutdownListeners.clear();
  }
}
