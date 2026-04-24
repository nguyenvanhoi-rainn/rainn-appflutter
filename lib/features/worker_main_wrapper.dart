import 'package:flutter/material.dart';
import 'worker/screens/worker_home.dart';
import 'worker/screens/worker_schedule_screen.dart';
import 'worker/screens/worker_chat_list.dart';
import 'worker/screens/worker_profile_screen.dart';

class WorkerMainWrapper extends StatefulWidget {
  const WorkerMainWrapper({super.key});

  @override
  State<WorkerMainWrapper> createState() => _WorkerMainWrapperState();
}

class _WorkerMainWrapperState extends State<WorkerMainWrapper> {
  int _selectedIndex = 0;

  // Danh sách 4 màn hình chính của Worker
  final List<Widget> _screens = [
    const WorkerHomeScreen(),       // Tab 0: Việc mới
    const WorkerScheduleScreen(),   // Tab 1: Lịch trình
    const WorkerChatList(),         // Tab 2: Tin nhắn
    const WorkerProfileScreen(),    // Tab 3: Cá nhân
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
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1BA39C),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.work_outline), label: 'Việc mới'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Lịch trình'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Tin nhắn'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Cá nhân'),
        ],
      ),
    );
  }
}