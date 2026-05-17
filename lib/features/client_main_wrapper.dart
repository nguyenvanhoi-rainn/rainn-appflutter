import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'client/screens/client_home.dart';
import 'client/screens/chat_list.dart';
import 'client/screens/history.dart';
import 'client/screens/payment.dart';
import 'client/screens/profile.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  // Danh sách 5 màn hình tương ứng với các Tab sau khi thêm Ví tiền
  final List<Widget> _screens = [
    const ClientHomeScreen(),      // Tab 0: Màn hình chính
    const ChatListScreen(),        // Tab 1: Danh sách chat
    const HistoryScreen(),         // Tab 2: Lịch sử
    const PaymentScreen(),         // Tab 3: Ví & Thanh toán (Tính năng mới thêm)
    const ClientProfileScreen(),   // Tab 4: Cá nhân
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
        type: BottomNavigationBarType.fixed, // Giữ cố định cấu trúc hiển thị khi thanh có 5 nút tab
        selectedItemColor: const Color(0xFF1BA39C),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.history_toggle_off), activeIcon: Icon(Icons.history), label: 'Lịch sử'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet), label: 'Thanh toán'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Hồ sơ'),
        ],
      ),
    );
  }
}