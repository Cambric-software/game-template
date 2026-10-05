# Security Policy

## Cambric Game Template — Security Principles

### Local-first design

The Cambric Game Template is designed to work without any mandatory server. No Cambric server is required for any core game feature. Player data lives on the player's device.

### No tracking by default

The template contains no:
- Analytics SDK
- Advertising SDK
- Remote telemetry
- Player profiling
- Hidden network calls

Network activity is limited to:
- GitHub Releases API for update checks (opt-in via `FeatureFlags.updateChecks`)
- Any network features your specific game adds

### Save file integrity

Every save is protected by a SHA-256 checksum. On load:
1. The checksum is verified before any data is read
2. If the primary save is corrupt, the backup is tried automatically
3. A failed checksum triggers a diagnostic log entry, not a silent failure

### Update verification

Before installing any update:
1. The downloaded artifact's SHA-256 checksum is verified against the release metadata
2. A backup of the current installation is created before extraction
3. On verification failure, the update is rejected and the current installation is preserved

### Safe file operations

All file writes that could corrupt user data use the atomic write pattern:
1. Write to `.tmp` file
2. Read-back verify
3. Rename to final path (atomic on NTFS/ext4)

No user data file is overwritten in-place.

### Path validation

All file paths provided by players or derived from save data are validated:
- No directory traversal (`..`)
- No null bytes
- No absolute paths outside the game data directory

### Dependency security

Dependencies are audited in CI via `dart pub audit`. The security workflow runs weekly and on every push.

### Secret handling

No secrets, API keys, or credentials should be committed to this repository. The `.gitignore` excludes:
- `.env` files
- `key.properties` (Android signing)
- `*.jks` / `*.keystore` (Android signing keys)
- `google-services.json`

The CI security workflow fails if pattern-matched secrets are found in source files.

### Reporting a vulnerability

Please report security vulnerabilities by opening a GitHub Security Advisory in the repository rather than a public issue. Include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if known)

We aim to respond within 5 business days.
