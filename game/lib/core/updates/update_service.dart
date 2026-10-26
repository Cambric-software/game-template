import 'dart:convert';

import 'package:http/http.dart' as http;

import '../cache/cache_service.dart';
import '../features/feature_flags.dart';
import '../identity/game_identity.dart';
import '../logging/logging_service.dart';

final _log = gameLogger('UpdateService');

/// Result of an update check.
class UpdateCheckResult {
  const UpdateCheckResult({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    this.downloadUrl,
    this.releaseNotes,
    this.checkedAt,
    this.error,
  });

  factory UpdateCheckResult.noUpdate(String currentVersion) =>
      UpdateCheckResult(
        hasUpdate: false,
        currentVersion: currentVersion,
        latestVersion: currentVersion,
        checkedAt: DateTime.now(),
      );

  factory UpdateCheckResult.error(String currentVersion, String error) =>
      UpdateCheckResult(
        hasUpdate: false,
        currentVersion: currentVersion,
        latestVersion: currentVersion,
        error: error,
        checkedAt: DateTime.now(),
      );

  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String? downloadUrl;
  final String? releaseNotes;
  final DateTime? checkedAt;
  final String? error;

  Map<String, dynamic> toJson() => {
    'hasUpdate': hasUpdate,
    'currentVersion': currentVersion,
    'latestVersion': latestVersion,
    'downloadUrl': downloadUrl,
    'releaseNotes': releaseNotes,
    'checkedAt': checkedAt?.toIso8601String(),
    'error': error,
  };

  factory UpdateCheckResult.fromJson(Map<String, dynamic> json) =>
      UpdateCheckResult(
        hasUpdate: json['hasUpdate'] as bool? ?? false,
        currentVersion: json['currentVersion'] as String? ?? '0.0.0',
        latestVersion: json['latestVersion'] as String? ?? '0.0.0',
        downloadUrl: json['downloadUrl'] as String?,
        releaseNotes: json['releaseNotes'] as String?,
        checkedAt: json['checkedAt'] != null
            ? DateTime.tryParse(json['checkedAt'] as String)
            : null,
        error: json['error'] as String?,
      );
}

/// Result of an update download attempt.
class DownloadResult {
  const DownloadResult({
    required this.success,
    this.filePath,
    this.checksum,
    this.error,
  });
  final bool success;
  final String? filePath;
  final String? checksum;
  final String? error;
}

/// Checks for game updates via GitHub Releases API.
///
/// Results are cached for 1 hour. If the network is unavailable,
/// the last cached result is returned. The game never fails to
/// start because of a failed update check.
class UpdateService {
  UpdateService();

  final CacheService _cache = CacheService();

  static const String _cacheKey = 'update_check';
  static const Duration _cacheTtl = Duration(hours: 1);

  /// Check for a newer version on GitHub Releases.
  Future<UpdateCheckResult> checkForUpdate({String? repository}) async {
    if (!FeatureFlags.updateChecks) {
      return UpdateCheckResult.noUpdate(GameIdentity.version);
    }
    if (!FeatureFlags.networkFeatures) {
      return UpdateCheckResult.noUpdate(GameIdentity.version);
    }

    final repo = repository ?? GameIdentity.repository;
    if (repo.isEmpty) {
      return UpdateCheckResult.error(
        GameIdentity.version,
        'No repository configured in game identity',
      );
    }

    // Return cached result if still fresh
    final cached = _cache.get<Map<String, dynamic>>(_cacheKey);
    if (cached != null) {
      _log.fine('Update check: returning cached result');
      return UpdateCheckResult.fromJson(cached);
    }

    try {
      final url = 'https://api.github.com/repos/$repo/releases/latest';
      final response = await http
          .get(
            Uri.parse(url),
            headers: {'Accept': 'application/vnd.github+json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        _log.warning('GitHub API returned ${response.statusCode} for $repo');
        return UpdateCheckResult.error(
          GameIdentity.version,
          'GitHub API error: ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final latestTag =
          (data['tag_name'] as String? ?? '').replaceFirst('v', '');
      final releaseNotes = data['body'] as String?;

      final hasUpdate = VersionComparator.isNewer(
        latestTag,
        GameIdentity.version,
      );

      final result = UpdateCheckResult(
        hasUpdate: hasUpdate,
        currentVersion: GameIdentity.version,
        latestVersion: latestTag,
        downloadUrl: _extractDownloadUrl(data),
        releaseNotes: releaseNotes,
        checkedAt: DateTime.now(),
      );

      _cache.set(_cacheKey, result.toJson(), ttl: _cacheTtl);
      await _cache.persistToDisk(_cacheKey, result.toJson());

      _log.info(
        'Update check: current=${GameIdentity.version} '
        'latest=$latestTag hasUpdate=$hasUpdate',
      );
      return result;
    } catch (e, st) {
      _log.warning('Update check failed', e, st);

      final diskCached = await _cache.loadFromDisk(_cacheKey);
      if (diskCached != null) {
        _log.info('Update check: using stale disk cache');
        return UpdateCheckResult.fromJson(
          diskCached as Map<String, dynamic>,
        );
      }

      return UpdateCheckResult.error(GameIdentity.version, e.toString());
    }
  }

  String? _extractDownloadUrl(Map<String, dynamic> release) {
    final assets = release['assets'] as List?;
    if (assets == null || assets.isEmpty) return null;
    for (final asset in assets) {
      final name = (asset['name'] as String? ?? '').toLowerCase();
      if (name.contains('windows') && name.endsWith('.zip')) {
        return asset['browser_download_url'] as String?;
      }
    }
    return (assets.first as Map)['browser_download_url'] as String?;
  }
}
