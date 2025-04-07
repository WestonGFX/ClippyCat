import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  // Default values
  int _maxHistoryItems = 100;
  double _databaseSizeLimitMB = 256.0;
  bool _closeToTray = true;
  bool _encryptDatabase = false; // Placeholder - Requires implementation
  bool _autoCleanupEnabled = false;
  int _autoCleanupDays = 60;
  bool _warnDbSize = true;
  bool _warnItemCount = true;
  bool _compressImages = false; // Placeholder
  int _imageCompressionQuality = 75; // Placeholder (e.g., 0-100)
  bool _editAutoSave = true;
  int _editAutoSaveSeconds = 2;
  String _clipboardMonitorFrequency = 'Instant'; // Placeholder
  // Appearance
  String _fontFamily = 'SystemDefault'; // Special value for system font
  double _fontSizeModifier = 1.0; // 1.0 is default
  double _paddingScale = 1.0; // 1.0 is default

  // --- Getters ---
  int get maxHistoryItems => _maxHistoryItems;
  double get databaseSizeLimitMB => _databaseSizeLimitMB;
  bool get closeToTray => _closeToTray;
  bool get encryptDatabase => _encryptDatabase;
  bool get autoCleanupEnabled => _autoCleanupEnabled;
  int get autoCleanupDays => _autoCleanupDays;
  bool get warnDbSize => _warnDbSize;
  bool get warnItemCount => _warnItemCount;
  bool get compressImages => _compressImages;
  int get imageCompressionQuality => _imageCompressionQuality;
  bool get editAutoSave => _editAutoSave;
  int get editAutoSaveSeconds => _editAutoSaveSeconds;
  String get clipboardMonitorFrequency => _clipboardMonitorFrequency;
  String get fontFamily => _fontFamily;
  double get fontSizeModifier => _fontSizeModifier;
  double get paddingScale => _paddingScale;


  SettingsProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _maxHistoryItems = prefs.getInt('maxHistoryItems') ?? 100;
    _databaseSizeLimitMB = prefs.getDouble('databaseSizeLimitMB') ?? 256.0;
    _closeToTray = prefs.getBool('closeToTray') ?? true;
    _encryptDatabase = prefs.getBool('encryptDatabase') ?? false;
    _autoCleanupEnabled = prefs.getBool('autoCleanupEnabled') ?? false;
    _autoCleanupDays = prefs.getInt('autoCleanupDays') ?? 60;
    _warnDbSize = prefs.getBool('warnDbSize') ?? true;
    _warnItemCount = prefs.getBool('warnItemCount') ?? true;
    _compressImages = prefs.getBool('compressImages') ?? false;
    _imageCompressionQuality = prefs.getInt('imageCompressionQuality') ?? 75;
    _editAutoSave = prefs.getBool('editAutoSave') ?? true;
    _editAutoSaveSeconds = prefs.getInt('editAutoSaveSeconds') ?? 2;
    _clipboardMonitorFrequency = prefs.getString('clipboardMonitorFrequency') ?? 'Instant';
    _fontFamily = prefs.getString('fontFamily') ?? 'SystemDefault';
    _fontSizeModifier = prefs.getDouble('fontSizeModifier') ?? 1.0;
    _paddingScale = prefs.getDouble('paddingScale') ?? 1.0;

    notifyListeners(); // Notify listeners after loading
  }

  // --- Setters (with persistence) ---
  Future<void> setMaxHistoryItems(int value) async {
    _maxHistoryItems = value.clamp(10, 1000); // Clamp between min/max
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('maxHistoryItems', _maxHistoryItems);
    notifyListeners();
    // Consider triggering cleanup check if count exceeds new max
  }

   Future<void> setDatabaseSizeLimitMB(double value) async {
    _databaseSizeLimitMB = value.clamp(50, 2048); // Example clamp
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('databaseSizeLimitMB', _databaseSizeLimitMB);
    notifyListeners();
     // Consider triggering size check
  }

  Future<void> setCloseToTray(bool value) async {
    _closeToTray = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('closeToTray', _closeToTray);
    notifyListeners();
  }

  // ... Add similar setters for all other settings ...
  // Remember to call notifyListeners() after updating a value
   Future<void> setFontFamily(String value) async {
    _fontFamily = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fontFamily', _fontFamily);
    notifyListeners();
  }
   Future<void> setFontSizeModifier(double value) async {
    _fontSizeModifier = value.clamp(0.8, 1.5); // Example clamp
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSizeModifier', _fontSizeModifier);
    notifyListeners();
  }

   Future<void> setPaddingScale(double value) async {
    _paddingScale = value.clamp(0.8, 1.5); // Example clamp
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('paddingScale', _paddingScale);
    notifyListeners();
  }

  // Add setters for other fields like autoCleanupDays, compressImages etc.
}