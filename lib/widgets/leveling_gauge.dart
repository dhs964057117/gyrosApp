import 'package:flutter/material.dart';

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

        // 鸟瞰图 (Mode 3) 内部已经使用了按比例布局，保持原样
        if (viewMode == 3) {
          return _buildBirdsEyeView(availableWidth, availableHeight);
        }

        // Determine which car image to use
        String carImage = viewMode == 1
            ? 'assets/images/car${carType}h.webp'
            : 'assets/images/car${carType}w.webp';

        // Determine background gauge image
        String levelerImage = _getLevelerImage(angle);

        // 使用固定的逻辑坐标系 (350 x 500)，然后使用 FittedBox 等比缩放整个 Stack。
        // 彻底锁死圆弧、指针、小车之间的相对位置和大小关系，永不越界。
        return FittedBox(
          fit: BoxFit.contain, // 保证等比缩放并在容器内居中完整显示
          child: SizedBox(
            width: 350,  // 逻辑宽度
            height: 500, // 逻辑高度
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background Gauge (Leveler Arcs)
                Positioned(
                  top: 26, // 维持原有的固定位置逻辑
                  child: Image.asset(
                    levelerImage,
                    width: 240, // 维持原有的固定大小
                    gaplessPlayback: true,
                  ),
                ),
                // 仪表的指针 - 独立出完美的几何旋转体系
                Positioned(
                  top: 35, // 略微上移，让旋转中心完美对准圆弧图像的几何圆心
                  child: AnimatedRotation(
                    turns: (angle * 6.5) / 360.0, // 将倍率从5.2放大到7.5，确保极限角度下能扫到圆弧最末端的边缘
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    child: Container(
                      height: 360, // 设置精确的旋转直径(半径180)，这与圆弧的物理曲率100%吻合，无论怎么转都不会越界
                      width: 20,
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10.0), // 指针尖端向下压10像素，稳稳卡在彩色带中央
                        child: CustomPaint(
                          size: const Size(20, 20),
                          painter: TrianglePainter(color: const Color(0xFF343434)),
                        ),
                      ),
                    ),
                  ),
                ),
                // 小车图片
                AnimatedRotation(
                  turns: (angle * 2.08) / 360.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  child: Image.asset(
                    carImage,
                    width: 280, // 相当于你原来的 availableWidth * 0.8 (350 * 0.8 = 280)
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getLevelerImage(double angle) {
    double absAngle = angle.abs();
    if (absAngle <= 1.0) return 'assets/images/leveler3.webp';
    if (angle > 1.0 && angle <= 3.0) return 'assets/images/leveler4.webp';
    if (angle > 3.0) return 'assets/images/leveler5.webp';
    if (angle < -1.0 && angle >= -3.0) return 'assets/images/leveler2.webp';
    return 'assets/images/leveler1.webp';
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
              fontSize: 18,
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