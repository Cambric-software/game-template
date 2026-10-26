# Troubleshooting

## Linux build fails on CI

If the Linux build fails with a GStreamer or audio-related error, install the required audio libraries:

```yaml
- name: Install Linux build dependencies
  run: |
    sudo apt-get install -y \
      clang cmake ninja-build pkg-config \
      libgtk-3-dev liblzma-dev libstdc++-12-dev \
      libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
      gstreamer1.0-plugins-good gstreamer1.0-plugins-bad
```

`audioplayers_linux` (pulled in by `flame_audio`) requires GStreamer on Ubuntu. Both `ci.yml` and `release.yml` already include these packages.

---

## `jni` 1.1.0 build failure

**Symptom:** `flutter build windows` fails with:

```
The plugin `jni` doesn't have a main class defined in JniPlugin.java or JniPlugin.kt.
```

**Cause:** The `jni 1.1.0` pub.dev artifact is missing the `JniPlugin.java` file. This is a corrupted upstream package.

**Fix:** `game/pubspec.yaml` already includes the workaround:

```yaml
dependency_overrides:
  jni: 1.0.3
  jni_flutter: 1.0.3
```

If you see this error after updating dependencies, ensure these overrides are still present.

**Remove when:** `jni` publishes a fixed release and the override is no longer needed.

---

## `audioplayers:windows` plugin warning

**Symptom:**

```
Package audioplayers:windows references audioplayers_windows:windows as the default plugin,
but the package does not exist, or is not a plugin package.
```

**Fix:** `game/pubspec.yaml` already includes `audioplayers_windows: ^4.4.1` as an explicit dependency. If you removed it, add it back. Also ensure the package is fully fetched:

```bash
dart pub cache repair
flutter pub get
```

---

## Build behaves unexpectedly after code changes

Run a clean build:

```bash
dart run scripts/cambric.dart clean
cd game && flutter pub get
flutter build windows --debug
```

---

## Android license not accepted

```bash
flutter doctor --android-licenses
```

Accept all licenses. Then run `flutter doctor` to confirm the Android toolchain is green.

---

## Linux build on Windows host

Linux builds are not supported on Windows. Use GitHub Actions (`ubuntu-latest`). The `ci.yml` workflow builds Linux automatically on push and pull request.

---

## SaveService not initialized error

**Symptom:** `StateError: SaveService not initialized. Call initialize() first.`

**Cause:** `SaveService.initialize(gameId)` was not called before the first save/load attempt.

**Fix:** This is handled automatically in `BootstrapService.initialize()` as of v0.1.0. If you see this error, ensure you are using the latest `bootstrap_service.dart` and not calling `SaveService()` before bootstrap completes.

---

## Save file corruption

If `SaveService.load()` returns `SaveResult.corrupt`:

1. The `.sav.bak` backup was also unreadable
2. Check the console output or run `dart run scripts/cambric.dart diagnose`
3. Run `dart run scripts/cambric.dart save validate <path>` to inspect the file
4. Do NOT manually edit `.sav` files — the checksum will no longer match

To reset a slot: call `SaveService.deleteSave(slot)` from the game's settings/debug menu.

---

## Game update check network errors

`UpdateService.checkForUpdate()` is non-fatal: a network failure returns an
error result and the game keeps running.

1. Update checks are disabled by default. Set `FeatureFlags.updateChecks = true`
   before calling the service.
2. The `repository` field in `cambric.manifest.json` must name a GitHub repo,
   for example `Cambric-software/my-game`.
3. The GitHub API is rate-limited for unauthenticated requests. Cache the last
   good result instead of checking on every launch.

The template does not download or install updates. See `SECURITY.md` before
adding an installer.

---

## `flutter run` fails to find device

```bash
flutter devices        # list connected devices
flutter run -d windows # explicit device target
```

On Android: connect a physical device with USB debugging enabled, or create an AVD:
```bash
flutter emulators --create --name pixel
flutter emulators --launch pixel
```

---

## Debug overlay not showing

The overlay only appears when `FeatureFlags.debugOverlay == true`, which requires `kDebugMode == true` (debug builds only). Make sure you're running a debug build, not a release build:

```bash
flutter run -d windows           # debug by default
flutter build windows --debug    # explicit debug build
```

Press F1 to cycle the overlay between hidden / minimal / full.

---

## `flutter test` hangs or fails on `build/unit_test_assets`

**Symptom:** the test run stalls with no output, or fails while deleting
`game/build/unit_test_assets`.

**Cause:** another Flutter process (an IDE, a running app, or a previous test
run) still holds the directory.

**Fix:** close the other process, wait a few seconds, delete `game/build/`, then
run `flutter test` again. The test runner recreates the asset bundle.
