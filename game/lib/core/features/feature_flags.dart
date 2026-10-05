import 'package:flutter/foundation.dart' show kDebugMode;

/// Central feature flags for the Cambric game template.
///
/// Flags default to safe production values. Debug flags are
/// automatically enabled in debug builds via [initializeDefaults].
///
/// Game code reads flags but must not modify them at runtime
/// except through [FeatureFlags.override] in tests.
class FeatureFlags {
  FeatureFlags._();

  // ── Debug / developer ──────────────────────────────────────────────────
  static bool debugOverlay = false;
  static bool showHitboxes = false;
  static bool showCollisionShapes = false;
  static bool verboseLogging = false;
  static bool showPerformanceMetrics = false;
  static bool godMode = false; // disable damage in dev

  // ── Platform capabilities ──────────────────────────────────────────────
  static bool touchSupport = true;
  static bool keyboardSupport = true;
  static bool mouseSupport = true;
  static bool gamepadSupport = true;

  // ── Cambric infrastructure ─────────────────────────────────────────────
  static bool updateChecks = true;
  static bool networkFeatures = true;
  static bool diagnosticsEnabled = true;
  static bool autosaveEnabled = true;

  // ── Experimental ──────────────────────────────────────────────────────
  static bool experimentalFeatures = false;
  static bool modSupport = false;

  /// Set defaults based on build mode.
  /// Call once during [BootstrapService.initialize].
  static void initializeDefaults({bool? forceDev}) {
    final isDev = forceDev ?? kDebugMode;
    debugOverlay = isDev;
    showPerformanceMetrics = isDev;
    verboseLogging = isDev;
    // Safety: never enable godMode, hitboxes, or collision shapes by default
    // even in dev — developer must explicitly toggle them.
    showHitboxes = false;
    showCollisionShapes = false;
    godMode = false;
  }

  /// Override flags for testing purposes only.
  /// Not intended for production code paths.
  static void override({
    bool? debugOverlayValue,
    bool? verboseLoggingValue,
    bool? autosaveEnabledValue,
    bool? updateChecksValue,
    bool? networkFeaturesValue,
  }) {
    if (debugOverlayValue != null) debugOverlay = debugOverlayValue;
    if (verboseLoggingValue != null) verboseLogging = verboseLoggingValue;
    if (autosaveEnabledValue != null) autosaveEnabled = autosaveEnabledValue;
    if (updateChecksValue != null) updateChecks = updateChecksValue;
    if (networkFeaturesValue != null) networkFeatures = networkFeaturesValue;
  }
}
