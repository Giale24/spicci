import 'package:flutter/material.dart';

class AppThemePalette {
  final String id;
  final String name;
  final IconData icon;
  final bool isDark;

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceCard;
  final Color surfaceKeypad;
  final Color border;
  final Color borderLight;

  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color primaryAccent;

  final Color goldCoin;
  final Color cyan;
  final Color mint;
  final Color amber;
  final Color amberLight;
  final Color red;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  const AppThemePalette({
    required this.id,
    required this.name,
    required this.icon,
    required this.isDark,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceCard,
    required this.surfaceKeypad,
    required this.border,
    required this.borderLight,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.primaryAccent,
    this.goldCoin = const Color(0xFFFFC107),
    this.cyan = const Color(0xFF22D3EE),
    this.mint = const Color(0xFF10B981),
    this.amber = const Color(0xFFF59E0B),
    this.amberLight = const Color(0xFFFFD54F),
    this.red = const Color(0xFFF43F5E),
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });
}

class AppPalettes {
  // 1. Viola Notte (Predefinito Spicci)
  static const darkPurple = AppThemePalette(
    id: 'dark_purple',
    name: 'Viola Notte',
    icon: Icons.nightlight_round,
    isDark: true,
    background: Color(0xFF0F0E17),
    surface: Color(0xFF181624),
    surfaceElevated: Color(0xFF221F33),
    surfaceCard: Color(0xFF1C1A2B),
    surfaceKeypad: Color(0xFF252238),
    border: Color(0xFF2E2A44),
    borderLight: Color(0xFF3E395B),
    primary: Color(0xFFA855F7),
    primaryDark: Color(0xFF7E22CE),
    primaryLight: Color(0xFFC084FC),
    primaryAccent: Color(0xFFE9D5FF),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFFCBD5E1),
    textMuted: Color(0xFF94A3B8),
  );

  // 2. Verde Menta (Fresco / Originale Spicci)
  static const darkMint = AppThemePalette(
    id: 'dark_mint',
    name: 'Verde Menta',
    icon: Icons.eco_rounded,
    isDark: true,
    background: Color(0xFF0B1411),
    surface: Color(0xFF11221D),
    surfaceElevated: Color(0xFF182E27),
    surfaceCard: Color(0xFF142621),
    surfaceKeypad: Color(0xFF1A332B),
    border: Color(0xFF1F3D34),
    borderLight: Color(0xFF2B5246),
    primary: Color(0xFF10B981),
    primaryDark: Color(0xFF059669),
    primaryLight: Color(0xFF34D399),
    primaryAccent: Color(0xFFA7F3D0),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFFCBD5E1),
    textMuted: Color(0xFF86A398),
  );

  // 3. Ambra & Oro (Caldo & Raffinato)
  static const darkAmber = AppThemePalette(
    id: 'dark_amber',
    name: 'Ambra Oro',
    icon: Icons.workspace_premium_rounded,
    isDark: true,
    background: Color(0xFF14100A),
    surface: Color(0xFF1E1810),
    surfaceElevated: Color(0xFF2B2317),
    surfaceCard: Color(0xFF231C13),
    surfaceKeypad: Color(0xFF30271A),
    border: Color(0xFF3D3220),
    borderLight: Color(0xFF54452C),
    primary: Color(0xFFF59E0B),
    primaryDark: Color(0xFFD97706),
    primaryLight: Color(0xFFFBBF24),
    primaryAccent: Color(0xFFFDE68A),
    textPrimary: Color(0xFFFFFBEB),
    textSecondary: Color(0xFFE2D9C8),
    textMuted: Color(0xFFA39682),
  );

  // 4. Oceano Blu (Profondo & Elettrico)
  static const darkOcean = AppThemePalette(
    id: 'dark_ocean',
    name: 'Oceano Blu',
    icon: Icons.water_drop_rounded,
    isDark: true,
    background: Color(0xFF0A111E),
    surface: Color(0xFF0F1A2D),
    surfaceElevated: Color(0xFF162540),
    surfaceCard: Color(0xFF122036),
    surfaceKeypad: Color(0xFF1A2C4C),
    border: Color(0xFF21375B),
    borderLight: Color(0xFF2E4B7A),
    primary: Color(0xFF0EA5E9),
    primaryDark: Color(0xFF0284C7),
    primaryLight: Color(0xFF38BDF8),
    primaryAccent: Color(0xFFBAE6FD),
    textPrimary: Color(0xFFF0F9FF),
    textSecondary: Color(0xFFBAE6FD),
    textMuted: Color(0xFF7DD3FC),
  );

  // 5. Luce Minimal (Tema Chiaro Moderno ad Alto Contrasto)
  static const lightClean = AppThemePalette(
    id: 'light_clean',
    name: 'Luce Minimal',
    icon: Icons.wb_sunny_rounded,
    isDark: false,
    background: Color(0xFFF1F5F9),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF8FAFC),
    surfaceCard: Color(0xFFFFFFFF),
    surfaceKeypad: Color(0xFFE2E8F0),
    border: Color(0xFFE2E8F0),
    borderLight: Color(0xFFCBD5E1),
    primary: Color(0xFF7C3AED),
    primaryDark: Color(0xFF5B21B6),
    primaryLight: Color(0xFF6D28D9),
    primaryAccent: Color(0xFF7C3AED),
    goldCoin: Color(0xFFD97706),
    cyan: Color(0xFF0284C7),
    mint: Color(0xFF059669),
    amber: Color(0xFFD97706),
    amberLight: Color(0xFFB45309),
    red: Color(0xFFDC2626),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF334155),
    textMuted: Color(0xFF64748B),
  );

  static const List<AppThemePalette> all = [
    darkPurple,
    darkMint,
    darkAmber,
    darkOcean,
    lightClean,
  ];

  static AppThemePalette byId(String id) {
    return all.firstWhere((p) => p.id == id, orElse: () => darkPurple);
  }
}
