import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final TextEditingController _nameController = TextEditingController(text: 'Carmtek');
  bool _isConnecting = false;

  void _onRecover(BleService ble) async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please enter a name')));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Attempting recovery: ${_nameController.text}...')),
    );

    await ble.recoveryWrite(_nameController.text);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recovery commands sent. Restart device to verify!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bleService = Provider.of<BleService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Recovery Tool'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.red.withOpacity(0.1),
            child: const Text(
              'NO FILTER SCAN: All BLE devices are listed below. Find your device by MAC address or proximity.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
          if (bleService.connectedDevice != null) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Connected to: ${bleService.connectedDevice!.remoteId}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'New Device Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => _onRecover(bleService),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text('FIX NAME (BRUTE FORCE)'),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => bleService.disconnect(),
                        child: const Text('Disconnect'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          Expanded(
            child: ListView.builder(
              itemCount: bleService.scanResults.length,
              itemBuilder: (context, index) {
                final result = bleService.scanResults[index];
                final device = result.device;
                return ListTile(
                  leading: const Icon(Icons.bluetooth),
                  title: Text(device.platformName.isEmpty ? 'Unknown' : device.platformName),
                  subtitle: Text('${device.remoteId}\nRSSI: ${result.rssi}'),
                  trailing: ElevatedButton(
                    onPressed: bleService.connectedDevice != null
                        ? null
                        : () async {
                            setState(() => _isConnecting = true);
                            try {
                              await bleService.connect(device);
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to connect: $e')),
                                );
                              }
                            }
                            setState(() => _isConnecting = false);
                          },
                    child: const Text('Connect'),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => bleService.startScan(),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Scan All Devices'),
            ),
          ),
        ],
      ),
    );
  }
}
