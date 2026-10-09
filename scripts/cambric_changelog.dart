#!/usr/bin/env dart
// Cambric — Changelog Generator
// Run: dart run scripts/cambric_changelog.dart
//
// Reads git log since last tag, writes CHANGELOG.md entry.
// Also records the changelog run in .cambric/state.json.

import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final root = Directory.current.path;

  print('');
  print('╔══════════════════════════════════════════╗');
  print('║   Cambric — Changelog Generator          ║');
  print('╚══════════════════════════════════════════╝');
  print('');

  // Read current version from manifest
  String version = '0.1.0';
  try {
    final manifest = jsonDecode(
      await File('$root/cambric.manifest.json').readAsString(),
    ) as Map<String, dynamic>;
    version = (manifest['product'] as Map?)?['version'] as String? ?? version;
  } catch (_) {}

  // Find last git tag
  final lastTag = await _gitLastTag();
  if (lastTag.isEmpty) {
    print('No previous tag found. Generating full history entry.');
  } else {
    print('Last tag: $lastTag');
  }
  print('Current version: $version');
  print('');

  // Get commits since last tag
  final commits = await _gitLogSinceTag(lastTag);
  if (commits.isEmpty) {
    print('No new commits since $lastTag. Nothing to changelog.');
    return;
  }

  print('${commits.length} commit(s) to include:');
  for (final c in commits.take(5)) {
    print('  • $c');
  }
  if (commits.length > 5) print('  ... and ${commits.length - 5} more');
  print('');

  // Categorize commits by conventional commit prefix
  final features = commits.where((c) => c.startsWith('feat')).toList();
  final fixes    = commits.where((c) => c.startsWith('fix')).toList();
  final others   = commits.where((c) => !c.startsWith('feat') && !c.startsWith('fix')).toList();

  // Build entry
  final date = DateTime.now().toIso8601String().substring(0, 10);
  final sb   = StringBuffer();
  sb.writeln('## [$version] — $date');
  sb.writeln('');
  if (features.isNotEmpty) {
    sb.writeln('### Added');
    for (final f in features) sb.writeln('- ${_cleanMessage(f)}');
    sb.writeln('');
  }
  if (fixes.isNotEmpty) {
    sb.writeln('### Fixed');
    for (final f in fixes) sb.writeln('- ${_cleanMessage(f)}');
    sb.writeln('');
  }
  if (others.isNotEmpty) {
    sb.writeln('### Changed');
    for (final f in others) sb.writeln('- ${_cleanMessage(f)}');
    sb.writeln('');
  }

  // Prepend to CHANGELOG.md
  final changelogFile = File('$root/CHANGELOG.md');
  final existing = changelogFile.existsSync()
      ? await changelogFile.readAsString()
      : '# Changelog\n\nAll notable changes to this project are documented here.\n\n';

  final header = existing.startsWith('# Changelog')
      ? existing.substring(0, existing.indexOf('\n\n') + 2)
      : '# Changelog\n\n';
  final rest = existing.startsWith('# Changelog')
      ? existing.substring(existing.indexOf('\n\n') + 2)
      : existing;

  await changelogFile.writeAsString('$header${sb.toString()}$rest');
  print('✓ CHANGELOG.md updated');

  // Record in .cambric/state.json
  await _recordState(root, 'lastChangelog', {
    'version': version,
    'date': date,
    'commitsIncluded': commits.length,
  });

  print('');
  print('Done. Review CHANGELOG.md before committing.');
  print('');
}

Future<String> _gitLastTag() async {
  final result = await Process.run(
    'git', ['describe', '--tags', '--abbrev=0'],
    stdoutEncoding: utf8,
  );
  return result.exitCode == 0 ? (result.stdout as String).trim() : '';
}

Future<List<String>> _gitLogSinceTag(String tag) async {
  final range = tag.isEmpty ? 'HEAD' : '$tag..HEAD';
  final result = await Process.run(
    'git', ['log', range, '--oneline', '--no-merges'],
    stdoutEncoding: utf8,
  );
  if (result.exitCode != 0) return [];
  return (result.stdout as String)
      .trim()
      .split('\n')
      .where((l) => l.isNotEmpty)
      .map((l) => l.substring(l.indexOf(' ') + 1)) // strip hash
      .toList();
}

String _cleanMessage(String msg) {
  // Strip conventional commit prefix: "feat(scope): message" -> "message"
  return msg.replaceFirst(RegExp(r'^(feat|fix|chore|docs|refactor|test|style)(\([^)]+\))?:\s*'), '');
}

Future<void> _recordState(String root, String key, Map<String, dynamic> value) async {
  try {
    final stateDir = Directory('$root/.cambric');
    if (!stateDir.existsSync()) stateDir.createSync();
    final stateFile = File('$root/.cambric/state.json');
    Map<String, dynamic> state = {};
    if (stateFile.existsSync()) {
      state = jsonDecode(await stateFile.readAsString()) as Map<String, dynamic>;
    }
    state[key] = {...value, 'timestamp': DateTime.now().toIso8601String()};
    await stateFile.writeAsString(const JsonEncoder.withIndent('  ').convert(state));
  } catch (_) {}
}
