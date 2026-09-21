import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import 'app_theme.dart';

/// Çizgi Bulmaca — Tema Provider
/// Koyu/Açık mod + kullanıcı renk seçimi yönetimi.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Color _primaryColor = AppColors.primary;

  ThemeProvider() {
    _loadPreferences();
  }

  // ─── Getters ─────────────────────────────────────────────
  ThemeMode get themeMode => _themeMode;
  Color get primaryColor => _primaryColor;

  ThemeData get lightTheme => AppTheme.lightTheme(primaryColor: _primaryColor);
  ThemeData get darkTheme => AppTheme.darkTheme(primaryColor: _primaryColor);

  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isSystemMode => _themeMode == ThemeMode.system;

  // ─── Setters ─────────────────────────────────────────────
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyThemeMode, mode.name);
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }

  Future<void> setPrimaryColor(Color color) async {
    _primaryColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    // ignore: deprecated_member_use
    await prefs.setInt(AppConstants.keyThemeColor, color.value);
  }

  // ─── Load Preferences ───────────────────────────────────
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Tema modu
    final themeModeStr = prefs.getString(AppConstants.keyThemeMode);
    if (themeModeStr != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == themeModeStr,
        orElse: () => ThemeMode.system,
      );
    }

    // Renk seçimi
    final colorValue = prefs.getInt(AppConstants.keyThemeColor);
    if (colorValue != null) {
      _primaryColor = Color(colorValue);
    }

    notifyListeners();
  }
}
