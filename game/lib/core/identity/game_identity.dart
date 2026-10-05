/// Game identity constants loaded from the manifest at startup.
///
/// All identity values come from [cambric.manifest.json] and
/// [pubspec.yaml] version. Never hardcode these in game code.
class GameIdentity {
  const GameIdentity._();

  // Values set once by BootstrapService from manifest + pubspec.
  static String _name = 'Cambric Game';
  static String _id = 'cambric-game';
  static String _packageId = 'com.cambric.game';
  static String _publisher = 'Cambric';
  static String _developer = 'Cambric';
  static String _website = 'https://cambric.dev';
  static String _repository = 'Cambric-software/game-template';
  static String _version = '0.1.0';
  static int _buildNumber = 1;
  static String _releaseChannel = 'stable';

  static String get name => _name;
  static String get id => _id;
  static String get packageId => _packageId;
  static String get publisher => _publisher;
  static String get developer => _developer;
  static String get website => _website;
  static String get repository => _repository;
  static String get version => _version;
  static int get buildNumber => _buildNumber;
  static String get releaseChannel => _releaseChannel;

  /// Full display version string e.g. "1.0.0 (42)"
  static String get displayVersion => '$_version ($_buildNumber)';

  /// Set by BootstrapService after reading manifest. Call only once.
  static void initialize({
    required String name,
    required String id,
    required String packageId,
    required String publisher,
    required String developer,
    required String website,
    required String repository,
    required String version,
    required int buildNumber,
    required String releaseChannel,
  }) {
    _name = name;
    _id = id;
    _packageId = packageId;
    _publisher = publisher;
    _developer = developer;
    _website = website;
    _repository = repository;
    _version = version;
    _buildNumber = buildNumber;
    _releaseChannel = releaseChannel;
  }
}

/// Semantic version comparison utility.
class VersionComparator {
  const VersionComparator._();

  /// Returns negative if [a] < [b], 0 if equal, positive if [a] > [b].
  /// Handles semver strings like "1.2.3", "1.2.3-beta.1".
  static int compare(String a, String b) {
    final aParts = _parse(a);
    final bParts = _parse(b);
    for (var i = 0; i < 3; i++) {
      final diff = aParts[i] - bParts[i];
      if (diff != 0) return diff;
    }
    return 0;
  }

  static bool isNewer(String candidate, String current) =>
      compare(candidate, current) > 0;

  static List<int> _parse(String version) {
    // Strip pre-release suffix
    final clean = version.replaceFirst(RegExp(r'^v'), '').split('-').first;
    final parts = clean.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    while (parts.length < 3) {
      parts.add(0);
    }
    return parts;
  }
}
