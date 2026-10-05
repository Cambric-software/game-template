import '../logging/logging_service.dart';

final _log = gameLogger('PluginRegistry');

/// Describes an optional Cambric plugin/module.
class PluginDescriptor {
  const PluginDescriptor({
    required this.id,
    required this.name,
    required this.version,
    this.initialize,
  });

  final String id;
  final String name;
  final String version;

  /// Optional initialization function called once on registration.
  final Future<void> Function()? initialize;

  @override
  String toString() => 'Plugin($id@$version)';
}

/// Central registry for optional Cambric modules.
///
/// This is the foundation for future plugins:
/// achievements, mods, replay systems, DLC, online services, etc.
///
/// No plugins are registered by default.
///
/// Usage:
/// ```dart
/// PluginRegistry().register(PluginDescriptor(
///   id: 'achievements',
///   name: 'Achievements',
///   version: '1.0.0',
///   initialize: () async { /* setup */ },
/// ));
/// ```
class PluginRegistry {
  PluginRegistry._();
  static final PluginRegistry _instance = PluginRegistry._();
  factory PluginRegistry() => _instance;

  final Map<String, PluginDescriptor> _plugins = {};

  Future<void> register(PluginDescriptor plugin) async {
    if (_plugins.containsKey(plugin.id)) {
      _log.warning('Plugin already registered: ${plugin.id}');
      return;
    }
    _plugins[plugin.id] = plugin;
    _log.info('Plugin registered: $plugin');
    await plugin.initialize?.call();
  }

  PluginDescriptor? get(String id) => _plugins[id];
  bool isRegistered(String id) => _plugins.containsKey(id);
  List<PluginDescriptor> list() => List.unmodifiable(_plugins.values);
}
