import 'package:flutter/material.dart';
import 'worker/screens/worker_home.dart';
import 'worker/screens/worker_schedule.dart';
import 'worker/screens/worker_chat_list.dart';
import 'worker/screens/wallet.dart';
import 'worker/screens/worker_profile.dart';

class WorkerMainWrapper extends StatefulWidget {
  const WorkerMainWrapper({super.key});

  @override
  State<WorkerMainWrapper> createState() => _WorkerMainWrapperState();
}

class _WorkerMainWrapperState extends State<WorkerMainWrapper> {
  int _selectedIndex = 0;

  // Danh sách 5 màn hình chính của Worker (Đã thêm Ví tiền)
  final List<Widget> _screens = [
    const WorkerHomeScreen(),       // Tab 0: Việc mới
    const WorkerScheduleScreen(),   // Tab 1: Lịch trình
    const WorkerChatList(),         // Tab 2: Tin nhắn
    const WalletScreen(),           // Tab 3: Ví tiền (Tính năng mới thêm)
    const WorkerProfileScreen(),    // Tab 4: Cá nhân
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed, // Giữ cố định thanh điều hướng khi có 5 tabs
        selectedItemColor: const Color(0xFF1BA39C),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.work_outline), label: 'Việc mới'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'Lịch trình'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Tin nhắn'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Ví tiền'), // 2. ✅ Thêm Tab Ví tiền
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Cá nhân'),
        ],
      ),
    );
  }
}