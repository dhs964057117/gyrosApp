import 'package:flutter/material.dart';
import 'package:page_flip/page_flip.dart';

class UserManualScreen extends StatefulWidget {
  const UserManualScreen({super.key});

  @override
  State<UserManualScreen> createState() => _UserManualScreenState();
}

class _UserManualScreenState extends State<UserManualScreen> {
  final GlobalKey<PageFlipWidgetState> _controller = GlobalKey<PageFlipWidgetState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'User Manual',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: PageFlipWidget(
            key: _controller,
            backgroundColor: Colors.white,
            lastPage: Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 80, color: Color(0xFFF6A42E)),
                    SizedBox(height: 20),
                    Text(
                      'End of Manual',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            children: [
              for (var i = 1; i <= 13; i++)
                _buildPage(i),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(int index) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: Image.asset(
              'assets/images/guide/guide$index.jpg',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.error_outline, color: Colors.red),
              ),
            ),
          ),
          // Page Footer info
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF9F9F9),
              border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Page $index / 13',
                  style: const TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
