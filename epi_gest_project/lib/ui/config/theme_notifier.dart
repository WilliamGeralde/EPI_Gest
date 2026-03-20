import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeOption {
  light,
  dark,
  system,
}

class ThemeNotifier extends ChangeNotifier {
  ThemeOption _themeOption = ThemeOption.system;
  static const String _themeKey = 'theme_preference';

  ThemeNotifier() {
    _loadThemePreference();
  }

  ThemeOption get themeOption => _themeOption;

  ThemeMode get themeMode {
    switch (_themeOption) {
      case ThemeOption.light:
        return ThemeMode.light;
      case ThemeOption.dark:
        return ThemeMode.dark;
      case ThemeOption.system:
        return ThemeMode.system;
    }
  }

  Future<void> setTheme(ThemeOption option) async {
    _themeOption = option;
    notifyListeners();
    await _saveThemePreference(option);
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? ThemeOption.system.index;
    _themeOption = ThemeOption.values[themeIndex];
    notifyListeners();
  }

  Future<void> _saveThemePreference(ThemeOption option) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, option.index);
  }
}
