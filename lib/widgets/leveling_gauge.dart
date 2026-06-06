import 'package:flutter/material.dart';
import 'dart:math' as math;

class LevelingGauge extends StatelessWidget {
  final double angle;
  final int carType;
  final int viewMode; // 1: Front-to-Back, 2: Side-to-Side, 3: Bird's Eye
  final double pitch; // Needed for bird's eye
  final double roll; // Needed for bird's eye
  final double width;
  final double height;
  final int unit;

  final Map<String, double> wheelValues;
  final Map<String, double> thresholds;

  const LevelingGauge({
    super.key,
    required this.angle,
    required this.carType,
    required this.viewMode,
    this.pitch = 0,
    this.roll = 0,
    this.width = 300.0,
    this.height = 800.0,
    this.unit = 2,
    this.wheelValues = const {},
    this.thresholds = const {},
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        final double availableHeight = constraints.maxHeight;

        // 鸟瞰图 (Mode 3) 内部已经使用了按比例布局，保持原样
        if (viewMode == 3) {
          return _buildBirdsEyeView(availableWidth, availableHeight);
        }

        // Determine which car image to use
        String carImage = viewMode == 1
            ? 'assets/images/car${carType}h.webp' // Side view
            : 'assets/images/car${carType}w.webp'; // Back view

        // JS Logic for wheel rotation and image states
        double l = viewMode == 1 ? height : width;
        double hSigned = l * (math.sin(angle * math.pi / 180.0));
        double nums = double.parse(hSigned.toStringAsFixed(2));

        // Clamp nums according to JS limits
        double limit = unit == 1 ? 12.5 : 5.0;

        // Calculate the rotational percentage
        double magnitudeScale = nums.abs() / limit;
        if (magnitudeScale > 1.0) magnitudeScale = 1.0;
        double sign = nums < 0 ? -1.0 : 1.0;

        // Clamped nums values directly match original JS variables
        if (nums <= -limit) nums = -limit;
        if (nums >= limit) nums = limit;

        // JS geometric fw rotation calculation (maximum ~26.25 degrees)
        double fw = unit == 1 ? (nums * 5.8 / 2.5) : (nums * 5.8);

        // Use EXACT pure fw as naturally configured by JS for the needle limits
        double pointerRotationDegrees = fw;
        // Car strictly derived from fw as well
        double carRotationDegrees = fw * 0.4;

        // Determine background gauge image based on absolute height difference (not angle)
        String levelerImage = _getLevelerImage(angle, nums.abs(), unit);

        // Responsive Column layout adapts gracefully to any height!
        return Stack(
          children: [
            Center(
              child: AnimatedRotation(
                turns: carRotationDegrees / 360.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                child: FractionallySizedBox(
                  widthFactor: carType == 2 ? 1.0 : 1.2, // 80% of width
                  child: Image.asset(carImage, fit: BoxFit.contain),
                ),
              ),
            ),
            Column(
              children: [
                // Flexible Top Area: Gauge Module
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      // Allow the Gauge itself to securely scale
                      child: SizedBox(
                        width: 320,
                        // Logic width
                        height: 180,
                        // Logic height for the Arc box, keeps it tightly clipped visually
                        child: Stack(
                          clipBehavior: Clip.none,
                          // Allow needle stick to safely bleed vertically
                          alignment: Alignment.topCenter,
                          children: [
                            // Background Gauge Arc
                            Positioned(
                              top: 24, // Original JS gauge static Y offset
                              child: Image.asset(
                                levelerImage,
                                width: 240,
                                gaplessPlayback: true,
                              ),
                            ),
                            // The Needle System perfectly mimicking JS DOM constraints
                            Positioned(
                              top: 45,
                              // Exact JS original tip offset Y (margin-top 32px + wrapped margins)
                              child: AnimatedRotation(
                                turns: pointerRotationDegrees / 360.0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                                child: Container(
                                  height: 436,
                                  // Diameter resolving strictly to JS radius 218px
                                  width: 20,
                                  alignment: Alignment.topCenter,
                                  child: CustomPaint(
                                    // Removed padding to lock geometric apex perfectly to local top=0
                                    size: const Size(20, 20),
                                    painter: TrianglePainter(
                                      color: const Color(0xFF343434),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Flexible Bottom Area: Rotating Car Image (Safely Centered)
            // Expanded(
            //   flex: 4,
            //   child: Center(
            //     child: AnimatedRotation(
            //       turns: carRotationDegrees / 360.0,
            //       duration: const Duration(milliseconds: 300),
            //       curve: Curves.easeOutBack,
            //       child: FractionallySizedBox(
            //         widthFactor: 0.8, // 80% of width
            //         child: Image.asset(carImage, fit: BoxFit.contain),
            //       ),
            //     ),
            //   ),
            // ),
            // Bottom Padding to give space above Labels
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  String _getLevelerImage(double angle, double hAbs, int unit) {
    double t1 = unit == 1 ? 2.5 : 1.0;
    double t2 = unit == 1 ? 7.5 : 3.0;

    if (hAbs <= t1) return 'assets/images/leveler3.webp';
    if (hAbs > t1 && hAbs <= t2) {
      return angle > 0
          ? 'assets/images/leveler4.webp'
          : 'assets/images/leveler2.webp';
    }
    return angle > 0
        ? 'assets/images/leveler5.webp'
        : 'assets/images/leveler1.webp';
  }

  Color _getColor(double val, String key) {
    double t8 = 0, t24 = 0;
    if (key == 'L1' || key == 'R1' || key == 'L2' || key == 'R2') {
      t8 = thresholds['zts8'] ?? 0;
      t24 = thresholds['zts24'] ?? 0;
    } else if (key == 'T1' || key == 'B1') {
      t8 = thresholds['zt8'] ?? 0;
      t24 = thresholds['zt24'] ?? 0;
    } else if (key == 'L3' || key == 'R3') {
      t8 = thresholds['zs8'] ?? 0;
      t24 = thresholds['zs24'] ?? 0;
    }

    if (val <= t8) return const Color(0xFF9CDA1E);
    if (val <= t24) return const Color(0xFFECDC05);
    return const Color(0xFFFB2A37);
  }

  Widget _buildBirdsEyeView(double width, double height) {
    String carImage = 'assets/images/car${carType}f.webp';
    String unitStr = unit == 1 ? 'cm' : '"';

    return Stack(
      children: [
        Center(child: Image.asset(carImage, width: width * 0.8)),
        if (carType <= 2) ...[
          _WheelValue(
            label: 'L1',
            value: wheelValues['L1'] ?? 0,
            unit: unitStr,
            color: _getColor(wheelValues['L1'] ?? 0, 'L1'),
            top: height * 0.1,
            left: width * 0.05,
          ),
          _WheelValue(
            label: 'R1',
            value: wheelValues['R1'] ?? 0,
            unit: unitStr,
            color: _getColor(wheelValues['R1'] ?? 0, 'R1'),
            top: height * 0.1,
            right: width * 0.05,
          ),
          _WheelValue(
            label: 'L2',
            value: wheelValues['L2'] ?? 0,
            unit: unitStr,
            color: _getColor(wheelValues['L2'] ?? 0, 'L2'),
            top: height * 0.5,
            left: width * 0.05,
          ),
          _WheelValue(
            label: 'R2',
            value: wheelValues['R2'] ?? 0,
            unit: unitStr,
            color: _getColor(wheelValues['R2'] ?? 0, 'R2'),
            top: height * 0.5,
            right: width * 0.05,
          ),
        ] else ...[
          _WheelValue(
            label: 'T1',
            value: wheelValues['T1'] ?? 0,
            unit: unitStr,
            color: _getColor(wheelValues['T1'] ?? 0, 'T1'),
            top: -20,
            left: width * 0.35,
          ),
          _WheelValue(
            label: 'B1',
            value: wheelValues['B1'] ?? 0,
            unit: unitStr,
            color: _getColor(wheelValues['B1'] ?? 0, 'B1'),
            bottom: -20,
            left: width * 0.35,
          ),
          _WheelValue(
            label: 'L3',
            value: wheelValues['L3'] ?? 0,
            unit: unitStr,
            color: _getColor(wheelValues['L3'] ?? 0, 'L3'),
            top: height * 0.3,
            left: width * 0.05,
          ),
          _WheelValue(
            label: 'R3',
            value: wheelValues['R3'] ?? 0,
            unit: unitStr,
            color: _getColor(wheelValues['R3'] ?? 0, 'R3'),
            top: height * 0.3,
            right: width * 0.05,
          ),
        ],
      ],
    );
  }
}

class _WheelValue extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final Color color;
  final double? top, bottom, left, right;

  const _WheelValue({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    this.top,
    this.bottom,
    this.left,
    this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Column(
        children: [
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 100),
            curve: Curves.linear,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            child: Text("${value.toStringAsFixed(2)}$unit"),
          ),
          Container(height: 2, width: 50, color: Colors.red),
        ],
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    path.moveTo(size.width / 2, 0); // Top center tip
    path.lineTo(0, size.height); // Bottom left corner
    path.lineTo(size.width, size.height); // Bottom right corner
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}