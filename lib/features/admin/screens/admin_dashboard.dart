import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1BA39C),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => context.push('/admin/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thống kê tổng quan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Hàng thẻ thống kê
            Row(
              children: [
                _buildStatCard('Người dùng', '1,250', Icons.people, Colors.blue),
                _buildStatCard('Công việc', '450', Icons.work, Colors.orange),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Quản lý hệ thống',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildAdminMenu(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminMenu(BuildContext context) {
    final List<Map<String, dynamic>> menus = [
      {'title': 'Xác minh Worker', 'icon': Icons.verified_user, 'route': '/admin/verify-workers'},
      {'title': 'Quản lý Dịch vụ', 'icon': Icons.miscellaneous_services, 'route': '/admin/services'},
      {'title': 'Báo cáo & Khiếu nại', 'icon': Icons.report, 'route': '/admin/reviews'},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: menus.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: Icon(menus[index]['icon'], color: const Color(0xFF1BA39C)),
          title: Text(menus[index]['title']),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(menus[index]['route']),
        );
      },
    );
  }
}