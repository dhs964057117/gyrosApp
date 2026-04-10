import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
import '../services/storage_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'settings_screen.dart';
import 'home_screen.dart';

class BluetoothScanScreen extends StatefulWidget {
  const BluetoothScanScreen({super.key});

  @override
  State<BluetoothScanScreen> createState() => _BluetoothScanScreenState();
}

class _BluetoothScanScreenState extends State<BluetoothScanScreen> {
  bool _isConnected = false;
  String? _connectedDeviceName;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final bleService = Provider.of<BleService>(context, listen: false);

    // On iOS, we check adapterState. It will trigger the system dialog if needed.
    // On Android 12+, we need explicit bluetoothScan and bluetoothConnect.

    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    bool isBluetoothGranted =
        statuses[Permission.bluetoothScan]!.isGranted &&
        statuses[Permission.bluetoothConnect]!.isGranted;

    if (isBluetoothGranted) {
      // Small delay to let the adapter state catch up after permission prompt
      await Future.delayed(const Duration(milliseconds: 500));

      if (bleService.adapterState == BluetoothAdapterState.on) {
        bleService.startScan();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Bluetooth is ${bleService.adapterState.toString().split('.').last}. Please turn it on.',
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bluetooth permissions are required for scanning.'),
          ),
        );
      }
    }
  }

  void _onDeviceSelected(ScanResult result) async {
    final bleService = Provider.of<BleService>(context, listen: false);
    final storage = Provider.of<StorageService>(context, listen: false);

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connect Device'),
        content: Text(
          'Do you want to connect to ${result.device.platformName.isEmpty ? 'this device' : result.device.platformName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      await bleService.connect(result.device);
      storage.deviceId = result.device.remoteId.str;

      if (mounted) {
        setState(() {
          _isConnected = true;
          _connectedDeviceName = result.device.platformName.isEmpty
              ? 'Unknown'
              : result.device.platformName;
        });
        Navigator.pop(context); // Close loading dialog
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Connection failed: $e')));
      }
    }
  }

  void _onRefreshTapped() async {
    final bleService = Provider.of<BleService>(context, listen: false);

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refresh Scan'),
        content: const Text('Do you want to refresh the device list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      bleService.startScan();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isConnected) {
      return _buildSuccessScreen();
    }

    final bleService = Provider.of<BleService>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 50),
            const Text(
              'Select your device from the list below',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView.builder(
                itemCount: bleService.scanResults.length,
                itemBuilder: (context, index) {
                  final result = bleService.scanResults[index];
                  final device = result.device;
                  String name = device.platformName;
                  if (name.isEmpty) {
                    name = result.advertisementData.localName;
                  }

                  // Filter as per original app
                  final lowerName = name.toLowerCase();
                  if (!lowerName.contains('gyro') &&
                      !lowerName.contains('carmtek')) {
                    if (lowerName.isEmpty)
                      return const SizedBox.shrink(); // Hide unknown if not matching
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 4,
                    ),
                    child: InkWell(
                      onTap: () => _onDeviceSelected(result),
                      child: Container(
                        height: 70,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEECEF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                name.isEmpty ? 'Unknown' : name,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            Image.asset(
                              'assets/images/device/device-ico.webp',
                              height: 46,
                            ),
                            const SizedBox(width: 15),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: _onRefreshTapped,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97B1B),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Refresh', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/success.webp', width: 90),
            const SizedBox(height: 20),
            const Text(
              'Connected!',
              style: TextStyle(
                color: Color(0xFFF68A2B),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            Image.asset('assets/images/device/device-ico.webp', width: 240),
            const SizedBox(height: 20),
            Text(
              _connectedDeviceName ?? '',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: ElevatedButton(
                onPressed: () {
                  final storage = Provider.of<StorageService>(
                    context,
                    listen: false,
                  );
                  if (storage.isFirstTime) {
                    storage.isFirstTime = false;
                    // Navigator.pushReplacement(
                    //   context,
                    //   MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    // );
                    // 清空路由栈并跳转到 HomeScreen
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                          (route) => false,
                    );
                    // 在下一帧打开 SettingsScreen
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                      }
                    });
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97B1B),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Done!', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
