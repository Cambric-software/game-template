#!/usr/bin/env dart
// Cambric Game Template — Setup Wizard
// Run: dart run scripts/cambric_setup.dart

import 'dart:convert';
import 'dart:io';

void main() async {
  _printBanner();

  // Load existing manifest if present
  final manifestFile = File('cambric.manifest.json');
  Map<String, dynamic> existing = {};
  if (await manifestFile.exists()) {
    try {
      existing = jsonDecode(await manifestFile.readAsString())
          as Map<String, dynamic>;
    } catch (_) {}
  }

  // Safety check: if already configured, warn before overwriting
  final existingName =
      (existing['product'] as Map?)?['name'] as String? ?? '';
  if (existingName.isNotEmpty &&
      existingName != 'Cambric Game' &&
      existingName != 'Game Name') {
    stdout.write(
      '\nThis project appears configured as "$existingName".\n'
      'Overwrite existing configuration? [y/N]: ',
    );
    final answer = stdin.readLineSync()?.trim().toLowerCase() ?? '';
    if (answer != 'y') {
      print('Setup cancelled. Existing configuration preserved.');
      exit(0);
    }
  }

  print('\n=== Game Identity ===');
  final gameName = _prompt('Game name', defaultValue: 'My Game');
  final gameId = _promptValidated(
    'Game ID (lowercase-hyphen, e.g. my-game)',
    defaultValue: _toKebab(gameName),
    validator: _isValidGameId,
    validationError:
        'Must be lowercase letters, numbers, and hyphens only.',
  );
  final packageId = _promptValidated(
    'Package ID (reverse domain, e.g. com.example.mygame)',
    defaultValue: 'com.cambric.${gameId.replaceAll('-', '')}',
    validator: _isValidPackageId,
    validationError: 'Must be reverse-domain format: com.example.name',
  );
  final developer = _prompt('Developer name', defaultValue: 'Cambric');
  final publisher = _prompt('Publisher name', defaultValue: developer);
  final version = _promptValidated(
    'Initial version',
    defaultValue: '0.1.0',
    validator: _isValidSemver,
    validationError: 'Must be x.y.z format (e.g. 0.1.0)',
  );

  print('\n=== Game Type ===');
  final gameType = _choose(
    'Game type',
    options: ['2d', 'platformer', 'topdown', 'puzzle', 'arcade', 'custom'],
    defaultIndex: 0,
  );

  print('\n=== Platforms ===');
  final platforms = _multiChoose(
    'Target platforms',
    options: ['android', 'windows', 'linux'],
    defaults: [0, 1, 2],
  );

  print('\n=== Display ===');
  final orientation = _choose(
    'Orientation',
    options: ['landscape', 'portrait', 'auto'],
    defaultIndex: 0,
  );

  print('\n=== Input ===');
  final inputMethods = _multiChoose(
    'Input methods',
    options: ['keyboard', 'mouse', 'touch', 'gamepad'],
    defaults: [0, 1, 2],
  );

  print('\n=== Language ===');
  final languageChoice = _choose(
    'Default language',
    options: ['English only (en)', 'Arabic only (ar)', 'Both (en + ar)'],
    defaultIndex: 0,
  );
  final locales = switch (languageChoice) {
    'Arabic only (ar)' => ['ar'],
    'Both (en + ar)' => ['en', 'ar'],
    _ => ['en'],
  };

  print('\n=== Save System ===');
  final slotsStr = _promptValidated(
    'Number of save slots (1-5)',
    defaultValue: '3',
    validator: (s) {
      final n = int.tryParse(s);
      return n != null && n >= 1 && n <= 5;
    },
    validationError: 'Must be a number from 1 to 5.',
  );
  final saveSlots = int.parse(slotsStr);
  final autosave = _yesNo('Enable autosave?', defaultYes: true);

  print('\n=== Development Mode ===');
  final devMode = _choose(
    'Mode',
    options: ['development', 'production'],
    defaultIndex: 0,
  );

  // ── Summary ─────────────────────────────────────────────────────────────
  print('\n=== Summary ===');
  print('  Name:        $gameName');
  print('  ID:          $gameId');
  print('  Package:     $packageId');
  print('  Developer:   $developer');
  print('  Publisher:   $publisher');
  print('  Version:     $version');
  print('  Type:        $gameType');
  print('  Platforms:   ${platforms.join(', ')}');
  print('  Orientation: $orientation');
  print('  Input:       ${inputMethods.join(', ')}');
  print('  Locales:     ${locales.join(', ')}');
  print('  Save slots:  $saveSlots (autosave: $autosave)');
  print('  Mode:        $devMode');

  stdout.write('\nApply these settings? [Y/n]: ');
  final confirm = stdin.readLineSync()?.trim().toLowerCase() ?? '';
  if (confirm == 'n') {
    print('Setup cancelled.');
    exit(0);
  }

  // ── Write manifest ───────────────────────────────────────────────────────
  final manifest = {
    'manifestVersion': 1,
    'product': {
      'type': 'game',
      'name': gameName,
      'id': gameId,
      'packageId': packageId,
      'version': version,
      'buildNumber': 1,
      'releaseChannel': devMode == 'production' ? 'stable' : 'beta',
      'publisher': publisher,
      'developer': developer,
      'website': 'https://cambric.dev',
      'repository': '',
      'support': '',
    },
    'platforms': platforms,
    'capabilities': {
      'touch': inputMethods.contains('touch'),
      'keyboard': inputMethods.contains('keyboard'),
      'mouse': inputMethods.contains('mouse'),
      'gamepad': inputMethods.contains('gamepad'),
      'offline': true,
      'saves': true,
      'localization': true,
      'updates': true,
    },
    'locales': locales,
    'gameType': gameType,
    'orientation': orientation,
    'saveSlots': saveSlots,
    'autosave': autosave,
    'frameworkVersion': '1.38.2',
    'cambricTemplateVersion': '0.1.0',
  };

  // Atomic write: .tmp → rename
  final tmpFile = File('cambric.manifest.json.tmp');
  await tmpFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest),
  );
  await tmpFile.rename('cambric.manifest.json');
  print('\n✓ cambric.manifest.json updated');

  // Also copy to game/assets/
  final assetManifest = File('game/assets/cambric.manifest.json');
  if (await File('game/assets').exists() ||
      await Directory('game/assets').exists()) {
    await File('cambric.manifest.json').copy(assetManifest.path);
    print('✓ game/assets/cambric.manifest.json updated');
  }

  // Update pubspec version
  final pubspecFile = File('game/pubspec.yaml');
  if (await pubspecFile.exists()) {
    var content = await pubspecFile.readAsString();
    content = content.replaceFirstMapped(
      RegExp(r'^version: .+$', multiLine: true),
      (_) => 'version: $version+1',
    );
    await pubspecFile.writeAsString(content);
    print('✓ game/pubspec.yaml version updated to $version+1');
  }

  print('\nSetup complete! Run: dart run scripts/cambric.dart run\n');
}

// ── Helpers ──────────────────────────────────────────────────────────────────

void _printBanner() {
  print('');
  print('╔═══════════════════════════════════════╗');
  print('║    Cambric Game Template — Setup      ║');
  print('╚═══════════════════════════════════════╝');
  print('');
}

String _prompt(String question, {String? defaultValue}) {
  final hint = defaultValue != null ? ' [$defaultValue]' : '';
  stdout.write('$question$hint: ');
  final input = stdin.readLineSync()?.trim() ?? '';
  return input.isEmpty && defaultValue != null ? defaultValue : input;
}

String _promptValidated(
  String question, {
  String? defaultValue,
  required bool Function(String) validator,
  required String validationError,
}) {
  while (true) {
    final value = _prompt(question, defaultValue: defaultValue);
    if (validator(value)) return value;
    print('  ✗ $validationError');
  }
}

bool _yesNo(String question, {bool defaultYes = true}) {
  final hint = defaultYes ? '[Y/n]' : '[y/N]';
  stdout.write('$question $hint: ');
  final input = stdin.readLineSync()?.trim().toLowerCase() ?? '';
  if (input.isEmpty) return defaultYes;
  return input == 'y';
}

String _choose(
  String question, {
  required List<String> options,
  int defaultIndex = 0,
}) {
  print('$question:');
  for (var i = 0; i < options.length; i++) {
    final marker = i == defaultIndex ? '▶' : ' ';
    print('  $marker ${i + 1}. ${options[i]}');
  }
  stdout.write('Choice [${defaultIndex + 1}]: ');
  final input = stdin.readLineSync()?.trim() ?? '';
  if (input.isEmpty) return options[defaultIndex];
  final n = int.tryParse(input);
  if (n != null && n >= 1 && n <= options.length) {
    return options[n - 1];
  }
  return options[defaultIndex];
}

List<String> _multiChoose(
  String question, {
  required List<String> options,
  List<int> defaults = const [],
}) {
  print('$question (comma-separated numbers, e.g. 1,2,3):');
  for (var i = 0; i < options.length; i++) {
    print('  ${i + 1}. ${options[i]}');
  }
  final defaultStr =
      defaults.map((d) => (d + 1).toString()).join(',');
  stdout.write('Choices [$defaultStr]: ');
  final input = stdin.readLineSync()?.trim() ?? '';
  if (input.isEmpty) return defaults.map((d) => options[d]).toList();

  final selected = <String>[];
  for (final part in input.split(',')) {
    final n = int.tryParse(part.trim());
    if (n != null && n >= 1 && n <= options.length) {
      selected.add(options[n - 1]);
    }
  }
  return selected.isEmpty
      ? defaults.map((d) => options[d]).toList()
      : selected;
}

// ── Validators ────────────────────────────────────────────────────────────────

bool _isValidGameId(String s) =>
    RegExp(r'^[a-z][a-z0-9-]*[a-z0-9]$').hasMatch(s) || s.length >= 2;

bool _isValidPackageId(String s) =>
    RegExp(r'^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*){1,}$').hasMatch(s);

bool _isValidSemver(String s) =>
    RegExp(r'^\d+\.\d+\.\d+$').hasMatch(s);

String _toKebab(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-+|-+$'), '');
