import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../logging/logging_service.dart';

final _log = gameLogger('LocalizationService');

/// Localization service with English and Arabic (RTL) support.
///
/// Loads locale strings from `assets/i18n/<locale>.json`.
/// Provides key lookup with parameter substitution.
///
/// Usage:
/// ```dart
/// final l10n = LocalizationService();
/// await l10n.load('en');
/// l10n.t('menu_start'); // 'Start'
/// l10n.t('error_asset_load', params: {'name': 'hero.png'});
/// ```
class LocalizationService {
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  static final LocalizationService _instance =
      LocalizationService._internal();

  Map<String, String> _strings = {};
  String _currentLocale = 'en';
  TextDirection _textDirection = TextDirection.ltr;

  String get currentLocale => _currentLocale;
  TextDirection get textDirection => _textDirection;
  bool get isRtl => _textDirection == TextDirection.rtl;

  static const List<String> supportedLocales = ['en', 'ar'];

  /// Load locale strings from bundled assets.
  Future<void> load(String locale) async {
    final target = supportedLocales.contains(locale) ? locale : 'en';

    try {
      final jsonString = await rootBundle.loadString(
        'assets/i18n/$target.json',
      );
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      _strings = data.map((k, v) => MapEntry(k, v.toString()));
      _currentLocale = target;

      final direction = _strings['direction'] ?? 'ltr';
      _textDirection =
          direction == 'rtl' ? TextDirection.rtl : TextDirection.ltr;

      _log.info('Loaded locale: $target (${_textDirection.name})');
    } catch (e, st) {
      _log.severe('Failed to load locale $target', e, st);
      _strings = {};
      _currentLocale = 'en';
      _textDirection = TextDirection.ltr;
    }
  }

  /// Translate [key], substituting `{param}` placeholders.
  /// Returns the key if no translation is found (visible during dev).
  String t(String key, {Map<String, String>? params}) {
    var value = _strings[key] ?? key;
    if (params != null) {
      for (final entry in params.entries) {
        value = value.replaceAll('{${entry.key}}', entry.value);
      }
    }
    return value;
  }

  static bool isSupported(String locale) => supportedLocales.contains(locale);
}
