# Building

## Using the CLI

```bash
dart run scripts/cambric.dart build windows   # Windows release
dart run scripts/cambric.dart build android   # Android APK
dart run scripts/cambric.dart build linux     # Linux (Linux host or CI)
```

The CLI wraps the same Flutter commands documented below.

---

## Windows

**Requirements:** Visual Studio 2022 with the "Desktop development with C++"
workload and the Windows 10/11 SDK.

```bash
cd game
flutter build windows --release
```

Output: `game/build/windows/x64/runner/Release/`.

Distribute the whole folder; the `.exe` depends on the DLLs and `data/` beside
it. The template does not ship an installer script. Use Inno Setup, WiX, or
MSIX if you need one.

For a debug build with the overlay:

```bash
flutter build windows --debug
```

---

## Android

**Requirements:** Android SDK 36+, Java 17+, accepted licenses.

```bash
flutter doctor --android-licenses
cd game
flutter build apk --release          # APK
flutter build appbundle --release    # AAB for Play Store
```

Output:

- APK: `game/build/app/outputs/flutter-apk/app-release.apk`
- AAB: `game/build/app/outputs/bundle/release/app-release.aab`

The template uses the debug signing config for release builds so CI can build
without secrets. Configure `android/key.properties` and a release keystore
before publishing; the file is already gitignored.

---

## Linux

Linux builds require a Linux toolchain and cannot run on a Windows host.

The `ci.yml` workflow builds on `ubuntu-latest`. To build locally:

```bash
sudo apt-get install clang cmake ninja-build pkg-config \
  libgtk-3-dev liblzma-dev libstdc++-12-dev \
  libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
  gstreamer1.0-plugins-good gstreamer1.0-plugins-bad

cd game
flutter build linux --release
```

Output: `game/build/linux/x64/release/bundle/`.

GStreamer packages are required by `audioplayers_linux` (through Flame Audio).

---

## Clean Build

```bash
dart run scripts/cambric.dart clean
cd game
flutter pub get
flutter build windows --release
```

Close running app instances first. On Windows, an open `game.exe` locks its DLLs
and the link step fails with a file-in-use error.

---

## Versioning

```bash
dart run scripts/cambric.dart release 1.2.0
```

This updates `cambric.manifest.json` and `game/pubspec.yaml` together. Commit
both files, then tag `v1.2.0` to publish a release.

---

## CI and Releases

`.github/workflows/ci.yml` runs on every push and pull request:

- analyze and test on Ubuntu
- Android APK on Ubuntu
- Linux bundle on Ubuntu
- Windows release on `windows-latest`

Artifacts are kept for 7 days.

`.github/workflows/release.yml` runs on tags matching `v*.*.*`. It runs analyze
and tests again, builds all three platforms, writes `.sha256` files, and creates
a GitHub Release with the archives.

`.github/workflows/security.yml` runs the dependency audit and secret scan on
push, pull request, and weekly.
