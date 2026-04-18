import 'package:flutter/material.dart';


// ==========================================
// 2. 隐私政策页面 (对应 privacypolicy.html)
// ==========================================
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 统一定义段落文本样式
    const paragraphStyle = TextStyle(
      fontSize: 15.0,
      height: 1.5, // 对应更好的行高阅读体验
      color: Colors.black87,
    );

    // 统一定义标题(H3)文本样式
    const headingStyle = TextStyle(
      fontSize: 18.0,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0, // 隐藏阴影
        leading: IconButton(
          icon: Image.asset('assets/images/roback.webp', width: 30),
          onPressed: () => Navigator.pop(context),
        )
      ),
      // 避免文字贴边，四周添加 20px 边距 (对应 padding: 0px 20px;)
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 40.0), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // H1
            const Center(
              child: Text(
                'upload this to Privacy Policy',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            
            // H3
            const Center(
              child: Text(
                'Privacy Policy',
                style: headingStyle,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            
            const Text(
              '    This Privacy Policy explains how our wireless RV leveling system and its companion mobile app (“App”) collect, use, and protect your information.',
              style: paragraphStyle,
            ),
            const SizedBox(height: 20),
            
            const Text('1. Information We Collect', style: headingStyle),
            const SizedBox(height: 10),
            const Text(
              '    We collect only the information necessary to operate and improve our product, including:\n\n'
              '    Device Data: Bluetooth connection data, sensor readings (e.g., RV leveling measurements), and device identifiers.\n'
              '    App Usage Data: Basic analytics such as app performance and feature usage.\n'
              '    Optional Information: If you contact support, we may collect your name, email address, and message details.',
              style: paragraphStyle,
            ),
            const SizedBox(height: 10),
            const Text(
              '    We do not collect precise location data, personal contacts, or sensitive personal information.',
              style: paragraphStyle,
            ),
            const SizedBox(height: 20),
            
            const Text('2. How We Use Information', style: headingStyle),
            const SizedBox(height: 10),
            const Text(
              '    We use collected information to:\n\n'
              '    Provide accurate RV leveling measurements and system functionality\n'
              '    Maintain and improve app performance\n'
              '    Troubleshoot issues and provide customer support',
              style: paragraphStyle,
            ),
            const SizedBox(height: 20),
            
            const Text('3. Data Sharing', style: headingStyle),
            const SizedBox(height: 10),
            const Text(
              '    We do not sell or rent your personal information.\n'
              '    We may share limited data with trusted service providers (e.g., analytics or hosting providers) solely to operate and improve the App.',
              style: paragraphStyle,
            ),
            const SizedBox(height: 20),
            
            const Text('4. Data Storage & Security', style: headingStyle),
            const SizedBox(height: 10),
            const Text(
              '    We take reasonable measures to protect your information. Most data is processed locally on your device and is not stored on external servers unless necessary for support or analytics.',
              style: paragraphStyle,
            ),
            const SizedBox(height: 20),
            
            const Text('5. Your Choices', style: headingStyle),
            const SizedBox(height: 10),
            const Text(
              '    You can stop data collection by uninstalling the App.\n'
              '    You may disable Bluetooth or app permissions through your device settings.',
              style: paragraphStyle,
            ),
            const SizedBox(height: 20),
            
            const Text('6. Children’s Privacy', style: headingStyle),
            const SizedBox(height: 10),
            const Text(
              '    Our App is not intended for children under 13, and we do not knowingly collect information from children.',
              style: paragraphStyle,
            ),
            const SizedBox(height: 20),
            
            const Text('7. Changes to This Policy', style: headingStyle),
            const SizedBox(height: 10),
            const Text(
              '    We may update this Privacy Policy from time to time. Updates will be posted within the App.',
              style: paragraphStyle,
            ),
            const SizedBox(height: 20),
            
            const Text('8. Contact Us', style: headingStyle),
            const SizedBox(height: 10),
            const Text(
              '    If you have questions about this Privacy Policy, please contact us at: support@carmtek.com',
              style: paragraphStyle,
            ),
          ],
        ),
      ),
    );
  }
}