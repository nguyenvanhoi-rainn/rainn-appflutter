import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class ClientProfileScreen extends StatelessWidget {
  const ClientProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
        backgroundColor: const Color(0xFF1BA39C), // Màu xanh RAINN
        actions: [
          // Nút chuyển sang trang sửa
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/profile-edit'),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final userData = snapshot.data!.data() as Map<String, dynamic>?;

          return Column(
            children: [
              const SizedBox(height: 30),
              // Ảnh đại diện giả lập
              const Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Color(0xFF1BA39C),
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),

              // Hiển thị thông tin (Read-only)
              _buildInfoTile(Icons.person, 'Họ tên', userData?['fullName'] ?? 'Chưa cập nhật'),
              _buildInfoTile(Icons.phone, 'Số điện thoại', userData?['phone'] ?? 'Chưa cập nhật'),
              _buildInfoTile(Icons.location_on, 'Địa chỉ', userData?['address'] ?? 'Chưa cập nhật'),

              const Divider(height: 40),

              // Nút đăng xuất
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  // Logic chuyển về trang Login sẽ do AppRouter/MainWrapper xử lý
                },
              ),

              const Spacer(),

              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'HTH\nPhiên bản 1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1BA39C)),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
    );
  }
}