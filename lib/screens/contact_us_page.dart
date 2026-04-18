import 'package:flutter/material.dart';

// ==========================================
// 1. 联系我们页面 (对应 contantus.html)
// ==========================================
class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 获取屏幕宽度，用于实现类似 width: 110%; left: -5% 的效果
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0, // 隐藏阴影
        leading: IconButton(
          icon: Image.asset('assets/images/roback.webp', width: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child:
            // 主体滚动内容
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: screenWidth * 1.1,
                // 对应 width: 110%
                // transform: Matrix4.translationValues(0.0, 20.0, 0.0), // 对应 left: -5%; margin-top: 20px;
                // 注意：这里请将 assets/images/13.jpg 替换为你项目中真实的图片路径
                // 如果暂时没有配置 assets，可以先用一个占位符查看效果：
                // child: const Placeholder(fallbackHeight: 800),
                child: Image.asset(
                  'assets/images/13.webp',
                  fit: BoxFit.fitWidth,
                  errorBuilder: (context, error, stackTrace) {
                    // 图片加载失败时的替代显示
                    return Container(
                      height: 800,
                      color: Colors.grey[200],
                      alignment: Alignment.center,
                      child: const Text(
                        '图片加载失败\n请在 pubspec.yaml 中配置 assets/images/13.webp',
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
            ),
      ),
    );
  }
}
