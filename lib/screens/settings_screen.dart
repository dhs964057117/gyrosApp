import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../services/ble_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _activeTab = 1; // 1: Device Setup, 2: RV Setup

  late int _unit;
  late int _tempUnit;
  late int _orientation;
  late int _carType;
  late TextEditingController _widthController;
  late TextEditingController _heightController;

  final GlobalKey _trailerWidthKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final storage = Provider.of<StorageService>(context, listen: false);
    _unit = storage.unit;
    _tempUnit = storage.tempUnit;
    _orientation = storage.orientation;
    _carType = storage.carType;
    _widthController = TextEditingController(text: storage.width.toString());
    _heightController = TextEditingController(text: storage.height.toString());
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 新增此方法：处理单位切换时的自动换算
  void _handleUnitChange(int newUnit) {
    if (_unit == newUnit) return;

    double currentWidth = double.tryParse(_widthController.text) ?? 0.0;
    double currentHeight = double.tryParse(_heightController.text) ?? 0.0;

    double newWidth = currentWidth;
    double newHeight = currentHeight;

    if (newUnit == 2 && _unit == 1) {
      // cm -> inch (除以 2.54)
      newWidth = currentWidth / 2.54;
      newHeight = currentHeight / 2.54;
    } else if (newUnit == 1 && _unit == 2) {
      // inch -> cm (乘以 2.54)
      newWidth = currentWidth * 2.54;
      newHeight = currentHeight * 2.54;
    }

    double maxVal = newUnit == 2 ? 999.0 : 2537.46;
    if (newWidth < 0) {
      newWidth = 0.0;
    } else if (newWidth > maxVal) {
      newWidth = maxVal;
    }

    if (newHeight < 0) {
      newHeight = 0.0;
    } else if (newHeight > maxVal) {
      newHeight = maxVal;
    }

    _widthController.text = newUnit == 1 ? newWidth.toStringAsFixed(2) : newWidth.toStringAsFixed(1);
    _heightController.text = newUnit == 1 ? newHeight.toStringAsFixed(2) : newHeight.toStringAsFixed(1);

    setState(() {
      _unit = newUnit;
    });
  }

  void _save() {
    final storage = Provider.of<StorageService>(context, listen: false);
    storage.unit = _unit;
    storage.tempUnit = _tempUnit;
    storage.orientation = _orientation;
    storage.carType = _carType;

    // 验证并限制宽度输入值
    double width = double.tryParse(_widthController.text) ?? storage.width;
    double maxWidth = _unit == 2 ? 999.0 : 2537.46;
    if (width < 0) {
      width = 0;
    } else if (width > maxWidth) {
      width = maxWidth;
    }
    _widthController.text = _unit == 1 ? width.toStringAsFixed(2) : width.toStringAsFixed(1);
    storage.width = width;

    // 验证并限制长度输入值
    double height = double.tryParse(_heightController.text) ?? storage.height;
    double maxHeight = _unit == 2 ? 999.0 : 2537.46;
    if (height < 0) {
      height = 0;
    } else if (height > maxHeight) {
      height = maxHeight;
    }
    _heightController.text = _unit == 1 ? height.toStringAsFixed(2) : height.toStringAsFixed(1);
    storage.height = height;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved successfully'), duration: Duration(seconds: 2)),
    );
  }

  void _scrollToTrailerWidth() async {
    // 如果当前不在 RV Setup 选项卡，先切换
    if (_activeTab != 2) {
      setState(() {
        _activeTab = 2;
      });
      // 等待视图构建完成
      await WidgetsBinding.instance.endOfFrame;
    }

    // 等待一帧确保布局完成
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performScroll();
    });
  }

  void _onSetLevelPressed() {
    final bleService = Provider.of<BleService>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text(
          'Please confirm whether the device is handling calibratable positions and click "Sure" to start the calibration?',
          style: TextStyle(fontSize: 16),
        ),
        contentPadding: const EdgeInsets.all(20),
        actionsPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
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

  void _performScroll() {
    final RenderBox? renderBox = _trailerWidthKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      // 若未找到，延迟重试一次
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _performScroll();
      });
      return;
    }

    final offset = renderBox.localToGlobal(Offset.zero);
    // 减去 AppBar 和 Tab 栏的高度（可根据实际情况调整）
    final double appBarHeight = kToolbarHeight + 10 + 38 + 10; // AppBar + 间距 + Tab容器 + 间距
    final targetOffset = offset.dy - appBarHeight;

    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Image.asset('assets/images/roback.webp', width: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Settings', style: TextStyle(color: Color(0xFF8F8F8F), fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          // Tab Switcher
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFDEFD0),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _TabButton(
                      text: 'Device Setup',
                      isActive: _activeTab == 1,
                      onPressed: () => setState(() => _activeTab = 1),
                    ),
                  ),
                  Expanded(
                    child: _TabButton(
                      text: 'RV Setup',
                      isActive: _activeTab == 2,
                      onPressed: () => setState(() => _activeTab = 2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _activeTab == 1 ? _buildDeviceSetup() : _buildRvSetup(),
              ),
            ),
          ),
          // Save Bar
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC8F09),
                      side: const BorderSide(color: Color(0xFFC5B7A5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Reset', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF7A52E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Save', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceSetup() {
    return Column(
      children: [
        _buildSection(
          title: 'Measurement Units',
          child: Row(
            children: [
              Expanded(
                child: _ToggleButton(
                  text: 'Inches',
                  isActive: _unit == 2,
                  onPressed: () => setState(() => _handleUnitChange(2)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ToggleButton(
                  text: 'Centimeters',
                  isActive: _unit == 1,
                  onPressed: () => setState(() => _handleUnitChange(1)),
                ),
              ),
            ],
          ),
        ),
        _buildSection(
          title: 'Temperature Units',
          child: Row(
            children: [
              Expanded(child: _ToggleButton(text: 'Fahrenheit', isActive: _tempUnit == 2, onPressed: () => setState(() => _tempUnit = 2))),
              const SizedBox(width: 10),
              Expanded(child: _ToggleButton(text: 'Celsius', isActive: _tempUnit == 1, onPressed: () => setState(() => _tempUnit = 1))),
            ],
          ),
        ),
        _buildSection(
          title: '',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Level your RV using your traditional leveling method.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('If your vehicle has power slideout rooms, the vehicle should be leveled with the slides out.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('Once your RV is level, press the "Set Level" button below.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _onSetLevelPressed,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE49D00)),
                  child: const Text('Set Level', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
        _buildSection(
          title: 'Set Installation Orientation',
          child: Center(
            child: SizedBox(
              width: 340,
              height: 380,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Positioned(
                    top: 60,
                    child: Container(
                      color: Colors.transparent,
                      child: Image.asset('assets/images/fushitu.webp', width: 140),
                    ),
                  ),
                  Positioned(
                      top: 10,
                      child: _OrientationButton(width: 180, height: 36, text: 'Logo Faces Rear', isActive: _orientation == 1, onPressed: () => setState(() => _orientation = 1))
                  ),
                  Positioned(
                      bottom: 20,
                      child: _OrientationButton(width: 180, height: 36, text: 'Logo Faces Front', isActive: _orientation == 2, onPressed: () => setState(() => _orientation = 2))
                  ),
                  Positioned(
                      left: 20,
                      bottom: 60,
                      child: _OrientationButton(width: 40, height: 220, text: "Logo Face Passenger's Side", isActive: _orientation == 3, onPressed: () => setState(() => _orientation = 3), isVertical: true)
                  ),
                  Positioned(
                      right: 20,
                      bottom: 60,
                      child: _OrientationButton(width: 40, height: 220, text: "Logo Face Driver's Side", isActive: _orientation == 4, onPressed: () => setState(() => _orientation = 4), isVertical: true)
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRvSetup() {
    return Column(
      children: [
        _buildSection(
          title: 'Select Your RV Type:',
          child: Column(
            children: List.generate(5, (index) {
              int type = index + 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: _CarModeRow(
                  type: type,
                  name: _getCarName(type),
                  isActive: _carType == type,
                  onPressed: () => setState(() => _carType = type),
                ),
              );
            }),
          ),
        ),
        Container(
          key: _trailerWidthKey,
          child: _buildSection(
            title: 'Trailer Width',
            child: Column(
              children: [
                Image.asset('assets/images/car4w_guid.webp', height: 190),
                const Text('Measure the width on the outside of each tire', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: TextField(
                            controller: _widthController,
                            textAlign: TextAlign.center,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF555555)),
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                              border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFCCCCCC))),
                              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFF7A52E))),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(_unit == 1 ? 'CM' : 'Inches', style: const TextStyle(color: Color(0xFF8F8F8F), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        _buildSection(
          title: 'Trailer Length',
          child: Column(
            children: [
                Image.asset('assets/images/car4h_guid.webp', height: 190),
              const Text('Measure the distance from the center of the rear wheel to the jack point, or to the center pf the front wheel if it is a drivable RV', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: TextField(
                          controller: _heightController,
                          textAlign: TextAlign.center,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF555555)),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                            border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFCCCCCC))),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFF7A52E))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(_unit == 1 ? 'CM' : 'Inches', style: const TextStyle(color: Color(0xFF8F8F8F), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EEF1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          // const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  String _getCarName(int type) {
    switch (type) {
      case 1: return 'Class A';
      case 2: return 'Class B/C';
      case 3: return 'Travel Trailer';
      case 4: return 'Fifth Wheel';
      case 5: return 'Hybrid/Pop-UP';
      default: return '';
    }
  }
}

class _TabButton extends StatelessWidget {
  final String text;
  final bool isActive;
  final VoidCallback onPressed;
  const _TabButton({required this.text, required this.isActive, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF7A52E) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF8F8F8F),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String text;
  final bool isActive;
  final VoidCallback onPressed;
  const _ToggleButton({required this.text, required this.isActive, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? const Color(0xFFF7A52E) : const Color(0xFFFDEFD0),
        foregroundColor: isActive ? Colors.white : const Color(0xFF8F8F8F),
        elevation: 0,
      ),
      child: Text(text),
    );
  }
}

class _OrientationButton extends StatelessWidget {
  final String text;
  final bool isActive;
  final VoidCallback onPressed;
  final bool isVertical;
  final double? width;
  final double? height;
  const _OrientationButton({required this.text, required this.isActive, required this.onPressed, this.isVertical = false, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    Widget content = Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold));
    if (isVertical) {
      content = RotatedBox(quarterTurns: 3, child: content);
    }

    return InkWell(
      onTap: onPressed,
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        decoration: BoxDecoration(
          color: isActive ? Colors.black : const Color(0xFFFFE9D2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: DefaultTextStyle(
          style: TextStyle(color: isActive ? const Color(0xFFFDEFD0) : const Color(0xFF8F8F8F)),
          child: content,
        ),
      ),
    );
  }
}

class _CarModeRow extends StatelessWidget {
  final int type;
  final String name;
  final bool isActive;
  final VoidCallback onPressed;
  const _CarModeRow({required this.type, required this.name, required this.isActive, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0x7FDAD6DB),
          borderRadius: BorderRadius.circular(4),
          border: isActive ? Border.all(color: Colors.green, width: 2) : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Image.asset('assets/images/car$type.webp', width: 100, height: 60),
            const SizedBox(width: 10),
            Expanded(child: Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? Colors.green : Colors.grey[700]))),
            if (isActive) Image.asset('assets/images/selecteds.webp', width: 24),
          ],
        ),
      ),
    );
  }
}