import 'save_data.dart';

/// Result of save validation.
class SaveValidationResult {
  const SaveValidationResult({
    required this.isValid,
    required this.errors,
  });

  final bool isValid;
  final List<String> errors;

  @override
  String toString() => isValid
      ? 'SaveValidationResult: valid'
      : 'SaveValidationResult: INVALID — ${errors.join('; ')}';
}

/// Validates save data for integrity and required fields.
///
/// Used by SaveService on load and by the CLI doctor command.
class SaveValidator {
  const SaveValidator();

  /// Validate a [SaveData] instance.
  SaveValidationResult validate(SaveData data) {
    final errors = <String>[];

    if (data.saveVersion <= 0) {
      errors.add('saveVersion must be > 0 (got ${data.saveVersion})');
    }

    if (data.saveVersion > kCurrentSaveVersion) {
      errors.add(
        'saveVersion ${data.saveVersion} is newer than current '
        '$kCurrentSaveVersion — may be from a future version',
      );
    }

    if (data.slotId.isEmpty) {
      errors.add('slotId must not be empty');
    }

    if (data.playtimeSeconds < 0) {
      errors.add(
        'playtimeSeconds must be >= 0 (got ${data.playtimeSeconds})',
      );
    }

    // createdAt sanity: should not be before year 2020
    final epoch = DateTime(2020);
    if (data.createdAt.isBefore(epoch)) {
      errors.add('createdAt appears invalid: ${data.createdAt}');
    }

    if (data.updatedAt.isBefore(data.createdAt)) {
      errors.add('updatedAt is before createdAt');
    }

    return SaveValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Validate that [gameData] contains all [requiredKeys].
  SaveValidationResult validateGameData(
    Map<String, dynamic> gameData,
    List<String> requiredKeys,
  ) {
    final errors = <String>[];
    for (final key in requiredKeys) {
      if (!gameData.containsKey(key)) {
        errors.add('Missing required game data key: $key');
      }
    }
    return SaveValidationResult(isValid: errors.isEmpty, errors: errors);
  }
}
