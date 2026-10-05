# Environment Audit

> Audit performed: 2026-10-04
> Template: Cambric Game Template
> Phase: 0 — Pre-implementation

---

## 1. Operating System

| Property | Value |
|---|---|
| OS | Microsoft Windows 11 (25H2) |
| Build | 10.0.26200.9457 |
| Architecture | x86-64 |

---

## 2. Languages and Runtimes

| Tool | Version | Status |
|---|---|---|
| Dart SDK | 3.13.2 (stable) | ✅ Available |
| Python | 3.12.10 | ✅ Available |
| Node.js | 24.19.0 | ✅ Available |
| npm | 11.17.0 | ✅ Available |
| Java (Temurin) | 17.0.20.1+1 | ✅ Available (via Flutter config) |
| Rust | — | ❌ Not installed |
| Go | — | ❌ Not installed |

---

## 3. Flutter SDK

| Property | Value |
|---|---|
| Version | 3.47.2 |
| Channel | stable |
| Dart bundled | 3.13.2 |
| DevTools | 2.60.0 |
| Install location | C:\src\flutter |

Flutter doctor reports **no issues**. All checks pass.

---

## 4. Android Toolchain

| Property | Value |
|---|---|
| Android SDK location | C:\Users\m\AppData\Local\Android\Sdk |
| SDK version | 36.0.0 |
| Platform | android-37.0 |
| Build tools | 36.0.0 |
| Java | OpenJDK Temurin 17.0.20.1+1 |
| Emulator | 37.1.11.0 (no AVDs configured) |
| Licenses | Accepted |

Android builds are possible. No physical device is currently connected; a physical device or emulator must be created to run on Android.

---

## 5. Windows Build Tooling

| Property | Value |
|---|---|
| Visual Studio | Community 2022 17.14.39 |
| Windows 10 SDK | 10.0.28000.0 |

`flutter build windows` works fully.

---

## 6. Linux Build Tooling

Linux toolchain (GCC, CMake, ninja, GTK headers) is **not available** on this Windows host. Linux builds are delegated to GitHub Actions `ubuntu-latest`.

---

## 7. Package Managers

| Tool | Status |
|---|---|
| pub (Dart) | ✅ bundled with Dart 3.13.2 |
| npm | ✅ 11.17.0 |
| pip | ✅ bundled with Python 3.12 |

Key packages already in local pub cache: `shared_preferences`, `path_provider`, `http`, `crypto`, `logging`, `intl`, `uuid`, `archive`, `args`, `flutter_lints`.

Notable absence: `flame`, `audioplayers` — will be fetched on `flutter pub get`.

---

## 8. Connected Devices

| Device | Status |
|---|---|
| Windows desktop | ✅ Primary test target |
| Chrome browser | ✅ Available (not primary) |
| Android device/emulator | ❌ Not connected |

---

## 9. Git

| Version | Status |
|---|---|
| 2.55.0.windows.4 | ✅ Available |

---

## 10. Target Platform Build Status

| Platform | Local build | Notes |
|---|---|---|
| Windows x64 | ✅ Yes | VS 2022 + Windows SDK |
| Android APK/AAB | ✅ Yes | SDK + Java present; runtime test needs device |
| Linux x64 | ❌ No | Linux toolchain absent; use GitHub CI |
| Web | ✅ Yes | Available but not primary target |

---

## Summary

Windows 11 host with Flutter 3.47.2, Dart 3.13.2, full Android toolchain, and Visual Studio 2022. Can produce Windows and Android builds directly. Linux builds require CI. All development can proceed immediately.
