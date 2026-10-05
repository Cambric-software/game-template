# Save System

## Architecture

```
SaveData (model)
    ↓
SaveService.save(slot, data)
    ↓
Serialize to JSON
    ↓
Write to <slot>.sav.tmp
    ↓
Read-back verify
    ↓
Rename .tmp → .sav   ← atomic commit
    ↓
Copy .sav → .sav.bak ← backup
```

On **load**:

```
Read .sav
    ↓
Verify checksum (SHA-256)
    ↓
If corrupt: try .sav.bak
    ↓
Run SaveMigration if saveVersion < current
    ↓
Return SaveData
```

The previous valid save is **never overwritten** before the new one is verified.

---

## Save Slots

Default slots defined in `SaveSlot`:

| Slot ID | Display name | Notes |
|---|---|---|
| `autosave` | Auto Save | Written by AutosaveService |
| `slot_1` | Slot 1 | Manual save |
| `slot_2` | Slot 2 | Manual save |
| `slot_3` | Slot 3 | Manual save |

The number of slots is configurable via the setup wizard.

---

## Save File Location

Platform-dependent, resolved by `PlatformService`:

| Platform | Location |
|---|---|
| Windows | `%APPDATA%\Cambric\Games\<gameId>\saves\` |
| Android | App internal storage `files/Cambric/Games/<gameId>/saves/` |
| Linux | `~/.local/share/Cambric/Games/<gameId>/saves/` |

---

## Save Format

Each `.sav` file is a JSON envelope:

```json
{
  "data": "{\"saveVersion\":1,\"slotId\":\"slot_1\",...}",
  "checksum": "sha256hexstring"
}
```

The checksum covers the inner `data` string, not the envelope.

---

## Adding Game Data

Add fields to the `gameData` map in `SaveData`:

```dart
final save = SaveData(
  saveVersion: kCurrentSaveVersion,
  slotId: 'slot_1',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  playtimeSeconds: session.elapsed,
  gameData: {
    'level': 3,
    'score': 2500,
    'playerHp': 85,
    'inventory': ['sword', 'potion'],
  },
);
await saveService.save(SaveSlot.slot1, save);
```

---

## Migration

Every format change must have a migration step. Add to `lib/save/save_migration.dart`:

```dart
static final List<_MigrationStep> _steps = [
  _MigrationStep(
    fromVersion: 1,
    toVersion: 2,
    migrate: _v1ToV2,
  ),
];

static SaveData _v1ToV2(SaveData data) {
  final newData = Map<String, dynamic>.from(data.gameData);
  // rename 'hp' to 'playerHp'
  newData['playerHp'] = newData.remove('hp') ?? 100;
  return data.copyWith(saveVersion: 2, gameData: newData);
}
```

Increment `kCurrentSaveVersion` when adding a step.

---

## Corruption Protection

If the primary save is corrupted:
1. `SaveService` reads `.sav.bak` automatically
2. If backup is also corrupt, returns `SaveResult.corrupt`
3. The game receives `null` data and a clear error code
4. **Never** silently discards corrupt saves or starts a new game without user consent

---

## Autosave

`AutosaveService` triggers saves every 5 minutes by default during active play sessions. Interval is configurable. Autosave respects `FeatureFlags.autosaveEnabled` and `SettingsService.autosaveEnabled`.

A failed autosave logs a warning — it never crashes the game.
