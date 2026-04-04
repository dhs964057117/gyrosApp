import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService extends ChangeNotifier {
  BluetoothDevice? _connectedDevice;
  StreamSubscription<List<int>>? _valueSubscription;
  
  bool _isScanning = false;
  bool get isScanning => _isScanning;
  
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  BluetoothAdapterState get adapterState => _adapterState;
  
  List<ScanResult> _scanResults = [];
  List<ScanResult> get scanResults => _scanResults;

  BluetoothDevice? get connectedDevice => _connectedDevice;

  final StreamController<List<int>> _dataController = StreamController<List<int>>.broadcast();
  Stream<List<int>> get dataStream => _dataController.stream;

  BleService() {
    FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      notifyListeners();
    });

    FlutterBluePlus.isScanning.listen((scanning) {
      _isScanning = scanning;
      notifyListeners();
    });

    FlutterBluePlus.scanResults.listen((results) {
      _scanResults = results;
      notifyListeners();
    });
  }

  Future<void> startScan() async {
    if (_isScanning) return;
    if (_adapterState != BluetoothAdapterState.on) {
      debugPrint('Warning: Attempting to scan when adapter is not ON: $_adapterState');
      return;
    }
    _scanResults = [];
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  BluetoothCharacteristic? _notifyCharacteristic;
  BluetoothCharacteristic? _writeCharacteristic;

  Future<void> connect(BluetoothDevice device) async {
    debugPrint('Connecting to device: ${device.remoteId}');
    await device.connect();
    _connectedDevice = device;
    
    // Discover services
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
       String serviceUuid = service.uuid.toString().toLowerCase();
       // Standard FFE0 service for serial modules
       if (serviceUuid.contains('ffe0') || serviceUuid.contains('fff0')) {
         debugPrint('Found serial service $serviceUuid');
         
         for (var characteristic in service.characteristics) {
           String charUuid = characteristic.uuid.toString().toLowerCase();
           final hasNotify = characteristic.properties.notify;
           final hasWrite = characteristic.properties.write || 
                            characteristic.properties.writeWithoutResponse;

           debugPrint('Checking characteristic $charUuid (Notify: $hasNotify, Write: $hasWrite)');

           // Priority 1: Pick characteristic that has BOTH notify and write (Standard Data Pipe)
           // If we already found one, only override if current is specifically FFE1/FFF1
           if (hasNotify && hasWrite) {
             if (_notifyCharacteristic == null || charUuid.contains('ffe1') || charUuid.contains('fff1')) {
               debugPrint('Selecting as main data pipe: $charUuid');
               _notifyCharacteristic = characteristic;
               _writeCharacteristic = characteristic;
             }
           } 
           // Priority 2: Just notify or just write (Fallback)
           else {
             if (hasNotify && _notifyCharacteristic == null) {
               _notifyCharacteristic = characteristic;
             }
             if (hasWrite && _writeCharacteristic == null) {
               _writeCharacteristic = characteristic;
             }
           }
         }
       }
    }

    // Process notification subscription if found
    if (_notifyCharacteristic != null) {
      await _notifyCharacteristic!.setNotifyValue(true);
      _valueSubscription = _notifyCharacteristic!.onValueReceived.listen((value) {
        _dataController.add(value);
      });
    }

    // Fallback: If no dedicated write characteristic, try using notify one
    if (_writeCharacteristic == null && _notifyCharacteristic != null) {
      _writeCharacteristic = _notifyCharacteristic;
    }
    
    notifyListeners();
  }

  Future<void> writeValue(List<int> value) async {
    if (_writeCharacteristic != null) {
      try {
        // Try standard write with response
        await _writeCharacteristic!.write(value, withoutResponse: false);
      } catch (e) {
        debugPrint('Standard write failed, trying without response: $e');
        try {
          await _writeCharacteristic!.write(value, withoutResponse: true);
        } catch (e2) {
          debugPrint('Write failed completely: $e2');
        }
      }
    } else {
      debugPrint('Error: No write characteristic found.');
    }
  }

  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
      _valueSubscription?.cancel();
      notifyListeners();
    }
  }

  // Recovery Tool: Brute force name change across potential config characteristics
  Future<void> recoveryWrite(String newName) async {
    if (_connectedDevice == null) return;

    List<BluetoothService> services = await _connectedDevice!.discoverServices();
    for (var service in services) {
      String serviceUuid = service.uuid.toString().toLowerCase();
      // Target the serial service
      if (serviceUuid.contains('ffe0') || serviceUuid.contains('fff0')) {
        for (var characteristic in service.characteristics) {
          // We target any characteristic that IS NOT our main data pipe
          if (characteristic.uuid != _notifyCharacteristic?.uuid) {
            final hasWrite = characteristic.properties.write || characteristic.properties.writeWithoutResponse;
            if (hasWrite) {
              debugPrint('Attempting recovery on ${characteristic.uuid}');
              
              // Try different common command formats
              List<String> commands = [
                'AT+NAME$newName',    // Standard JDY-10/HM-10
                newName,              // Some raw modules
                newName,     // Older iterations
              ];

              for (var cmd in commands) {
                try {
                  List<int> bytes = cmd.codeUnits;
                  await characteristic.write(bytes, withoutResponse: false);
                  await characteristic.write(bytes, withoutResponse: true);
                  // Brief delay between protocol attempts
                  await Future.delayed(const Duration(milliseconds: 200));
                } catch (e) {
                  debugPrint('Recovery write failed for $cmd on ${characteristic.uuid}: $e');
                }
              }
            }
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _dataController.close();
    _valueSubscription?.cancel();
    super.dispose();
  }
}
