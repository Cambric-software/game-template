import '../logging/logging_service.dart';

final _log = gameLogger('EcosystemService');

/// Information about another Cambric application found on this device.
class CambricAppInfo {
  const CambricAppInfo({
    required this.appId,
    required this.appName,
    required this.version,
    required this.dataPath,
  });

  final String appId;
  final String appName;
  final String version;
  final String dataPath;

  @override
  String toString() => 'CambricApp($appId@$version)';
}

/// Foundation for Cambric ecosystem integration.
///
/// The full ecosystem enables Cambric products to discover each other
/// on the same device, share accessibility preferences, and exchange
/// local data with explicit user permission.
///
/// ## Current implementation
///
/// This is a protocol foundation — the actual discovery and IPC require
/// Cambric Hub, which is a separate component. Until Hub is available:
/// - [discover] returns an empty list
/// - [sharePreference] logs the call but does nothing
///
/// ## Privacy guarantee
///
/// Ecosystem connections are always permission-controlled. No app can
/// access another app's private data without explicit user consent.
/// No Cambric server is required for local ecosystem functionality.
class EcosystemService {
  EcosystemService._();
  static final EcosystemService _instance = EcosystemService._();
  factory EcosystemService() => _instance;

  /// Discover other Cambric applications on this device.
  ///
  /// Requires Cambric Hub for full implementation.
  /// Currently returns empty list.
  Future<List<CambricAppInfo>> discover() async {
    // Extension point: scan for Cambric Hub socket / shared preferences
    // namespace to find other Cambric apps.
    _log.fine('EcosystemService.discover() — Hub not present, returning []');
    return [];
  }

  /// Broadcast a shared preference to other Cambric apps (local only).
  ///
  /// Requires Cambric Hub for full implementation.
  void sharePreference(String key, dynamic value) {
    // Extension point: write to shared Cambric preferences namespace
    _log.fine('EcosystemService.sharePreference($key) — Hub not present');
  }
}
