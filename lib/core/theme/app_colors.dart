import 'package:flutter/material.dart';

/// All color constants for the Mood Tracker app.
/// Based on design palette: Sky Blue, Slate Blue, Soft Rose, Blush.
class AppColors {
  AppColors._();

  // ─── Primary ───────────────────────────────────────────────────
  /// Sky Blue — calendar bg, section headers, teal accents
  static const Color primary = Color(0xFF9ECAD6);

  /// Slate Blue — secondary actions, nav active, "your" highlight
  static const Color secondary = Color(0xFF748DAE);

  // ─── Accent ────────────────────────────────────────────────────
  /// Soft Rose — mood circles, "Pause" highlight, icon backgrounds
  static const Color accent = Color(0xFFF5CBCB);

  /// Blush — quick action card bg, soft surface areas
  static const Color surface = Color(0xFFFFEAEA);

  // ─── Sage Green — "Things To Do" button, activity icons ────────
  static const Color sage = Color(0xFF7BAE8F);
  static const Color sageLight = Color(0xFFE8F5EE);

  // ─── Neutral ───────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF1A1A2E);

  // ─── Background ────────────────────────────────────────────────
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundSecondary = Color(0xFFF8FAFB);

  // ─── Text ──────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF5A6A7E);
  static const Color textHint = Color(0xFFABB8C3);
  static const Color textOnPrimary = Color(0xFF1A4A54);
  static const Color textOnSage = Color(0xFFFFFFFF);

  // ─── Highlight (inline text colors) ───────────────────────────
  /// Used for "Pause" word highlight
  static const Color highlightPink = Color(0xFFE07B8A);

  /// Used for "your" word highlight
  static const Color highlightTeal = Color(0xFF4A9BAD);

  // ─── Border ────────────────────────────────────────────────────
  static const Color border = Color(0xFFE4ECF0);
  static const Color borderPrimary = Color(0xFF9ECAD6);

  // ─── Mood Palette ──────────────────────────────────────────────
  static const Color moodGreat = Color(0xFF748DAE);
  static const Color moodGood = Color(0xFF9ECAD6);
  static const Color moodOkay = Color(0xFFF5CBCB);
  static const Color moodSad = Color(0xFFFFEAEA);
  static const Color moodBad = Color(0xFFE8A0A0);

  /// Default mood circle background (pink soft)
  static const Color moodCircle = Color(0xFFF5CBCB);
  static const Color moodCircleEmpty = Color(0xFFFFFFFF);

  // ─── Semantic ──────────────────────────────────────────────────
  static const Color success = Color(0xFF7BAE8F);
  static const Color warning = Color(0xFFF5C97A);
  static const Color error = Color(0xFFE07B7B);
  static const Color info = Color(0xFF9ECAD6);

  // ─── Gradients ─────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient softPinkGradient = LinearGradient(
    colors: [surface, accent],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
