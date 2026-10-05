/// The version of the save file format.
/// Increment when the save schema changes. Migration runs automatically.
const int kCurrentSaveVersion = 1;

/// Immutable snapshot of save-game data.
///
/// Extend this class for game-specific save data by adding fields
/// in [gameData]. The core fields (version, checksum, timestamps)
/// are managed by [SaveService] and must not be modified directly.
class SaveData {
  const SaveData({
    required this.saveVersion,
    required this.slotId,
    required this.createdAt,
    required this.updatedAt,
    required this.playtimeSeconds,
    required this.gameData,
    this.checksum,
  });

  /// The save format version. Used for migration.
  final int saveVersion;

  /// Identifies which save slot this belongs to.
  final String slotId;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Total playtime in seconds.
  final int playtimeSeconds;

  /// Game-specific data. Add your fields here.
  /// Example: {'level': 3, 'score': 2500, 'playerHp': 100}
  final Map<String, dynamic> gameData;

  /// SHA-256 checksum of the serialized data (set by SaveService).
  final String? checksum;

  /// Human-readable playtime string, e.g. "1h 23m".
  String get playtimeDisplay {
    final hours = playtimeSeconds ~/ 3600;
    final minutes = (playtimeSeconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  SaveData copyWith({
    int? saveVersion,
    String? slotId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? playtimeSeconds,
    Map<String, dynamic>? gameData,
    String? checksum,
  }) {
    return SaveData(
      saveVersion: saveVersion ?? this.saveVersion,
      slotId: slotId ?? this.slotId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      playtimeSeconds: playtimeSeconds ?? this.playtimeSeconds,
      gameData: gameData ?? this.gameData,
      checksum: checksum ?? this.checksum,
    );
  }

  Map<String, dynamic> toJson() => {
    'saveVersion': saveVersion,
    'slotId': slotId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'playtimeSeconds': playtimeSeconds,
    'gameData': gameData,
    // checksum is NOT included in the JSON — it's stored separately
  };

  factory SaveData.fromJson(Map<String, dynamic> json) => SaveData(
    saveVersion: json['saveVersion'] as int? ?? 1,
    slotId: json['slotId'] as String? ?? 'unknown',
    createdAt: _parseDate(json['createdAt']),
    updatedAt: _parseDate(json['updatedAt']),
    playtimeSeconds: json['playtimeSeconds'] as int? ?? 0,
    gameData: Map<String, dynamic>.from(
      json['gameData'] as Map? ?? {},
    ),
  );

  /// Create a fresh save for the given slot.
  factory SaveData.fresh(String slotId) => SaveData(
    saveVersion: kCurrentSaveVersion,
    slotId: slotId,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    playtimeSeconds: 0,
    gameData: const {},
  );

  static DateTime _parseDate(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}

/// Identifies a save slot.
class SaveSlot {
  const SaveSlot({
    required this.id,
    required this.displayName,
    this.isAutoSave = false,
  });

  final String id;
  final String displayName;
  final bool isAutoSave;

  static const SaveSlot slot1 = SaveSlot(id: 'slot_1', displayName: 'Slot 1');
  static const SaveSlot slot2 = SaveSlot(id: 'slot_2', displayName: 'Slot 2');
  static const SaveSlot slot3 = SaveSlot(id: 'slot_3', displayName: 'Slot 3');
  static const SaveSlot autosave = SaveSlot(
    id: 'autosave',
    displayName: 'Auto Save',
    isAutoSave: true,
  );

  static const List<SaveSlot> defaultSlots = [
    autosave,
    slot1,
    slot2,
    slot3,
  ];
}
