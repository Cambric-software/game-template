#!/usr/bin/env dart
// Cambric — Lock File Generator
// Run: dart run scripts/cambric_lock.dart
//
// Records template/Dart/OS versions at setup time.
// Commit cambric.lock so future developers can detect environment drift.

import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  print('Generating cambric.lock...');

  // Read manifest
  String templateVersion = '0.1.0';
  String gameVersion     = '0.1.0';
  try {
    final manifest = jsonDecode(
      await File('cambric.manifest.json').readAsString(),
    ) as Map<String, dynamic>;
    templateVersion =
        (manifest['cambricTemplateVersion'] as String?) ?? templateVersion;
    gameVersion =
        (manifest['product'] as Map?)?['version'] as String? ?? gameVersion;
  } catch (_) {}

  // Dart version is always available at runtime
  final dartVersion = Platform.version.split(' ').first;

  final lock = {
    'lockVersion': 1,
    'generatedAt': DateTime.now().toIso8601String(),
    'cambric': {
      'templateVersion': templateVersion,
      'gameVersion': gameVersion,
      'repository': 'Cambric-software/game-template',
    },
    'environment': {
      'dart': dartVersion,
      'flutter': '3.47.2',   // update when upgrading Flutter
      'flame': '1.38.2',     // update when upgrading Flame
      'platform': Platform.operatingSystem,
      'os': Platform.operatingSystemVersion,
    },
    'note':
        'Regenerate: dart run scripts/cambric_lock.dart  |  '
        'Check drift: dart run scripts/cambric.dart doctor',
  };

  await File('cambric.lock').writeAsString(
    const JsonEncoder.withIndent('  ').convert(lock),
  );
  print('✓ cambric.lock written');
  print('');
}
