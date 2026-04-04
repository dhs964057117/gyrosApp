import 'package:flutter/material.dart';

class BatteryIndicator extends StatelessWidget {
  final int level;
  const BatteryIndicator({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(_getBatteryImage(level), height: 26),
        const SizedBox(width: 8),
        Text(
          "$level%",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _getBatteryImage(int level) {
    if (level <= 20) return 'assets/images/center/power5.png';
    if (level <= 40) return 'assets/images/center/power4.png';
    if (level <= 60) return 'assets/images/center/power3.png';
    if (level <= 80) return 'assets/images/center/power2.png';
    return 'assets/images/center/power1.png';
  }
}
