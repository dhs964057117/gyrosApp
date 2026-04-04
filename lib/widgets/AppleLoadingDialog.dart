
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppleLoadingDialog {
  /// 显示苹果风格加载弹窗，返回 Future，可通过 Navigator.pop(context) 关闭
  static Future<void> show({
    required BuildContext context,
    String title = 'calibrating...',
    String message = 'please wait...',
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _AppleLoadingDialogContent(
          title: title,
          message: message,
        );
      },
    );
  }
}

class _AppleLoadingDialogContent extends StatelessWidget {
  final String title;
  final String message;

  const _AppleLoadingDialogContent({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CupertinoActivityIndicator(radius: 16),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}