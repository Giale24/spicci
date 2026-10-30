import 'package:flutter/material.dart';
import 'app_palettes.dart';

/// Palette colori dinamica per Spicci, personalizzabile con temi multipli (Dark e Light).
class AppColors {
  static AppThemePalette _current = AppPalettes.darkPurple;

  static AppThemePalette get current => _current;

  static void setPalette(AppThemePalette palette) {
    _current = palette;
  }

  // Sfondi e Superfici
  static Color get background => _current.background;
  static Color get surface => _current.surface;
  static Color get surfaceElevated => _current.surfaceElevated;
  static Color get surfaceCard => _current.surfaceCard;
  static Color get surfaceKeypad => _current.surfaceKeypad;
  static Color get border => _current.border;
  static Color get borderLight => _current.borderLight;

  // Accenti Principali
  static Color get purple => _current.primary;
  static Color get purpleDark => _current.primaryDark;
  static Color get purpleLight => _current.primaryLight;
  static Color get lilac => _current.primaryAccent;

  // Accenti Secondari
  static Color get goldCoin => _current.goldCoin;
  static Color get cyan => _current.cyan;
  static Color get mint => _current.mint;
  static Color get amber => _current.amber;
  static Color get amberLight => _current.amberLight;

  // Stati & Feedback
  static Color get red => _current.red;

  // Testo
  static Color get textPrimary => _current.textPrimary;
  static Color get textSecondary => _current.textSecondary;
  static Color get textMuted => _current.textMuted;
}
