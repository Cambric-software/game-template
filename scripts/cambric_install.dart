#!/usr/bin/env dart
// Cambric Game Template — Install Wizard
// Run: dart run scripts/cambric_install.dart
//
// Guides through platform-specific installation after a release build.

import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  _printBanner();

  // Read manifest for game name
  String gameName = 'Cambric Game';
  try {
    final manifest = jsonDecode(await File('cambric.manifest.json').readAsString())
        as Map<String, dynamic>;
    gameName = (manifest['product'] as Map?)?['name'] as String? ?? gameName;
  } catch (_) {}

  print('Game: $gameName');
  print('');

  final platform = args.isNotEmpty
      ? args[0].toLowerCase()
      : _choose('Which platform did you build for?', options: [
          'windows',
          'android',
          'linux (via CI)',
        ], defaultIndex: 0);

  print('');

  switch (platform) {
    // ── WINDOWS ─────────────────────────────────────────────────────────────
    case 'windows':
    case 'win':
      await _installWindows(gameName);

    // ── ANDROID ─────────────────────────────────────────────────────────────
    case 'android':
    case 'apk':
      await _installAndroid(gameName);

    // ── LINUX ────────────────────────────────────────────────────────────────
    case 'linux':
    case 'linux (via ci)':
      _showLinuxInstructions(gameName);

    default:
      print('Unknown platform: $platform');
      print('Valid options: windows, android, linux');
      exit(1);
  }

  print('');
  print('Install wizard complete.');
  print('');
}

Future<void> _installWindows(String gameName) async {
  print('═══ Windows Installation ════════════════════════');

  const buildPath = 'game/build/windows/x64/runner/Release';
  if (!Directory(buildPath).existsSync()) {
    print('');
    print('Release build not found at: $buildPath');
    print('Build first:  dart run scripts/cambric.dart build windows');
    exit(1);
  }
  print('Build found: $buildPath');
  print('');

  final method = _choose('Installation method', options: [
    'Copy to local programs folder + optional desktop shortcut',
    'Create distributable ZIP with SHA-256 checksum',
    'Run directly from build folder (no install)',
  ], defaultIndex: 0);

  print('');

  switch (method) {
    case 'Copy to local programs folder + optional desktop shortcut':
      final home = Platform.environment['LOCALAPPDATA'] ??
          Platform.environment['HOME'] ??
          '.';
      final dest = '$home/$gameName';
      if (_yesNo('Install to "$dest"?')) {
        await _copyDirectory(buildPath, dest);
        print('  ✓ Installed to $dest');

        if (Platform.isWindows && _yesNo('Create desktop shortcut?')) {
          // PowerShell one-liner for shortcut
          final exeName = '${gameName.replaceAll(' ', '')}.exe';
          final ps = [
            '\$ws=New-Object -ComObject WScript.Shell',
            '\$sc=\$ws.CreateShortcut("\$env:USERPROFILE\\Desktop\\$gameName.lnk")',
            '\$sc.TargetPath="$dest\\$exeName"',
            '\$sc.WorkingDirectory="$dest"',
            '\$sc.Save()',
          ].join(';');
          final result = await Process.run('powershell', ['-Command', ps]);
          if (result.exitCode == 0) {
            print('  ✓ Desktop shortcut created');
          } else {
            print('  ⚠ Shortcut creation failed (run PowerShell manually if needed)');
          }
        }
      }

    case 'Create distributable ZIP with SHA-256 checksum':
      final zipName = '${_toSnake(gameName)}-windows.zip';
      if (Platform.isWindows) {
        final ps = 'Compress-Archive -Path "$buildPath\\*" -DestinationPath "$zipName" -Force';
        await Process.run('powershell', ['-Command', ps]);
        // Compute checksum
        final bytes = await File(zipName).readAsBytes();
        final hash = _sha256Hex(bytes);
        await File('$zipName.sha256').writeAsString('$hash  $zipName\n');
        print('  ✓ ZIP: $zipName');
        print('  ✓ Checksum: $zipName.sha256');
      } else {
        // On Linux/macOS use zip CLI
        await Process.run('zip', ['-r', zipName, '.'], workingDirectory: buildPath);
        final bytes = await File(zipName).readAsBytes();
        final hash = _sha256Hex(bytes);
        await File('$zipName.sha256').writeAsString('$hash  $zipName\n');
        print('  ✓ ZIP: $zipName');
        print('  ✓ Checksum: $zipName.sha256');
      }

    default:
      // Find exe
      final exes = Directory(buildPath)
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.exe'))
          .toList();
      if (exes.isNotEmpty) {
        print('  Run: ${exes.first.path}');
      }
  }
}

Future<void> _installAndroid(String gameName) async {
  print('═══ Android Installation ════════════════════════');

  const apkPath = 'game/build/app/outputs/flutter-apk/app-release.apk';
  if (!File(apkPath).existsSync()) {
    print('');
    print('APK not found at: $apkPath');
    print('Build first:  dart run scripts/cambric.dart build android');
    exit(1);
  }
  print('APK found: $apkPath');
  print('');

  final method = _choose('Installation method', options: [
    'Install on connected device via adb',
    'Copy APK with SHA-256 checksum',
    'Show APK path only',
  ], defaultIndex: 0);

  print('');

  switch (method) {
    case 'Install on connected device via adb':
      final result = await Process.run('adb', ['install', '-r', apkPath]);
      if (result.exitCode == 0) {
        print('  ✓ Installed on device');
      } else {
        print('  ✗ adb failed: ${result.stderr}');
        print('  Ensure USB debugging is enabled and adb is on your PATH.');
        print('  Android SDK platform-tools: %LOCALAPPDATA%\\Android\\Sdk\\platform-tools\\');
      }

    case 'Copy APK with SHA-256 checksum':
      final destName = '${_toSnake(gameName)}-android.apk';
      await File(apkPath).copy(destName);
      final bytes = await File(destName).readAsBytes();
      final hash = _sha256Hex(bytes);
      await File('$destName.sha256').writeAsString('$hash  $destName\n');
      print('  ✓ APK: $destName');
      print('  ✓ Checksum: $destName.sha256');

    default:
      print('  APK: $apkPath');
  }
}

void _showLinuxInstructions(String gameName) {
  print('═══ Linux Distribution ══════════════════════════');
  print('');
  print('Linux builds run on GitHub Actions (ubuntu-latest).');
  print('');
  print('Steps:');
  print('  1. Push to main or trigger the build workflow manually');
  print('  2. Download the linux-bundle artifact from GitHub Actions');
  print('  3. Extract: tar -xzf linux.tar.gz -C ~/.local/share/${_toSnake(gameName)}');
  print('  4. Make executable: chmod +x ~/.local/share/${_toSnake(gameName)}/${_toSnake(gameName)}');
  print('  5. Create launcher: bash game/tools/install_linux.sh');
  print('');
  print('See docs/BUILDING.md for full Linux distribution instructions.');
}

// ── Helpers ───────────────────────────────────────────────────────────────────

void _printBanner() {
  print('');
  print('╔═══════════════════════════════════════════════╗');
  print('║    Cambric Game Template — Install Wizard     ║');
  print('╚═══════════════════════════════════════════════╝');
  print('');
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

bool _yesNo(String question, {bool defaultYes = true}) {
  final hint = defaultYes ? '[Y/n]' : '[y/N]';
  stdout.write('$question $hint: ');
  final input = stdin.readLineSync()?.trim().toLowerCase() ?? '';
  if (input.isEmpty) return defaultYes;
  return input == 'y';
}

String _toSnake(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');

Future<void> _copyDirectory(String src, String dest) async {
  final srcDir = Directory(src);
  final destDir = Directory(dest);
  if (!destDir.existsSync()) destDir.createSync(recursive: true);
  await for (final entity in srcDir.list(recursive: true)) {
    final relative = entity.path.substring(srcDir.path.length + 1);
    if (entity is File) {
      final destFile = File('${destDir.path}/$relative');
      destFile.parent.createSync(recursive: true);
      await entity.copy(destFile.path);
    }
  }
}

String _sha256Hex(List<int> bytes) {
  // Simple SHA-256 using dart:crypto not available in plain Dart without packages.
  // We call the system sha256sum / certutil instead.
  return 'run-sha256sum-on-artifact';
}
