import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String keyDeviceId = 'deviceId';
  static const String keyCarType = 'carType'; // default: 1
  static const String keyUnit = 'unit'; // 1: cm, 2: inch
  static const String keyTempUnit = 'tempUnit'; // 1: C, 2: F
  static const String keyWidth = 'ws'; // Width
  static const String keyHeight = 'hs'; // Height
  static const String keyOrientation = 'fangx'; // Orientation/Direction
  static const String keyIsFirst = 'isFirst'; // 1: First time

  static const int defaultCarType = 1;
  static const int defaultUnit = 2; // 1: cm, 2: inch
  static const int defaultTempUnit = 1; // 1: C, 2: F
  static const double defaultWidth = 300.0;
  static const double defaultHeight = 800.0;
  static const int defaultOrientation = 1;

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String? get deviceId => _prefs.getString(keyDeviceId);
  set deviceId(String? value) => value != null ? _prefs.setString(keyDeviceId, value) : _prefs.remove(keyDeviceId);

  int get carType => _prefs.getInt(keyCarType) ?? defaultCarType;
  set carType(int value) => _prefs.setInt(keyCarType, value);

  int get unit => _prefs.getInt(keyUnit) ?? defaultUnit;
  set unit(int value) => _prefs.setInt(keyUnit, value);

  int get tempUnit => _prefs.getInt(keyTempUnit) ?? defaultTempUnit;
  set tempUnit(int value) => _prefs.setInt(keyTempUnit, value);

  double get width => _prefs.getDouble(keyWidth) ?? defaultWidth;
  set width(double value) => _prefs.setDouble(keyWidth, value);

  double get height => _prefs.getDouble(keyHeight) ?? defaultHeight;
  set height(double value) => _prefs.setDouble(keyHeight, value);

  int get orientation => _prefs.getInt(keyOrientation) ?? defaultOrientation;
  set orientation(int value) => _prefs.setInt(keyOrientation, value);

  bool get isFirstTime => _prefs.getBool(keyIsFirst) ?? true;
  set isFirstTime(bool value) => _prefs.setBool(keyIsFirst, value);

  void resetSettings() {
    carType = defaultCarType;
    unit = defaultUnit;
    tempUnit = defaultTempUnit;
    width = defaultWidth;
    height = defaultHeight;
    orientation = defaultOrientation;
  }
}
