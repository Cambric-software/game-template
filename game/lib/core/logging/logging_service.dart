import 'package:logging/logging.dart';

/// Central logging service for the Cambric game template.
///
/// Wraps dart:logging to provide structured log output with
/// level filtering and optional log storage for diagnostics.
/// Game code must never use print() directly — use this service.
class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  factory LoggingService() => _instance;
  LoggingService._internal();

  final List<LogRecord> _recentRecords = [];
  static const int _maxRecentRecords = 200;

  bool _initialized = false;
  Level _level = Level.INFO;

  /// Initialize logging. Call once at startup.
  void initialize({Level level = Level.INFO, bool verbose = false}) {
    if (_initialized) return;
    _initialized = true;
    _level = verbose ? Level.ALL : level;

    Logger.root.level = _level;
    Logger.root.onRecord.listen(_handleRecord);
  }

  void _handleRecord(LogRecord record) {
    // Store recent records for diagnostics
    _recentRecords.add(record);
    if (_recentRecords.length > _maxRecentRecords) {
      _recentRecords.removeAt(0);
    }

    // Format and output — production builds suppress DEBUG
    final prefix = '[${record.level.name}] ${record.loggerName}: ';
    final message = '$prefix${record.message}';
    if (record.error != null) {
      // ignore: avoid_print
      print('$message\nError: ${record.error}\n${record.stackTrace ?? ""}');
    } else {
      // ignore: avoid_print
      print(message);
    }
  }

  /// Returns a copy of recent log records for diagnostic reports.
  List<LogRecord> get recentRecords => List.unmodifiable(_recentRecords);

  /// Clear stored records (e.g. after writing a diagnostic report).
  void clearRecentRecords() => _recentRecords.clear();

  /// Change the active log level at runtime.
  void setLevel(Level level) {
    _level = level;
    Logger.root.level = level;
  }
}

/// Convenience logger factory. Use at the top of each file:
///
/// ```dart
/// final _log = gameLogger('MyClassName');
/// _log.info('initialized');
/// ```
Logger gameLogger(String name) => Logger(name);
