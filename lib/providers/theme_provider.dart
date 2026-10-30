import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_palettes.dart';

class ThemeNotifier extends StateNotifier<AppThemePalette> {
  static const _prefKey = 'spicci_selected_theme_id';

  ThemeNotifier() : super(AppPalettes.darkPurple) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_prefKey);
    if (savedId != null) {
      final palette = AppPalettes.byId(savedId);
      AppColors.setPalette(palette);
      state = palette;
    }
  }

  Future<void> selectTheme(AppThemePalette palette) async {
    AppColors.setPalette(palette);
    state = palette;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, palette.id);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemePalette>((ref) {
  return ThemeNotifier();
});
