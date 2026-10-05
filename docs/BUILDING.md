# Building

## Using the CLI

```bash
dart run scripts/cambric.dart build windows   # Windows release
dart run scripts/cambric.dart build android   # Android APK
dart run scripts/cambric.dart build linux     # Linux (requires Linux host or CI)
```

---

## Windows

**Requirements:** Visual Studio 2022 with "Desktop development with C++" workload, Windows 10 SDK.

```bash
cd game
flutter build windows --release
```

Output: `game/build/windows/x64/runner/Release/`

The output directory contains the `.exe` and all required DLLs. Distribute this entire folder or package it with an installer (see `.template/distribution/windows_install.md`).

For a debug build (faster compile, with debug overlay):

```bash
flutter build windows --debug
```

---

## Android

**Requirements:** Android SDK 36+, Java 17+, accepted licenses (`flutter doctor --android-licenses`).

```bash
cd game
flutter build apk --release          # APK for sideloading/testing
flutter build appbundle --release     # AAB for Play Store
```

Output:
- APK: `game/build/app/outputs/flutter-apk/app-release.apk`
- AAB: `game/build/app/outputs/bundle/release/app-release.aab`

For signed release builds, create `game/android/key.properties` — see `.template/distribution/android_build.md`.

---

## Linux

Linux builds require a Linux toolchain. They are not supported on the Windows development host.

Build via GitHub Actions (`.github/workflows/build.yml`) or in a WSL2 environment with:

```bash
sudo apt-get install libgtk-3-dev libblkid-dev liblzma-dev ninja-build cmake clang
cd game && flutter build linux --release
```

Output: `game/build/linux/x64/release/bundle/`

---

## Clean Build

Before release or when encountering unexpected build behavior:

```bash
dart run scripts/cambric.dart clean
cd game && flutter pub get
flutter build windows --release
```

---

## Versioning

Before building a release:

```bash
dart run scripts/cambric.dart release 1.2.0
```

This updates `cambric.manifest.json` and `game/pubspec.yaml` atomically.

---

## CI Builds

All three platforms build automatically on GitHub Actions when pushing to `main` or `master`. See `.github/workflows/build.yml`.

Artifacts are uploaded and retained for 30 days.
