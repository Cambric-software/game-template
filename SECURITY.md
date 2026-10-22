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
- GitHub Releases API when your game calls `UpdateService.checkForUpdate()`
  (disabled by default; enable with `FeatureFlags.updateChecks`)
- Any network features your specific game adds

The template never starts a network request on its own.

### Save file integrity

Every save is protected by a SHA-256 checksum. On load:
1. The checksum is verified before any data is used
2. If the primary save is corrupt, the backup is tried automatically
3. A failed checksum triggers a diagnostic log entry, not a silent failure

### Update checks

`UpdateService` only checks GitHub Releases for a newer version and returns a
release URL. It does not download or install anything.

If you add an installer, you own its safety:
1. Download over HTTPS and verify the artifact's SHA-256 against the release
   metadata before extracting it
2. Back up the current installation first
3. Reject the update and keep the current installation if verification fails

The release workflow publishes `.sha256` files for this purpose.

### Safe file operations

All file writes that could corrupt user data use the atomic write pattern:
1. Write to `.tmp` file
2. Read-back verify
3. Rename to final path (atomic on NTFS/ext4)

No user data file is overwritten in-place.

### Path validation

Save slots are fixed identifiers, not player-supplied paths, so the save system
never builds a path from arbitrary input.

If your game accepts a filename or path from a player, validate it at the
boundary with `SecurityService.isPathSafe` and `sanitizeFilename`:
- No directory traversal (`..`)
- No null bytes
- No absolute paths outside the game data directory

### Dependency security

The security workflow reports outdated dependencies and scans source for
hardcoded secrets on every push and weekly. Dart has no built-in CVE audit;
add OSV-Scanner or your registry's audit tool if you need advisory matching.

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
