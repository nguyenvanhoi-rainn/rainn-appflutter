import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy UID của người dùng đang đăng nhập (Lúc này là Client)
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Tin nhắn',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1BA39C),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 1. ✅ ĐÃ SỬA: Loại bỏ .orderBy để né hoàn toàn yêu cầu tạo Index phức tạp từ Firestore
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('users', arrayContains: currentUserId) // Tìm các phòng chat có ID của khách
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Đã xảy ra lỗi khi tải danh sách tin nhắn.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. ✅ Lấy mảng danh sách tài liệu thô về máy
          final List<DocumentSnapshot> rawChats = snapshot.data!.docs;

          // Hiển thị khi không có cuộc trò chuyện nào
          if (rawChats.isEmpty) {
            return _buildEmptyState();
          }

          // 3. ✅ ĐÃ SỬA: Tự sắp xếp danh sách bằng code Dart ngay trên thiết bị (Client-side sort giống bản React)
          rawChats.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;

            final Timestamp? timeA = dataA['updatedAt'] as Timestamp?;
            final Timestamp? timeB = dataB['updatedAt'] as Timestamp?;

            final int secondsA = timeA?.seconds ?? 0;
            final int secondsB = timeB?.seconds ?? 0;

            // Phòng chat nào có mốc thời gian tin nhắn mới nhất (seconds lớn hơn) sẽ đứng đầu
            return secondsB.compareTo(secondsA);
          });

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: rawChats.length,
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 75),
            itemBuilder: (context, index) {
              final chatData = rawChats[index].data() as Map<String, dynamic>;

              // ✅ Bóc tách tìm đúng workerId (ID của Thợ) nằm chung trong mảng thành viên
              final List users = chatData['users'] ?? [];
              final String workerId = users.firstWhere((id) => id != currentUserId, orElse: () => '');

              // Lấy tên động hiển thị theo cấu trúc 'name_workerId'
              final String workerName = chatData['name_$workerId'] ?? 'Người làm dịch vụ';
              final String jobTitle = chatData['jobTitle'] ?? 'Dịch vụ';

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF1BA39C), width: 1.5)),
                  child: const CircleAvatar(
                    radius: 23,
                    backgroundColor: Color(0xFFF0F9F8),
                    child: Icon(Icons.engineering, color: Color(0xFF1BA39C)), // Biểu tượng thợ kỹ thuật
                  ),
                ),
                title: Text(
                  workerName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF333333)),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '[$jobTitle] ${chatData['lastMessage'] ?? 'Chưa có tin nhắn'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatTime(chatData['updatedAt']), // Đồng bộ lấy mốc thời gian 'updatedAt'
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 5),
                    const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                  ],
                ),
                onTap: () {
                  if (workerId.isNotEmpty) {
                    // ✅ Đẩy chuẩn xác workerId sang cho AppRouter phía Client để mở phòng kết nối
                    context.push('/chat/$workerId');
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  // Widget hiển thị khi danh sách trống
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 70,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có cuộc trò chuyện nào',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Vào danh mục để tìm và đặt thợ ngay nhé!',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      DateTime date = (timestamp as Timestamp).toDate();
      return "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return '';
    }
  }
}