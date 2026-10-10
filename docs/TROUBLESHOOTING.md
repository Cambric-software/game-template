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

`audioplayers_linux` (pulled in by `flame_audio`) requires GStreamer on Ubuntu. All three CI workflow files (ci.yml, build.yml, release.yml) already include these packages.

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

Linux builds are not supported on Windows. Use GitHub Actions (`ubuntu-latest`). The `.github/workflows/build.yml` workflow handles Linux builds automatically on push to `main`.

---

## SaveService not initialized error

**Symptom:** `StateError: SaveService not initialized. Call initialize() first.`

**Cause:** `SaveService.initialize(gameId)` was not called before the first save/load attempt.

**Fix:** This is handled automatically in `BootstrapService.initialize()` as of v0.1.0. If you see this error, ensure you are using the latest `bootstrap_service.dart` and not calling `SaveService()` before bootstrap completes.

---

## Save file corruption

If `SaveService.load()` returns `SaveResult.corrupt`:

If `SaveService.load()` returns `SaveResult.corrupt`:

1. The `.sav.bak` backup was also unreadable
2. Check `logs/` directory for diagnostic entries
3. Run `dart run scripts/cambric.dart save validate <path>` to inspect the file
4. Do NOT manually edit `.sav` files — the checksum will no longer match

To reset a slot: call `SaveService.deleteSave(slot)` from the game's settings/debug menu.

---

## Update check network errors

If `cambric update check` fails with a network error:

1. The update check is non-fatal — the game continues normally
2. Check your internet connection
3. If the repository field in `cambric.manifest.json` is empty, update check is disabled

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
