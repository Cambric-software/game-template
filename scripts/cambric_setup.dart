#!/usr/bin/env dart
// Cambric Game Template — Setup Wizard
// Run: dart run scripts/cambric_setup.dart

import 'dart:convert';
import 'dart:io';

void main() async {
  _printBanner();

  // Safety check
  final manifestFile = File('cambric.manifest.json');
  Map<String, dynamic> existing = {};
  if (await manifestFile.exists()) {
    try {
      existing = jsonDecode(await manifestFile.readAsString())
          as Map<String, dynamic>;
    } catch (_) {}
  }
  final existingName = (existing['product'] as Map?)?['name'] as String? ?? '';
  if (existingName.isNotEmpty &&
      existingName != 'Cambric Game' &&
      existingName != 'Game Name') {
    stdout.write(
      '\nThis project is already configured as "$existingName".\n'
      'Overwrite existing configuration? [y/N]: ',
    );
    final answer = stdin.readLineSync()?.trim().toLowerCase() ?? '';
    if (answer != 'y') {
      print('Setup cancelled. Existing configuration preserved.');
      exit(0);
    }
  }

  // ── SECTION 1: Game Identity ───────────────────────────────────────────────
  print('\n═══ Game Identity ════════════════════════════════');

  final gameName  = _prompt('Game name', defaultValue: 'My Game');
  final gameId    = _promptValidated(
    'Game ID (lowercase-hyphen, e.g. my-game)',
    defaultValue: _toKebab(gameName),
    validator: _isValidGameId,
    validationError: 'Must be lowercase letters, numbers, and hyphens only.',
  );
  final packageId = _promptValidated(
    'Package ID (reverse domain, e.g. com.example.mygame)',
    defaultValue: 'com.cambric.${gameId.replaceAll('-', '')}',
    validator: _isValidPackageId,
    validationError: 'Must be reverse-domain format: com.example.name',
  );
  final developer  = _prompt('Developer name', defaultValue: 'Cambric');
  final publisher  = _prompt('Publisher name', defaultValue: developer);
  final version    = _promptValidated(
    'Initial version',
    defaultValue: '0.1.0',
    validator: _isValidSemver,
    validationError: 'Must be x.y.z format (e.g. 0.1.0)',
  );
  final repository = _prompt('GitHub repository (owner/repo, optional)', defaultValue: '');

  // ── SECTION 2: Game Genre ─────────────────────────────────────────────────
  print('\n═══ Game Genre & Dimension ═══════════════════════');

  final gameGenre = _choose(
    'Game genre',
    options: [
      '2D Platformer',
      '2D Top-Down',
      '2D Side-Scroller',
      '3D First-Person',
      '3D Third-Person',
      '3D Open World',
      'Puzzle',
      'Strategy / Tower Defense',
      'RPG / Adventure',
      'Arcade / Casual',
      'Racing',
      'Horror / Survival',
      'Shooter',
      'Card / Board Game',
      'Simulation',
      'Custom / Hybrid',
    ],
    defaultIndex: 0,
  );

  final gameType = _genreToType(gameGenre);

  final dimension = _choose(
    'Game dimension',
    options: ['2D', '3D', 'Both (2D UI + 3D world)'],
    defaultIndex: gameGenre.startsWith('3D') ? 1 : 0,
  );

  // ── SECTION 3: Platforms ──────────────────────────────────────────────────
  print('\n═══ Target Platforms ═════════════════════════════');

  final platforms = _multiChoose(
    'Target platforms',
    options: ['android', 'windows', 'linux'],
    defaults: [0, 1, 2],
  );

  // ── SECTION 4: Display ────────────────────────────────────────────────────
  print('\n═══ Display & Performance ════════════════════════');

  final orientation = _choose(
    'Screen orientation',
    options: ['landscape', 'portrait', 'auto'],
    defaultIndex: 0,
  );

  final targetFps = _choose(
    'Target frame rate',
    options: ['30 fps (mobile-friendly)', '60 fps (standard)', '120 fps (high-refresh)'],
    defaultIndex: 1,
  );

  // ── SECTION 5: Input ──────────────────────────────────────────────────────
  print('\n═══ Input Methods ════════════════════════════════');

  final inputMethods = _multiChoose(
    'Input methods',
    options: ['keyboard', 'mouse', 'touch', 'gamepad'],
    defaults: [0, 1, 2],
  );

  // ── SECTION 6: Physics ────────────────────────────────────────────────────
  print('\n═══ Physics ══════════════════════════════════════');

  final physicsType = _choose(
    'Physics approach',
    options: [
      'Simple (built-in Flame collision only)',
      'Full physics (flame_forge2d / Box2D)',
      'No physics (puzzle/card/turn-based)',
    ],
    defaultIndex: 0,
  );

  // ── SECTION 7: Save System ────────────────────────────────────────────────
  print('\n═══ Save System ══════════════════════════════════');

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
  final autosave  = _yesNo('Enable autosave?', defaultYes: true);

  // ── SECTION 8: Audio ──────────────────────────────────────────────────────
  print('\n═══ Audio ════════════════════════════════════════');

  final hasMusic = _yesNo('Include background music?', defaultYes: true);
  final hasSfx   = _yesNo('Include sound effects?', defaultYes: true);

  // ── SECTION 9: Language ───────────────────────────────────────────────────
  print('\n═══ Language & Localization ══════════════════════');

  final languageChoice = _choose(
    'Supported languages',
    options: [
      'English only (en)',
      'Arabic only (ar)',
      'Both (en + ar)',
      'English + add more later',
    ],
    defaultIndex: 0,
  );
  final locales = switch (languageChoice) {
    'Arabic only (ar)'         => ['ar'],
    'Both (en + ar)'           => ['en', 'ar'],
    'English + add more later' => ['en'],
    _                          => ['en'],
  };

  // ── SECTION 10: Multiplayer ───────────────────────────────────────────────
  print('\n═══ Multiplayer ══════════════════════════════════');

  final multiplayerType = _choose(
    'Multiplayer support',
    options: [
      'None (single-player only)',
      'Local multiplayer (same device)',
      'Online multiplayer (architecture placeholder — requires backend)',
      'Co-op (local + optional online)',
    ],
    defaultIndex: 0,
  );

  // ── SECTION 11: DLC & Extensions ─────────────────────────────────────────
  print('\n═══ DLC & Content Extensions ═════════════════════');

  final dlcSupport = _yesNo(
    'Reserve architecture for DLC / downloadable content?',
    defaultYes: false,
  );

  // ── SECTION 12: Monetization ──────────────────────────────────────────────
  print('\n═══ Monetization ═════════════════════════════════');

  final monetization = _choose(
    'Monetization model',
    options: [
      'None (free game)',
      'Paid one-time purchase',
      'Freemium (free + paid content)',
      'Subscription (requires backend)',
      'Not decided yet',
    ],
    defaultIndex: 0,
  );

  // ── SECTION 13: Dev Mode ──────────────────────────────────────────────────
  print('\n═══ Development Mode ═════════════════════════════');

  final devMode = _choose(
    'Mode',
    options: ['development', 'production'],
    defaultIndex: 0,
  );

  // ── SUMMARY ───────────────────────────────────────────────────────────────
  print('\n═══ Summary ══════════════════════════════════════');
  print('  Name:         $gameName');
  print('  ID:           $gameId');
  print('  Package:      $packageId');
  print('  Developer:    $developer');
  print('  Version:      $version');
  print('  Genre:        $gameGenre');
  print('  Dimension:    $dimension');
  print('  Platforms:    ${platforms.join(', ')}');
  print('  Orientation:  $orientation');
  print('  FPS:          $targetFps');
  print('  Input:        ${inputMethods.join(', ')}');
  print('  Physics:      $physicsType');
  print('  Save slots:   $saveSlots (autosave: $autosave)');
  print('  Audio:        music=$hasMusic sfx=$hasSfx');
  print('  Languages:    ${locales.join(', ')}');
  print('  Multiplayer:  $multiplayerType');
  print('  DLC:          ${dlcSupport ? "reserved" : "none"}');
  print('  Monetization: $monetization');
  print('  Mode:         $devMode');

  stdout.write('\nApply these settings? [Y/n]: ');
  final confirm = stdin.readLineSync()?.trim().toLowerCase() ?? '';
  if (confirm == 'n') {
    print('Setup cancelled.');
    exit(0);
  }

  // ── WRITE MANIFEST ────────────────────────────────────────────────────────
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
      'repository': repository,
      'support': '',
    },
    'platforms': platforms,
    'capabilities': {
      'touch':        inputMethods.contains('touch'),
      'keyboard':     inputMethods.contains('keyboard'),
      'mouse':        inputMethods.contains('mouse'),
      'gamepad':      inputMethods.contains('gamepad'),
      'offline':      true,
      'saves':        true,
      'localization': true,
      'updates':      true,
      'dlc':          dlcSupport,
      'multiplayer':  multiplayerType != 'None (single-player only)',
    },
    'locales':          locales,
    'gameType':         gameType,
    'gameGenre':        gameGenre,
    'gameDimension':    dimension.startsWith('3D') ? '3d' : '2d',
    'orientation':      orientation,
    'targetFps':        targetFps.startsWith('30') ? 30 : targetFps.startsWith('120') ? 120 : 60,
    'physics':          physicsType.startsWith('Full') ? 'box2d' : physicsType.startsWith('No') ? 'none' : 'simple',
    'saveSlots':        saveSlots,
    'autosave':         autosave,
    'audio':            {'music': hasMusic, 'sfx': hasSfx},
    'multiplayer':      multiplayerType,
    'dlcSupport':       dlcSupport,
    'monetization':     monetization,
    'frameworkVersion': '1.38.2',
    'cambricTemplateVersion': '0.1.0',
  };

  // Atomic write
  final tmp = File('cambric.manifest.json.tmp');
  await tmp.writeAsString(const JsonEncoder.withIndent('  ').convert(manifest));
  await tmp.rename('cambric.manifest.json');
  print('\n✓ cambric.manifest.json updated');

  // Copy to game/assets/
  try {
    await File('cambric.manifest.json').copy('game/assets/cambric.manifest.json');
    print('✓ game/assets/cambric.manifest.json updated');
  } catch (_) {}

  // Update pubspec version
  final pubspec = File('game/pubspec.yaml');
  if (await pubspec.exists()) {
    var content = await pubspec.readAsString();
    content = content.replaceFirstMapped(
      RegExp(r'^version: .+$', multiLine: true),
      (_) => 'version: $version+1',
    );
    await pubspec.writeAsString(content);
    print('✓ game/pubspec.yaml version set to $version+1');
  }

  // Notes
  print('');
  if (dimension.startsWith('3D') || dimension.contains('3D')) {
    print('⚠  3D games: Add a 3D renderer to game/pubspec.yaml.');
    print('   Options: flutter_scene, three_dart, or custom OpenGL/Vulkan binding.');
  }
  if (physicsType.startsWith('Full')) {
    print('⚠  Full physics: run: cd game && flutter pub add flame_forge2d');
  }
  if (multiplayerType.contains('Online')) {
    print('⚠  Online multiplayer is an architecture placeholder.');
    print('   You will need a backend. Add networking in lib/services/.');
  }
  if (dlcSupport) {
    print('⚠  DLC: The DownloadService architecture is reserved in lib/core/updates/.');
    print('   Implement content manifest + signed download verification before shipping.');
  }

  print('');
  print('Setup complete! Run: dart run scripts/cambric.dart run');
  print('');
}

// ── Helpers ───────────────────────────────────────────────────────────────────

void _printBanner() {
  print('');
  print('╔═══════════════════════════════════════════════╗');
  print('║    Cambric Game Template — Setup Wizard       ║');
  print('╚═══════════════════════════════════════════════╝');
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

String _choose(String question, {required List<String> options, int defaultIndex = 0}) {
  print('$question:');
  for (var i = 0; i < options.length; i++) {
    final marker = i == defaultIndex ? '▶' : ' ';
    print('  $marker ${i + 1}. ${options[i]}');
  }
  stdout.write('Choice [${defaultIndex + 1}]: ');
  final input = stdin.readLineSync()?.trim() ?? '';
  if (input.isEmpty) return options[defaultIndex];
  final n = int.tryParse(input);
  if (n != null && n >= 1 && n <= options.length) return options[n - 1];
  return options[defaultIndex];
}

List<String> _multiChoose(
  String question, {
  required List<String> options,
  List<int> defaults = const [],
}) {
  print('$question (comma-separated numbers):');
  for (var i = 0; i < options.length; i++) {
    print('  ${i + 1}. ${options[i]}');
  }
  final defaultStr = defaults.map((d) => (d + 1).toString()).join(',');
  stdout.write('Choices [$defaultStr]: ');
  final input = stdin.readLineSync()?.trim() ?? '';
  if (input.isEmpty) return defaults.map((d) => options[d]).toList();
  final selected = <String>[];
  for (final part in input.split(',')) {
    final n = int.tryParse(part.trim());
    if (n != null && n >= 1 && n <= options.length) selected.add(options[n - 1]);
  }
  return selected.isEmpty ? defaults.map((d) => options[d]).toList() : selected;
}

bool _isValidGameId(String s) =>
    s.length >= 2 && RegExp(r'^[a-z][a-z0-9\-]*$').hasMatch(s);
bool _isValidPackageId(String s) =>
    RegExp(r'^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+$').hasMatch(s);
bool _isValidSemver(String s) => RegExp(r'^\d+\.\d+\.\d+$').hasMatch(s);

String _toKebab(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-+|-+$'), '');

String _genreToType(String genre) {
  if (genre.startsWith('2D Platformer'))   return 'platformer';
  if (genre.startsWith('2D Top-Down'))     return 'topdown';
  if (genre.startsWith('2D Side'))         return '2d';
  if (genre.startsWith('3D'))              return '3d';
  if (genre.startsWith('Puzzle'))          return 'puzzle';
  if (genre.startsWith('RPG'))             return 'rpg';
  if (genre.startsWith('Arcade'))          return 'arcade';
  if (genre.startsWith('Strategy'))        return 'strategy';
  if (genre.startsWith('Racing'))          return 'racing';
  if (genre.startsWith('Horror'))          return 'horror';
  if (genre.startsWith('Shooter'))         return 'shooter';
  if (genre.startsWith('Card'))            return 'card';
  if (genre.startsWith('Simulation'))      return 'simulation';
  return 'custom';
}
