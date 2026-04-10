import 'package:flutter/material.dart';

class TemperatureIndicator extends StatelessWidget {
  final double temp;
  final int unit; // 1: C, 2: F
  const TemperatureIndicator({super.key, required this.temp, required this.unit});

  @override
  Widget build(BuildContext context) {
    String unitStr = unit == 1 ? '℃' : '°F';
    double displayTemp = unit == 1 ? temp : (temp * 1.8 + 32);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "${displayTemp.toStringAsFixed(1)}$unitStr",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Image.asset('assets/images/center/wenduji.webp', height: 26),
      ],
    );
  }
}
