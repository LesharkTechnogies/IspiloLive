import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _largeTextKey = 'large_text_enabled';

  ThemeMode _themeMode = ThemeMode.system;
  bool _largeTextEnabled = false;

  ThemeMode get themeMode => _themeMode;
  bool get largeTextEnabled => _largeTextEnabled;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  bool get isSystemTheme => _themeMode == ThemeMode.system;

  ThemeProvider() {
    _loadThemeMode();
    _loadLargeText();
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeIndex =
          prefs.getInt(_themeModeKey) ?? ThemeMode.system.index;
      _themeMode = ThemeMode.values[themeModeIndex];
      notifyListeners();
    } catch (e) {
      // If reading preferences fails, fall back to system theme.
      _themeMode = ThemeMode.system;
      // swallow intentionally; no further action needed here
    }
  }

  Future<void> _loadLargeText() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _largeTextEnabled = prefs.getBool(_largeTextKey) ?? false;
      notifyListeners();
    } catch (e) {
      // If reading preferences fails, default to false and continue.
      _largeTextEnabled = false;
      // swallow intentionally
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_themeModeKey, mode.index);
      } catch (e) {
        // ignore storage errors
      }
    }
  }

  Future<void> setLargeTextEnabled(bool enabled) async {
    if (_largeTextEnabled != enabled) {
      _largeTextEnabled = enabled;
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_largeTextKey, enabled);
      } catch (e) {
        // ignore storage errors
      }
    }
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.system);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }

  String getThemeModeName() {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
}
