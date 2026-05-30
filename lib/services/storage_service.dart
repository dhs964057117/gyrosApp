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

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String? get deviceId => _prefs.getString(keyDeviceId);
  set deviceId(String? value) => value != null ? _prefs.setString(keyDeviceId, value) : _prefs.remove(keyDeviceId);

  int get carType => _prefs.getInt(keyCarType) ?? 1;
  set carType(int value) => _prefs.setInt(keyCarType, value);

  int get unit => _prefs.getInt(keyUnit) ?? 1;
  set unit(int value) => _prefs.setInt(keyUnit, value);

  int get tempUnit => _prefs.getInt(keyTempUnit) ?? 1;
  set tempUnit(int value) => _prefs.setInt(keyTempUnit, value);

  double get width => _prefs.getDouble(keyWidth) ?? 300.0;
  set width(double value) => _prefs.setDouble(keyWidth, value);

  double get height => _prefs.getDouble(keyHeight) ?? 800.0;
  set height(double value) => _prefs.setDouble(keyHeight, value);

  int get orientation => _prefs.getInt(keyOrientation) ?? 1;
  set orientation(int value) => _prefs.setInt(keyOrientation, value);

  bool get isFirstTime => _prefs.getBool(keyIsFirst) ?? true;
  set isFirstTime(bool value) => _prefs.setBool(keyIsFirst, value);
}
