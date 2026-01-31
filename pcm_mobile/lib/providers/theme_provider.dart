import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  ThemeMode _themeMode = ThemeMode.system;
  bool _loaded = false;

  ThemeMode get themeMode => _themeMode;
  bool get loaded => _loaded;

  Future<void> loadTheme() async {
    final saved = await _storage.read(key: 'theme_mode');
    _themeMode = _fromString(saved);
    _loaded = true;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _storage.write(key: 'theme_mode', value: _asString(mode));
    notifyListeners();
  }

  ThemeMode _fromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _asString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      default:
        return 'system';
    }
  }
}
