import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class WorkerProfileScreen extends StatelessWidget {
  const WorkerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ thợ'),
        backgroundColor: const Color(0xFF1BA39C),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final userData = snapshot.data!.data() as Map<String, dynamic>?;

          return Column(
            children: [
              const SizedBox(height: 30),
              const Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.engineering, size: 50, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),

              _buildInfoTile(Icons.person, 'Họ tên', userData?['fullName'] ?? 'N/A'),
              _buildInfoTile(Icons.email, 'Email', userData?['email'] ?? 'N/A'),
              _buildInfoTile(Icons.build, 'Chuyên môn', userData?['role'] ?? 'Worker'),
              _buildInfoTile(Icons.verified, 'Trạng thái', userData?['isVerified'] == true ? 'Đã xác minh' : 'Chờ duyệt'),

              const Divider(height: 40),

              ListTile(
                leading: const Icon(Icons.account_balance_wallet, color: Color(0xFF1BA39C)),
                title: const Text('Ví tiền & Thu nhập'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/worker/wallet'),
              ),

              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) context.go('/login');
                },
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
      subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}