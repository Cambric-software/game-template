import 'dart:io';
import 'package:flutter/foundation.dart';

import '../identity/game_identity.dart';
import '../logging/logging_service.dart';
import '../platform/platform_service.dart';

final _log = gameLogger('DiagnosticsService');

/// Generates local diagnostic reports.
///
/// Reports contain only technical information needed for debugging.
/// No secrets, no player data, no personal information.
/// The user must explicitly request a report — nothing is transmitted
/// automatically.
class DiagnosticsService {
  static final DiagnosticsService _instance = DiagnosticsService._internal();
  factory DiagnosticsService() => _instance;
  DiagnosticsService._internal();

  final PlatformService _platform = PlatformService();

  // Runtime health state set by subsystems
  bool _saveSystemHealthy = true;
  bool _audioSystemHealthy = true;
  bool _assetSystemHealthy = true;
  String? _lastError;
  DateTime? _lastErrorTime;
  int _errorCount = 0;

  /// Report a runtime error to diagnostics.
  void reportError(String message, {Object? error, StackTrace? stackTrace}) {
    _errorCount++;
    _lastError = message;
    _lastErrorTime = DateTime.now();
    _log.warning('Diagnostic error #$_errorCount: $message', error, stackTrace);
  }

  void setSaveSystemHealthy(bool healthy) => _saveSystemHealthy = healthy;
  void setAudioSystemHealthy(bool healthy) => _audioSystemHealthy = healthy;
  void setAssetSystemHealthy(bool healthy) => _assetSystemHealthy = healthy;

  bool get isHealthy =>
      _saveSystemHealthy && _audioSystemHealthy && _assetSystemHealthy;

  /// Generate a diagnostic report as a string.
  /// Safe to display to a user or write to a file.
  Future<String> generateReport() async {
    final sb = StringBuffer();
    sb.writeln('=== Cambric Game Diagnostic Report ===');
    sb.writeln('Generated: ${DateTime.now().toIso8601String()}');
    sb.writeln();

    sb.writeln('--- Game ---');
    sb.writeln('Name:     ${GameIdentity.name}');
    sb.writeln('Version:  ${GameIdentity.displayVersion}');
    sb.writeln('Channel:  ${GameIdentity.releaseChannel}');
    sb.writeln();

    sb.writeln('--- Environment ---');
    sb.writeln('Platform: ${_platform.platformName}');
    sb.writeln('OS:       ${_platform.osVersion}');
    sb.writeln('Mode:     ${kDebugMode ? 'debug' : 'release'}');
    sb.writeln();

    sb.writeln('--- Health ---');
    sb.writeln('Overall:       ${isHealthy ? 'OK' : 'DEGRADED'}');
    sb.writeln('Save system:   ${_saveSystemHealthy ? 'OK' : 'FAILED'}');
    sb.writeln('Audio system:  ${_audioSystemHealthy ? 'OK' : 'FAILED'}');
    sb.writeln('Asset system:  ${_assetSystemHealthy ? 'OK' : 'FAILED'}');
    sb.writeln();

    sb.writeln('--- Errors ---');
    sb.writeln('Total errors: $_errorCount');
    if (_lastError != null) {
      sb.writeln('Last error:   $_lastError');
      sb.writeln('Last time:    ${_lastErrorTime?.toIso8601String() ?? 'unknown'}');
    }
    sb.writeln();

    sb.writeln('--- Recent Logs ---');
    final recent = LoggingService().recentRecords.take(20);
    for (final r in recent) {
      sb.writeln('[${r.level.name}] ${r.loggerName}: ${r.message}');
    }

    sb.writeln();
    sb.writeln('=== End of Report ===');
    return sb.toString();
  }

  /// Write diagnostic report to the logs directory.
  Future<String?> writeReportToFile(String gameId) async {
    try {
      final logsDir = await _platform.getLogsDirectory(gameId);
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      final file = File('${logsDir.path}/diagnostic_$timestamp.txt');
      final report = await generateReport();
      await file.writeAsString(report);
      _log.info('Diagnostic report written to ${file.path}');
      return file.path;
    } catch (e, st) {
      _log.severe('Failed to write diagnostic report', e, st);
      return null;
    }
  }

  void reset() {
    _errorCount = 0;
    _lastError = null;
    _lastErrorTime = null;
    _saveSystemHealthy = true;
    _audioSystemHealthy = true;
    _assetSystemHealthy = true;
  }
}
