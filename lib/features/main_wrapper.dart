import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'client/screens/client_home.dart';
import 'client/screens/chat_list_screen.dart';
import 'client/screens/history_screen.dart';
import 'client/screens/profile_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  // Danh sách các màn hình tương ứng với các Tab
  final List<Widget> _screens = [
    const ClientHomeScreen(),      // Màn hình chính
    const ChatListScreen(),  // Danh sách chat
    const HistoryScreen(),   // Lịch sử
    const ClientProfileScreen(),   // Cá nhân
  ];

  void _onItemTapped(int index) {
    // Tạo hiệu ứng rung nhẹ khi chuyển tab (tương đương HapticTab trong RN)
    HapticFeedback.lightImpact();
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1BA39C),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Lịch sử'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Hồ sơ'),
        ],
      ),
    );
  }
}