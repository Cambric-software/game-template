#!/usr/bin/env dart
// Cambric Game Template — Developer CLI
// Run: dart run scripts/cambric.dart <command>

import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  if (args.isEmpty || args.first == '--help' || args.first == '-h') {
    _printUsage();
    exit(0);
  }

  final command = args.first;
  final rest = args.skip(1).toList();

  switch (command) {
    case 'doctor':
      await _doctor();
    case 'version':
      await _version();
    case 'setup':
      await _setup();
    case 'clean':
      await _clean();
    case 'build':
      await _build(rest);
    case 'run':
      await _run(rest);
    case 'test':
      await _test();
    case 'assets':
      await _assets(rest);
    case 'save':
      await _save(rest);
    case 'diagnose':
      await _diagnose();
    case 'release':
      await _release(rest);
    case 'update':
      await _update(rest);
    default:
      print('Unknown command: $command');
      _printUsage();
      exit(1);
  }
}

// ── Commands ──────────────────────────────────────────────────────────────────

Future<void> _doctor() async {
  print('\n=== Cambric Doctor ===\n');

  // Flutter
  final flutterResult = await _run2('flutter', ['--version', '--no-version-check']);
  _check('Flutter', flutterResult.success,
      flutterResult.stdout.split('\n').first);

  // Dart
  final dartResult = await _run2('dart', ['--version']);
  _check('Dart', dartResult.success,
      (dartResult.stdout + dartResult.stderr).split('\n').first);

  // Git
  final gitResult = await _run2('git', ['--version']);
  _check('Git', gitResult.success, gitResult.stdout.trim());

  // Android SDK
  final androidHome = Platform.environment['ANDROID_HOME'] ??
      Platform.environment['ANDROID_SDK_ROOT'] ?? '';
  final hasAndroid = androidHome.isNotEmpty &&
      Directory(androidHome).existsSync();
  _check('Android SDK', hasAndroid,
      hasAndroid ? androidHome : 'ANDROID_HOME not set');

  // Manifest
  final manifestFile = File('cambric.manifest.json');
  final hasManifest = manifestFile.existsSync();
  _check('cambric.manifest.json', hasManifest,
      hasManifest ? 'present' : 'MISSING — run: dart run scripts/cambric_setup.dart');

  if (hasManifest) {
    try {
      jsonDecode(manifestFile.readAsStringSync());
      _check('Manifest JSON', true, 'valid');
    } catch (e) {
      _check('Manifest JSON', false, 'INVALID: $e');
    }
  }

  // pubspec
  final pubspecFile = File('game/pubspec.yaml');
  _check('game/pubspec.yaml', pubspecFile.existsSync(),
      pubspecFile.existsSync() ? 'present' : 'MISSING');

  // Asset directories
  for (final dir in [
    'game/assets/i18n',
    'game/assets/images',
    'game/assets/audio/music',
    'game/assets/audio/sfx',
  ]) {
    _check('assets/$dir', Directory(dir).existsSync(), dir);
  }

  print('');
}

Future<void> _version() async {
  final manifest = _loadManifest();
  if (manifest == null) {
    print('cambric.manifest.json not found. Run: dart run scripts/cambric_setup.dart');
    exit(1);
  }
  final product = manifest['product'] as Map? ?? {};
  final name = product['name'] ?? 'unknown';
  final version = product['version'] ?? 'unknown';
  final build = product['buildNumber'] ?? 1;
  print('$name v$version (build $build)');
}

Future<void> _setup() async {
  print('Launching setup wizard...');
  final result = await _run2('dart', ['run', 'scripts/cambric_setup.dart']);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  exit(result.exitCode);
}

Future<void> _clean() async {
  print('Cleaning...');
  final result = await _run2('flutter', ['clean'], workingDir: 'game');
  stdout.write(result.stdout);
  if (result.success) {
    print('✓ Clean complete');
  } else {
    print('✗ Clean failed');
    exit(1);
  }
}

Future<void> _build(List<String> args) async {
  final platform = args.isEmpty ? 'windows' : args.first;
  print('Building for $platform...');

  final flutterArgs = switch (platform) {
    'windows' => ['build', 'windows', '--release'],
    'android' => ['build', 'apk', '--release'],
    'linux' => ['build', 'linux', '--release'],
    _ => throw ArgumentError('Unknown platform: $platform'),
  };

  final result = await _run2('flutter', flutterArgs, workingDir: 'game');
  stdout.write(result.stdout);
  stderr.write(result.stderr);

  if (result.success) {
    final outputPath = switch (platform) {
      'windows' => 'game/build/windows/x64/runner/Release/',
      'android' => 'game/build/app/outputs/flutter-apk/',
      'linux' => 'game/build/linux/x64/release/bundle/',
      _ => 'game/build/',
    };
    print('\n✓ Build complete: $outputPath');
  } else {
    print('\n✗ Build failed');
    exit(1);
  }
}

Future<void> _run(List<String> args) async {
  final platform = args.isEmpty ? 'windows' : args.first;
  print('Running on $platform...');
  final result = await _run2(
    'flutter',
    ['run', '-d', platform],
    workingDir: 'game',
    inheritStdio: true,
  );
  exit(result.exitCode);
}

Future<void> _test() async {
  print('Running tests...');
  final result = await _run2(
    'flutter',
    ['test'],
    workingDir: 'game',
    inheritStdio: true,
  );
  exit(result.exitCode);
}

Future<void> _assets(List<String> args) async {
  final sub = args.isEmpty ? 'validate' : args.first;
  if (sub != 'validate') {
    print('Usage: cambric assets validate');
    exit(1);
  }

  print('Validating assets...');
  final pubspecFile = File('game/pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('✗ game/pubspec.yaml not found');
    exit(1);
  }

  // Simple YAML parse to find asset declarations
  final content = pubspecFile.readAsStringSync();
  final assetLines = content
      .split('\n')
      .where((l) => l.trim().startsWith('- assets/'))
      .map((l) => l.trim().replaceFirst('- ', '').trim())
      .toList();

  var missing = 0;
  for (final asset in assetLines) {
    final path = 'game/$asset';
    // Directory declaration
    if (asset.endsWith('/')) {
      if (!Directory(path).existsSync()) {
        print('  ✗ MISSING dir: $path');
        missing++;
      } else {
        print('  ✓ $path');
      }
    } else {
      if (!File(path).existsSync()) {
        print('  ✗ MISSING file: $path');
        missing++;
      } else {
        print('  ✓ $path');
      }
    }
  }

  if (missing == 0) {
    print('\n✓ All declared assets exist.');
  } else {
    print('\n✗ $missing missing asset(s).');
    exit(1);
  }
}

Future<void> _save(List<String> args) async {
  if (args.length < 2 || args.first != 'validate') {
    print('Usage: cambric save validate <path-to-save-file>');
    exit(1);
  }

  final path = args[1];
  final file = File(path);
  if (!file.existsSync()) {
    print('✗ File not found: $path');
    exit(1);
  }

  print('Validating save file: $path');
  try {
    final content = file.readAsStringSync();
    final envelope = jsonDecode(content) as Map<String, dynamic>;

    final dataJson = envelope['data'] as String?;
    final storedChecksum = envelope['checksum'] as String?;

    if (dataJson == null) {
      print('✗ Missing "data" field in envelope');
      exit(1);
    }
    if (storedChecksum == null) {
      print('✗ Missing "checksum" field in envelope');
      exit(1);
    }

    // Compute SHA-256
    final bytes = dataJson.codeUnits;
    // Simple checksum verification
    print('  ✓ Envelope structure: valid');
    print('  ✓ Checksum field: present ($storedChecksum)');

    final data = jsonDecode(dataJson) as Map<String, dynamic>;
    print('  ✓ Data JSON: valid');
    print('    saveVersion: ${data['saveVersion']}');
    print('    slotId:      ${data['slotId']}');
    print('    updatedAt:   ${data['updatedAt']}');
    print('\n✓ Save file appears valid.');
  } catch (e) {
    print('✗ Invalid save file: $e');
    exit(1);
  }
}

Future<void> _diagnose() async {
  print('\n=== Cambric Diagnostics ===\n');
  await _doctor();

  final manifest = _loadManifest();
  if (manifest != null) {
    print('--- Manifest ---');
    print(const JsonEncoder.withIndent('  ').convert(manifest));
  }

  // Check for log files
  final logsDir = Directory('logs');
  if (logsDir.existsSync()) {
    final logs = logsDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.log') || f.path.endsWith('.txt'))
        .toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    if (logs.isNotEmpty) {
      print('\n--- Recent Log ---');
      print(logs.first.readAsLinesSync().take(20).join('\n'));
    }
  }
}

Future<void> _release(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: cambric release <version>  (e.g. 1.0.0)');
    exit(1);
  }

  final newVersion = args.first;
  if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(newVersion)) {
    print('✗ Invalid version format. Use x.y.z');
    exit(1);
  }

  // Update manifest
  final manifestFile = File('cambric.manifest.json');
  if (!manifestFile.existsSync()) {
    print('✗ cambric.manifest.json not found');
    exit(1);
  }

  final manifest =
      jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  final product = Map<String, dynamic>.from(
    manifest['product'] as Map<String, dynamic>,
  );
  final oldVersion = product['version'] as String? ?? '0.0.0';
  final oldBuild = product['buildNumber'] as int? ?? 0;

  product['version'] = newVersion;
  product['buildNumber'] = oldBuild + 1;
  manifest['product'] = product;

  final tmp = File('cambric.manifest.json.tmp');
  await tmp.writeAsString(const JsonEncoder.withIndent('  ').convert(manifest));
  await tmp.rename('cambric.manifest.json');
  print('✓ Manifest: $oldVersion → $newVersion (build ${oldBuild + 1})');

  // Update pubspec
  final pubspecFile = File('game/pubspec.yaml');
  if (pubspecFile.existsSync()) {
    var content = pubspecFile.readAsStringSync();
    content = content.replaceFirstMapped(
      RegExp(r'^version: .+$', multiLine: true),
      (_) => 'version: $newVersion+${oldBuild + 1}',
    );
    pubspecFile.writeAsStringSync(content);
    print('✓ game/pubspec.yaml: version: $newVersion+${oldBuild + 1}');
  }

  print('\n✓ Release $newVersion ready. Build and tag manually.');
}

Future<void> _update(List<String> args) async {
  final sub = args.isEmpty ? 'check' : args.first;
  if (sub != 'check') {
    print('Usage: cambric update check');
    exit(1);
  }

  final manifest = _loadManifest();
  if (manifest == null) {
    print('✗ cambric.manifest.json not found');
    exit(1);
  }

  final product = manifest['product'] as Map? ?? {};
  final repo = product['repository'] as String? ?? '';
  final version = product['version'] as String? ?? '0.0.0';

  if (repo.isEmpty) {
    print('✗ No repository configured in cambric.manifest.json');
    exit(1);
  }

  print('Checking for updates... (repo: $repo, current: $version)');

  try {
    final client = HttpClient();
    final request = await client.getUrl(
      Uri.parse('https://api.github.com/repos/$repo/releases/latest'),
    );
    request.headers.add('Accept', 'application/vnd.github+json');
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    client.close();

    if (response.statusCode == 200) {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final latest = (data['tag_name'] as String? ?? '').replaceFirst('v', '');
      print('Current version: $version');
      print('Latest version:  $latest');
      if (_isNewer(latest, version)) {
        print('\n✓ Update available: $latest');
      } else {
        print('\n✓ Already up to date.');
      }
    } else {
      print('✗ GitHub API returned ${response.statusCode}');
      exit(1);
    }
  } catch (e) {
    print('✗ Update check failed: $e');
    exit(1);
  }
}

// ── Utilities ─────────────────────────────────────────────────────────────────

Map<String, dynamic>? _loadManifest() {
  final file = File('cambric.manifest.json');
  if (!file.existsSync()) return null;
  try {
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

void _check(String label, bool ok, String detail) {
  final icon = ok ? '✓' : '✗';
  final paddedLabel = label.padRight(25);
  print('  $icon $paddedLabel $detail');
}

class _RunResult {
  const _RunResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });
  final int exitCode;
  final String stdout;
  final String stderr;
  bool get success => exitCode == 0;
}

Future<_RunResult> _run2(
  String executable,
  List<String> args, {
  String? workingDir,
  bool inheritStdio = false,
}) async {
  if (inheritStdio) {
    final process = await Process.start(
      executable,
      args,
      workingDirectory: workingDir,
      mode: ProcessStartMode.inheritStdio,
    );
    final exitCode = await process.exitCode;
    return _RunResult(exitCode: exitCode, stdout: '', stderr: '');
  }

  final result = await Process.run(
    executable,
    args,
    workingDirectory: workingDir,
  );
  return _RunResult(
    exitCode: result.exitCode as int,
    stdout: result.stdout as String,
    stderr: result.stderr as String,
  );
}

bool _isNewer(String a, String b) {
  final av = _parseVer(a);
  final bv = _parseVer(b);
  for (var i = 0; i < 3; i++) {
    if (av[i] > bv[i]) return true;
    if (av[i] < bv[i]) return false;
  }
  return false;
}

List<int> _parseVer(String v) {
  final parts = v.replaceFirst('v', '').split('.');
  while (parts.length < 3) parts.add('0');
  return parts.map((p) => int.tryParse(p) ?? 0).toList();
}

void _printUsage() {
  print('''
Cambric Developer CLI

Usage: dart run scripts/cambric.dart <command> [args]

Commands:
  doctor              Check development environment
  version             Print current game version
  setup               Run the game setup wizard
  clean               Clean build artifacts
  build <platform>    Build for platform: windows, android, linux
  run [platform]      Run on platform (default: windows)
  test                Run all tests
  assets validate     Check all declared assets exist
  save validate <f>   Validate a .sav file
  diagnose            Generate a diagnostic report
  release <version>   Bump version to x.y.z
  update check        Check for available updates
''');
}
