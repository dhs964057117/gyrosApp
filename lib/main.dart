import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gyros_app/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'services/storage_service.dart';
import 'services/ble_service.dart';
import 'models/orientation_model.dart';
import 'screens/bluetooth_scan_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final storageService = StorageService();
  await storageService.init();

  final bleService = BleService();
  final orientationModel = OrientationModel();

  // Listen for BLE data and update orientation model
  bleService.dataStream.listen((data) {
    // Convert List<int> to Hex String
    String hex = data.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
    orientationModel.updateFromHex(
      hex,
      storageService.orientation,
      storageService.unit,
      storageService.tempUnit,
      storageService.width,
      storageService.height,
    );
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: bleService),
        ChangeNotifierProvider.value(value: orientationModel),
        Provider.value(value: storageService),
      ],
      child: const CarmtekApp(),
    ),
  );
}

class CarmtekApp extends StatelessWidget {
  const CarmtekApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<StorageService>(context, listen: false);
    
    // Set status bar to transparent and icons to dark (matching original app)
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return MaterialApp(
      title: 'Carmtek',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        fontFamily: 'Arial',
      ),
      home: const BluetoothScanScreen(),
    );
  }
}
