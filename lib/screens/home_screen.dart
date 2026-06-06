import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gyros_app/screens/privacy_policy_page.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
import '../services/storage_service.dart';
import '../models/orientation_model.dart';
import '../widgets/battery_indicator.dart';
import '../widgets/temperature_indicator.dart';
import '../widgets/leveling_gauge.dart';
import 'package:torch_light/torch_light.dart';

import 'contact_us_page.dart';
import 'settings_screen.dart';
import 'bluetooth_scan_screen.dart';
import 'user_manual_screen.dart';
import 'test_screen.dart';
import 'package:flutter/foundation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _drawerController;
  StreamSubscription? _dataSubscription;
  int _viewMode = 1; // 1: Front-to-Back, 2: Side-to-Side, 3: Bird's Eye
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bleService = Provider.of<BleService>(context, listen: false);
      final orientation = Provider.of<OrientationModel>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);

      _dataSubscription = bleService.dataStream.listen((data) {
        String hex = data
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join('');
        orientation.updateFromHex(
          hex,
          storage.orientation,
          storage.unit,
          storage.tempUnit,
          storage.width,
          storage.height,
        );
      });
    });
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    _drawerController.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    if (_drawerController.isCompleted) {
      _drawerController.reverse();
    } else {
      _drawerController.forward();
    }
  }

  // Clamping function for gauge rotation (per original JS lines 1399-1401)
  // The visual angle is capped to match the dial's range
  double _clampAngle(double angle) {
    if (angle <= -5.7) return -5.7;
    if (angle >= 5.7) return 5.7;
    return angle;
  }

  @override
  Widget build(BuildContext context) {
    final bleService = Provider.of<BleService>(context);
    final storage = Provider.of<StorageService>(context);

    const double drawerWidth = 280.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF6A42E),
      // Match sidebar color when pushed
      body: Stack(
        children: [
          // BOTTOM LAYER: Sidebar (Stationary)
          _buildSidebar(bleService, storage),

          // TOP LAYER: Main Content (Translated)
          AnimatedBuilder(
            animation: _drawerController,
            builder: (context, child) {
              double slide = drawerWidth * _drawerController.value;
              double scale = 1.0 - (_drawerController.value * 0.05);

              return Transform(
                transform: Matrix4.identity()
                  ..translate(slide)
                  ..scale(scale),
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      if (_drawerController.value > 0)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(-10, 0),
                        ),
                    ],
                  ),
                  child: Scaffold(
                    key: _scaffoldKey,
                    backgroundColor: Colors.white,
                    appBar: AppBar(
                      backgroundColor: Colors.white,
                      elevation: 0,
                      leading: IconButton(
                        icon: Image.asset(
                          'assets/images/center/menu.webp',
                          width: 26,
                        ),
                        onPressed: _toggleDrawer,
                      ),
                      title: Image.asset(
                        'assets/images/app-logo.webp',
                        width: 130,
                      ),
                      centerTitle: true,
                      actions: [
                        IconButton(
                          icon: Image.asset(
                            'assets/images/center/set.webp',
                            width: 26,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    body: _buildHomeBody(storage),
                  ),
                ),
              );
            },
          ),

          // TAP-TO-CLOSE COVER (When drawer is open)
          AnimatedBuilder(
            animation: _drawerController,
            builder: (context, child) {
              if (_drawerController.value == 0) return const SizedBox.shrink();
              return Positioned.fill(
                left: drawerWidth * _drawerController.value,
                child: GestureDetector(
                  onTap: _toggleDrawer,
                  behavior: HitTestBehavior.opaque,
                  child: Container(color: Colors.transparent),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHomeBody(StorageService storage) {
    return Consumer<OrientationModel>(
      builder: (context, orientation, child) {
        final wheelData = orientation.calculateWheelDifferentials(
          storage.width,
          storage.height,
          storage.unit,
        );
        final wheelValues = Map<String, double>.from(wheelData['values']);
        final thresholds = Map<String, double>.from(wheelData['thresholds']);

        double currentAngle = _viewMode == 1
            ? orientation.pitch
            : (_viewMode == 2 ? orientation.roll : 0);

        double lengthForMode = _viewMode == 1 ? storage.height : storage.width;
        double hAbsVal = _viewMode == 3
            ? 0.0
            : orientation.calculateHighDifference(currentAngle, lengthForMode);

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Battery and Temperature Row
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6A42E),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: BatteryIndicator(
                          level: orientation.batteryLevel,
                        ),
                      ),
                      Expanded(
                        child: TemperatureIndicator(
                          temp: orientation.temperatureCelsius,
                          unit: storage.tempUnit,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Gauge Box
                Container(
                  height: MediaQuery.of(context).size.height * 0.6,
                  decoration: BoxDecoration(
                    color: const Color(0x66DAD6DB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Stack(
                    children: [
                      // Main LevelingGauge Animation
                      // 重点优化：整体向下偏移（top: 75），让指针正好1/3刺入圆弧，剩下2/3在圆弧下方
                      Positioned(
                        top: 15,
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: LevelingGauge(
                          angle: currentAngle,
                          carType: storage.carType,
                          viewMode: _viewMode,
                          pitch: orientation.pitch,
                          roll: orientation.roll,
                          width: storage.width,
                          height: storage.height,
                          unit: storage.unit,
                          wheelValues: wheelValues,
                          thresholds: thresholds,
                        ),
                      ),
                      // High Difference Text
                      Positioned(
                        top: 110,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 100),
                            curve: Curves.linear,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: _getGaugeColor(hAbsVal, storage.unit),
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                            child: Text(
                              _getDifferenceText(storage, _viewMode, hAbsVal),
                            ),
                          ),
                        ),
                      ),
                      // Labels
                      if (_viewMode != 3)
                        Positioned(
                          bottom: 20,
                          left: 24,
                          right: 24,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _getLabelLeft(_viewMode),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                _getLabelRight(_viewMode),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Control Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ControlButton(
                        icon: 'assets/images/dingwei.webp',
                        onPressed: () => _jiaozhun(context),
                      ), // Calibration
                      const SizedBox(width: 4),
                      Expanded(
                        child: _ViewModeButton(
                          text: 'SIDE-TO-SIDE',
                          isActive: _viewMode == 2,
                          onPressed: () => setState(() => _viewMode = 2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Expanded(
                      //   child: _ViewModeButton(
                      //     text: 'LOOKING DOWN',
                      //     isActive: _viewMode == 3,
                      //     onPressed: () => setState(() => _viewMode = 3),
                      //   ),
                      // ),
                      // const SizedBox(width: 4),
                      Expanded(
                        child: _ViewModeButton(
                          text: 'FRONT-TO-BACK',
                          isActive: _viewMode == 1,
                          onPressed: () => setState(() => _viewMode = 1),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _ControlButton(
                        icon: 'assets/images/shoudiantong.webp',
                        onPressed: _toggleTorch,
                      ), // Torch
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSidebar(BleService ble, StorageService storage) {
    return Container(
      width: 280,
      color: const Color(0xFFF6A42E),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                const Icon(Icons.menu, color: Colors.white, size: 30),
                const SizedBox(width: 15),
                const Text(
                  'MENU',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSidebarItem(Icons.email_outlined, 'Contact Us', () {
            _toggleDrawer();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ContactUsPage()),
            );
          }),
          _buildSidebarItem(Icons.book_outlined, 'User Manual', () {
            _toggleDrawer();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UserManualScreen()),
            );
          }),
          _buildSidebarItem(Icons.policy_outlined, 'Privacy Policy', () {
            _toggleDrawer();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
            );
          }),
          _buildSidebarItem(Icons.refresh_outlined, 'Reset Device', () {
            _showResetDialog(ble, storage);
          }),
          _buildSidebarItem(Icons.logout_outlined, 'Disconnect', () {
            _disconnect(ble, storage);
          }),
          const Divider(color: Colors.white24),
          _buildDebugSidebarItem(Icons.bug_report, 'DEBUG: Recovery Tool', () {
            _toggleDrawer();
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => const TestScreen()));
          }),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'App Version 1.0.0',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Padding(
        padding: const EdgeInsets.only(left: 10.0),
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildDebugSidebarItem(
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    if (kDebugMode) {
      return ListTile(
        leading: Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
      );
    }
    return Spacer();
  }

  // Logic Helpers
  void _showResetDialog(BleService ble, StorageService storage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Device'),
        content: const Text('Whether to reset the device data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _disconnect(ble, storage);
              storage.carType = 1;
              storage.unit = 2;
              storage.tempUnit = 1;
              storage.width = 300.0;
              storage.height = 800.0;
              storage.orientation = 1;
              storage.isFirstTime = true;
              Navigator.pop(context);
              _toggleDrawer();
              setState(() {});
            },
            child: const Text('Sure'),
          ),
        ],
      ),
    );
  }

  void _toggleTorch() async {
    try {
      if (await TorchLight.isTorchAvailable()) {
        if (_isTorchOn) {
          await TorchLight.disableTorch();
        } else {
          await TorchLight.enableTorch();
        }
        setState(() {
          _isTorchOn = !_isTorchOn;
        });
      }
    } catch (e) {}
  }

  void _disconnect(BleService ble, StorageService storage) async {
    await ble.disconnect();
    storage.deviceId = null;
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const BluetoothScanScreen()),
      (route) => false,
    );
  }

  void _jiaozhun(BuildContext context) {
    final bleService = Provider.of<BleService>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text(
          'Please confirm whether the device is handling calibratable positions and click "Sure" to start the calibration?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await bleService.writeValue([0x02]);
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Calibration command sent')),
              );
            },
            child: const Text('Sure'),
          ),
        ],
      ),
    );
  }

  String _getDifferenceText(StorageService storage, int mode, double hAbs) {
    if (mode == 3) return "";
    String unitStr = storage.unit == 1 ? ' cm' : '"';
    return "${hAbs.toStringAsFixed(2)}$unitStr";
  }

  String _getLabelLeft(int mode) {
    if (mode == 1) return "REAR";
    if (mode == 2) return "LEFT";
    return "";
  }

  String _getLabelRight(int mode) {
    if (mode == 1) return "FRONT";
    if (mode == 2) return "RIGHT";
    return "";
  }

  Color _getGaugeColor(double hAbsVal, int unit) {
    double t1 = unit == 1 ? 2.5 : 1.0;
    double t2 = unit == 1 ? 7.5 : 3.0;
    if (hAbsVal <= t1) return const Color(0xFF9CDA1E);
    if (hAbsVal <= t2) return const Color(0xFFECDC05);
    return const Color(0xFFFB2A37);
  }
}

class _ControlButton extends StatelessWidget {
  final String icon;
  final VoidCallback onPressed;

  const _ControlButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3E5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: IconButton(
        icon: Image.asset(icon, width: 24),
        onPressed: onPressed,
      ),
    );
  }
}

class _ViewModeButton extends StatelessWidget {
  final String text;
  final bool isActive;
  final VoidCallback onPressed;

  const _ViewModeButton({
    required this.text,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE8900D) : const Color(0xFFFEF3E5),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : const Color(0xFF292525),
          ),
        ),
      ),
    );
  }
}
