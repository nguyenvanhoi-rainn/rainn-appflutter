import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ionicons/ionicons.dart';

class ManageUsers extends StatefulWidget {
  const ManageUsers({super.key});

  @override
  State<ManageUsers> createState() => _ManageUsersState();
}

class _ManageUsersState extends State<ManageUsers> {
  String _currentTab = 'client'; // Mặc định hiển thị khách hàng

  // Hàm khóa/mở khóa tài khoản thực tế trên Firestore[cite: 8]
  Future<void> _toggleUserStatus(String uid, String currentStatus) async {
    String newStatus = currentStatus == 'locked' ? 'active' : 'locked';
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'status': newStatus,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý tài khoản'),
        backgroundColor: const Color(0xFF1BA39C),
      ),
      body: Column(
        children: [
          // Thanh chọn Tab[cite: 8]
          Container(
            color: Colors.white,
            child: Row(
              children: [
                _buildTabBtn('client', 'Khách hàng'),
                _buildTabBtn('worker', 'Thợ sửa chữa'),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Truy vấn dữ liệu thật dựa trên vai trò[cite: 8]
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: _currentTab)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final users = snapshot.data!.docs;
                if (users.isEmpty) return const Center(child: Text('Danh sách trống.'));

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index].data() as Map<String, dynamic>;
                    bool isLocked = user['status'] == 'locked';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isLocked ? Colors.grey : const Color(0xFF1BA39C),
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(user['fullName'] ?? 'N/A'),
                      subtitle: Text(user['email'] ?? ''),
                      trailing: IconButton(
                        icon: Icon(
                          isLocked ? Ionicons.lock_closed : Ionicons.lock_open,
                          color: isLocked ? Colors.red : Colors.green,
                        ),
                        onPressed: () => _toggleUserStatus(users[index].id, user['status'] ?? 'active'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBtn(String key, String label) {
    bool isActive = _currentTab == key;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentTab = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: isActive ? const Color(0xFF1BA39C) : Colors.transparent, width: 2)),
          ),
          child: Text(label, textAlign: TextAlign.center,
              style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? const Color(0xFF1BA39C) : Colors.grey)),
        ),
      ),
    );
  }
}