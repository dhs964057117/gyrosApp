import 'package:flutter/material.dart';

class LevelingGauge extends StatelessWidget {
  final double angle;
  final int carType;
  final int viewMode; // 1: Front-to-Back, 2: Side-to-Side, 3: Bird's Eye
  final double pitch; // Needed for bird's eye
  final double roll;  // Needed for bird's eye
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
    this.width = 266.7,
    this.height = 300.2,
    this.unit = 1,
    this.wheelValues = const {},
    this.thresholds = const {},
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        final double availableHeight = constraints.maxHeight;
        
        // Determine which car image to use
        String carImage;
        if (viewMode == 1) {
          carImage = 'assets/images/car${carType}h.png';
        } else {
          carImage = 'assets/images/car${carType}w.png';
        }

        if (viewMode == 3) {
          return _buildBirdsEyeView(availableWidth, availableHeight);
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            // The Lever/Pointer (Triangle)
            Transform.rotate(
              angle: angle * 3.14159 / 180,
              child: Container(
                height: availableHeight * 0.9,
                width: 20,
                alignment: Alignment.topCenter,
                child: CustomPaint(
                  size: const Size(20, 20),
                  painter: TrianglePainter(color: const Color(0xFF343434)),
                ),
              ),
            ),
            // The Car Image
            Transform.rotate(
              angle: (angle / 2.0) * 3.14159 / 180, // Half rotation as in original JS
              child: Image.asset(
                carImage,
                width: availableWidth * 0.8,
                fit: BoxFit.contain,
              ),
            ),
          ],
        );
      }
    );
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
    
    // JS used fixed thresholds for colors in some places, but also used calculated ones.
    // We stick to the calculated high-difference thresholds to match the original logic.
    if (val <= t8) return const Color(0xFF9CDA1E);
    if (val <= t24) return const Color(0xFFECDC05);
    return const Color(0xFFFB2A37);
  }

  Widget _buildBirdsEyeView(double width, double height) {
    String carImage = 'assets/images/car${carType}f.png';
    String unitStr = unit == 1 ? 'cm' : '"';

    return Stack(
      children: [
        Center(child: Image.asset(carImage, width: width * 0.8)),
        if (carType <= 2) ...[
          _WheelValue(label: 'L1', value: wheelValues['L1'] ?? 0, unit: unitStr, color: _getColor(wheelValues['L1'] ?? 0, 'L1'), top: height * 0.1, left: width * 0.05),
          _WheelValue(label: 'R1', value: wheelValues['R1'] ?? 0, unit: unitStr, color: _getColor(wheelValues['R1'] ?? 0, 'R1'), top: height * 0.1, right: width * 0.05),
          _WheelValue(label: 'L2', value: wheelValues['L2'] ?? 0, unit: unitStr, color: _getColor(wheelValues['L2'] ?? 0, 'L2'), top: height * 0.5, left: width * 0.05),
          _WheelValue(label: 'R2', value: wheelValues['R2'] ?? 0, unit: unitStr, color: _getColor(wheelValues['R2'] ?? 0, 'R2'), top: height * 0.5, right: width * 0.05),
        ] else ...[
          _WheelValue(label: 'T1', value: wheelValues['T1'] ?? 0, unit: unitStr, color: _getColor(wheelValues['T1'] ?? 0, 'T1'), top: -20, left: width * 0.35),
          _WheelValue(label: 'B1', value: wheelValues['B1'] ?? 0, unit: unitStr, color: _getColor(wheelValues['B1'] ?? 0, 'B1'), bottom: -20, left: width * 0.35),
          _WheelValue(label: 'L3', value: wheelValues['L3'] ?? 0, unit: unitStr, color: _getColor(wheelValues['L3'] ?? 0, 'L3'), top: height * 0.3, left: width * 0.05),
          _WheelValue(label: 'R3', value: wheelValues['R3'] ?? 0, unit: unitStr, color: _getColor(wheelValues['R3'] ?? 0, 'R3'), top: height * 0.3, right: width * 0.05),
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
    this.top, this.bottom, this.left, this.right,
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
          Text(
            "${value.toStringAsFixed(2)}$unit",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
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
    // Original CSS: width:0; height:0; border-left/right: 10px; border-bottom: 20px
    // This creates an upward pointing triangle.
    final paint = Paint()..color = color;
    final path = Path();
    path.moveTo(size.width / 2, 0); // Top center tip
    path.lineTo(0, size.height);    // Bottom left corner
    path.lineTo(size.width, size.height); // Bottom right corner
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
