import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/themes.dart'; // We'll create this next

class ThemeProvider with ChangeNotifier {
  late CupertinoThemeData _themeData;
  late String _themeName;

  CupertinoThemeData get themeData => _themeData;
  String get themeName => _themeName;

  ThemeProvider() {
    _themeName = 'System'; // Default
    _themeData = systemTheme; // Default
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _themeName = prefs.getString('themeName') ?? 'System';
    _themeData = getThemeByName(_themeName);
    notifyListeners();
  }

  Future<void> setTheme(String themeName) async {
    _themeName = themeName;
    _themeData = getThemeByName(_themeName);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeName', themeName);
  }
}