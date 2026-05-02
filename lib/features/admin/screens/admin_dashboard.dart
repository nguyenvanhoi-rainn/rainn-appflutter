import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ionicons/ionicons.dart'; // Thêm: flutter pub add ionicons

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  // Chức năng Đăng xuất giống file dashboard.tsx
  Future<void> _handleLogout(BuildContext context) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn muốn đăng xuất khỏi quyền Admin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Đăng xuất', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) context.go('/login'); // Điều hướng về trang login
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Rainn Admin Panel', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1BA39C),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRealtimeStats(), // Thống kê thực tế từ Firestore
            const SizedBox(height: 25),
            const Text("Quản lý hệ thống", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildAdminGrid(context),
          ],
        ),
      ),
    );
  }

  // Thống kê Real-time lấy dữ liệu thật giống analytics.tsx
  Widget _buildRealtimeStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, userSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
          builder: (context, jobSnap) {
            int userCount = userSnap.data?.size ?? 0;
            int jobCount = jobSnap.data?.size ?? 0;

            return Row(
              children: [
                _statCard('Thành viên', '$userCount', Icons.people, Colors.blue),
                const SizedBox(width: 15),
                _statCard('Công việc', '$jobCount', Icons.work, Colors.orange),
              ],
            );
          },
        );
      },
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // Lưới menu giống dashboard.tsx[cite: 3]
  Widget _buildAdminGrid(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {'title': 'Tài khoản', 'icon': Icons.people, 'route': '/admin/users', 'color': const Color(0xFF1BA39C)},
      {'title': 'Danh mục', 'icon': Icons.grid_view, 'route': '/admin/categories', 'color': Colors.orange},
      {'title': 'Dịch vụ', 'icon': Icons.build, 'route': '/admin/services', 'color': Colors.indigo},
      {'title': 'Duyệt thợ', 'icon': Icons.verified_user, 'route': '/admin/verify-workers', 'color': Colors.blue},
      {'title': 'Thống kê', 'icon': Icons.bar_chart, 'route': '/admin/analytics', 'color': Colors.pink},
      {'title': 'Cài đặt', 'icon': Icons.settings, 'route': '/admin/settings', 'color': Colors.grey},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1.1,
      ),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        return InkWell(
          onTap: () => context.push(item['route']),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: item['color'].withOpacity(0.1)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: item['color'].withOpacity(0.1),
                  child: Icon(item['icon'], color: item['color']),
                ),
                const SizedBox(height: 12),
                Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }
}