import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Accent colours the user can pick in Settings.
enum AccentColor {
  blue('Wayfarer blue', Color(0xFF2B5BA8)),
  teal('Teal', Color(0xFF00897B)),
  purple('Purple', Color(0xFF6A4FB3)),
  sunset('Sunset', Color(0xFFE0663A));

  const AccentColor(this.label, this.color);

  final String label;
  final Color color;
}

enum DistanceUnit { km, mi }

enum TempUnit { celsius, fahrenheit }

/// Holds the user's UI settings and saves every change to the device
/// (shared_preferences), so they survive an app restart.
class SettingsController extends ChangeNotifier {
  SettingsController(this._prefs) {
    _themeMode = ThemeMode.values[_prefs.getInt(_kTheme) ?? ThemeMode.system.index];
    _accent = AccentColor.values[_prefs.getInt(_kAccent) ?? 0];
    _textScale = _prefs.getDouble(_kTextScale) ?? 1.0;
    _distanceUnit = DistanceUnit.values[_prefs.getInt(_kDistance) ?? 0];
    _tempUnit = TempUnit.values[_prefs.getInt(_kTemp) ?? 0];
    _displayName = _prefs.getString(_kName) ?? 'Traveller';
  }

  static const String _kTheme = 'settings.themeMode';
  static const String _kAccent = 'settings.accent';
  static const String _kTextScale = 'settings.textScale';
  static const String _kDistance = 'settings.distanceUnit';
  static const String _kTemp = 'settings.tempUnit';
  static const String _kName = 'settings.displayName';

  final SharedPreferences _prefs;

  late ThemeMode _themeMode;
  late AccentColor _accent;
  late double _textScale;
  late DistanceUnit _distanceUnit;
  late TempUnit _tempUnit;
  late String _displayName;

  ThemeMode get themeMode => _themeMode;
  AccentColor get accent => _accent;
  double get textScale => _textScale;
  DistanceUnit get distanceUnit => _distanceUnit;
  TempUnit get tempUnit => _tempUnit;
  String get displayName => _displayName;

  set themeMode(ThemeMode value) {
    _themeMode = value;
    _prefs.setInt(_kTheme, value.index);
    notifyListeners();
  }

  set accent(AccentColor value) {
    _accent = value;
    _prefs.setInt(_kAccent, value.index);
    notifyListeners();
  }

  set textScale(double value) {
    _textScale = value;
    _prefs.setDouble(_kTextScale, value);
    notifyListeners();
  }

  set distanceUnit(DistanceUnit value) {
    _distanceUnit = value;
    _prefs.setInt(_kDistance, value.index);
    notifyListeners();
  }

  set tempUnit(TempUnit value) {
    _tempUnit = value;
    _prefs.setInt(_kTemp, value.index);
    notifyListeners();
  }

  set displayName(String value) {
    _displayName = value;
    _prefs.setString(_kName, value);
    notifyListeners();
  }

  /// Puts every setting back to its default.
  void reset() {
    _themeMode = ThemeMode.system;
    _accent = AccentColor.blue;
    _textScale = 1.0;
    _distanceUnit = DistanceUnit.km;
    _tempUnit = TempUnit.celsius;
    for (final String key in <String>[_kTheme, _kAccent, _kTextScale, _kDistance, _kTemp]) {
      _prefs.remove(key);
    }
    notifyListeners();
  }
}
