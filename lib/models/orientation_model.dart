import 'dart:math';
import 'package:flutter/foundation.dart';

class OrientationModel extends ChangeNotifier {
  double _pitch = 0; // Front-to-back
  double _roll = 0;  // Side-to-side
  int _batteryLevel = 0;
  double _temperatureCelsius = 0;
  String _calibStatus = '01'; // '00': Uncalibrated, '01': Calibrating, '02'+: Ready

  double get pitch => _pitch;
  double get roll => _roll;
  int get batteryLevel => _batteryLevel;
  double get temperatureCelsius => _temperatureCelsius;
  bool get isCalibrating => _calibStatus == '01';
  bool get needsInitialization => _calibStatus == '00';

  void updateFromHex(String hex, int orientation, int unit, int tempUnit, double ws, double hs) {
    if (hex.length < 8) return;

    int rawZuoyou = _hexToShort(hex.substring(0, 4));    // Original bytes 0-1
    int rawShangxian = _hexToShort(hex.substring(4, 8)); // Original bytes 2-3

    double zuoyouzhi;
    double shangxiazhi;

    // Handle orientation axis swap (fangx 3 or 4)
    if (orientation == 3 || orientation == 4) {
      zuoyouzhi = rawShangxian / 100.0;
      shangxiazhi = rawZuoyou / 100.0;
    } else {
      zuoyouzhi = rawZuoyou / 100.0;
      shangxiazhi = rawShangxian / 100.0;
    }

    // Apply orientation inversion to the mapped axes
    if (orientation == 1 || orientation == 4) {
      zuoyouzhi = -zuoyouzhi;
    }

    if (orientation == 2 || orientation == 4) {
      shangxiazhi = -shangxiazhi;
    }

    // In the original JS, the raw angle value is used for text display WITHOUT clamping.
    // Clamping only happens for the visual gauge rotation logic.
    _pitch = zuoyouzhi;
    _roll = shangxiazhi;

    // Calibration status (hex characters 8-10)
    if (hex.length >= 10) {
      _calibStatus = hex.substring(8, 10);
    }

    // Battery (hex characters 10-12)
    if (hex.length >= 12) {
      _batteryLevel = int.parse(hex.substring(10, 12), radix: 16);
    }

    // Temperature (hex characters 12-14)
    if (hex.length >= 14) {
      // Replicating JS quirk: (byte << 8) / 100.0
      int rawTempByte = int.parse(hex.substring(12, 14), radix: 16);
      int rawTempShort = (rawTempByte << 8); 
      _temperatureCelsius = rawTempShort / 100.0;
    }

    notifyListeners();
  }

  int _hexToShort(String hex) {
    if (hex.length < 4) return 0;
    int val = int.parse(hex, radix: 16);
    if (val > 32767) {
      val -= 65536;
    }
    return val;
  }

  double calculateHighDifference(double angle, double l) {
    double angleInRadians = angle.abs() * pi / 180.0;
    double h = l * sin(angleInRadians);
    return double.parse(h.toStringAsFixed(2)); // Exact rounding as in original JS
  }

  Map<String, dynamic> calculateWheelDifferentials(double ws, double hs, int unit) {
    // Rounding matches original JS: parseFloat(h1.toFixed(2))
    double z1 = calculateHighDifference(_pitch, hs); // zuoyouzhi -> z1 (hs)
    double z2 = calculateHighDifference(_roll, ws);  // shangxiazhi -> z2 (ws)
    
    // Original JS uses sin(8) and sin(24) applied to the dimensions
    double zt8 = calculateHighDifference(8.0, hs);
    double zt24 = calculateHighDifference(24.0, hs);
    double zs8 = calculateHighDifference(8.0, ws);
    double zs24 = calculateHighDifference(24.0, ws);
    
    // Average thresholds as per original JS line 812-813
    double zts8 = double.parse(((zt8 + zs8) / 2.0).toStringAsFixed(2));
    double zts24 = double.parse(((zt24 + zs24) / 2.0).toStringAsFixed(2));

    double l1 = 0, r1 = 0, l2 = 0, r2 = 0, t1 = 0, b1 = 0, l3 = 0, r3 = 0;

    // Bird's Eye Logic (Original logic from center.html lines 815-859)
    if (_pitch <= 0) {
      l1 = z1; r1 = z1; t1 = z1;
    } else {
      l2 = z1; r2 = z1; b1 = z1;
    }

    if (_roll <= 0) {
      if (r1 != 0) {
        r1 = double.parse(((r1 + z2) / 2.0).toStringAsFixed(2));
      } else {
        r1 = z2;
      }
      if (r2 != 0) {
        r2 = double.parse(((r2 + z2) / 2.0).toStringAsFixed(2));
      } else {
        r2 = z2;
      }
      r3 = z2;
    } else {
      if (l1 != 0) {
        l1 = double.parse(((l1 + z2) / 2.0).toStringAsFixed(2));
      } else {
        l1 = z2;
      }
      if (l2 != 0) {
        l2 = double.parse(((l2 + z2) / 2.0).toStringAsFixed(2));
      } else {
        l2 = z2;
      }
      l3 = z2;
    }

    return {
      'values': {
        'L1': l1, 'R1': r1, 'L2': l2, 'R2': r2,
        'T1': t1, 'B1': b1, 'L3': l3, 'R3': r3
      },
      'thresholds': {
        'zt8': zt8, 'zt24': zt24, 'zs8': zs8, 'zs24': zs24,
        'zts8': zts8, 'zts24': zts24
      }
    };
  }
}
