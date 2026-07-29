import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

class OrientationModel extends ChangeNotifier {
  // --- Smoothing configuration ---
  /// How often the displayed value is re-integrated toward the raw target.
  static const Duration _tickInterval = Duration(milliseconds: 33);

  /// Exponential smoothing time constant in seconds.
  /// Larger = smoother but slower to reach the real value.
  static const double _tauSeconds = 0.3;

  /// Once the displayed value is within this many degrees of its target it
  /// snaps exactly to the target and the ticker goes idle.
  static const double _settleEpsilon = 0.004;

  // Raw, unfiltered sensor values in degrees (targets for the smoothing).
  double _rawPitch = 0; // Front-to-back
  double _rawRoll = 0;  // Side-to-side

  // Smoothed values that the UI actually consumes.
  double _pitch = 0; // Front-to-back
  double _roll = 0;  // Side-to-side
  int _batteryLevel = 0;
  double _temperatureCelsius = 0;
  String _calibStatus = '01'; // '00': Uncalibrated, '01': Calibrating, '02'+: Ready

  bool _hasFirstValue = false;
  Timer? _smoothTimer;
  DateTime _lastTickTime = DateTime.now();

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
    //
    // The raw values are only stored as targets. The smoothed _pitch/_roll
    // ramp progressively toward them so noisy BLE packets (possibly amplified
    // by the configured length/width) never cause visible jumps.
    _rawPitch = zuoyouzhi;
    _rawRoll = shangxiazhi;

    if (!_hasFirstValue) {
      // Show the very first reading immediately instead of sweeping from 0.
      _hasFirstValue = true;
      _pitch = _rawPitch;
      _roll = _rawRoll;
    }
    _ensureSmoothing();

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

  /// Starts the smoothing ticker if it is not already running.
  void _ensureSmoothing() {
    if (_smoothTimer?.isActive == true) return;
    _lastTickTime = DateTime.now();
    _smoothTimer = Timer.periodic(_tickInterval, _onSmoothTick);
  }

  /// Moves the displayed values one step closer to the latest raw targets
  /// using a time-based exponential moving average, so the numbers and the
  /// needle increase/decrease gradually instead of jumping between packets.
  void _onSmoothTick(Timer timer) {
    final DateTime now = DateTime.now();
    double dt = now.difference(_lastTickTime).inMicroseconds / 1e6;
    _lastTickTime = now;
    // Clamp so a long pause cannot turn into one huge leap.
    dt = dt.clamp(0.001, 0.1);

    final double alpha = 1 - exp(-dt / _tauSeconds);

    double nextPitch = _pitch + (_rawPitch - _pitch) * alpha;
    double nextRoll = _roll + (_rawRoll - _roll) * alpha;

    bool settled = true;
    if ((nextPitch - _rawPitch).abs() <= _settleEpsilon) {
      nextPitch = _rawPitch;
    } else {
      settled = false;
    }
    if ((nextRoll - _rawRoll).abs() <= _settleEpsilon) {
      nextRoll = _rawRoll;
    } else {
      settled = false;
    }

    if (nextPitch != _pitch || nextRoll != _roll) {
      _pitch = nextPitch;
      _roll = nextRoll;
      notifyListeners();
    }

    if (settled) {
      // Both axes reached their targets: stop ticking until the next packet.
      timer.cancel();
    }
  }

  @override
  void dispose() {
    _smoothTimer?.cancel();
    super.dispose();
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
