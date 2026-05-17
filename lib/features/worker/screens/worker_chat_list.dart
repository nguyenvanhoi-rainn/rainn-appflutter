import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class WorkerChatList extends StatelessWidget {
  const WorkerChatList({super.key});

  @override
  Widget build(BuildContext context) {
    final String workerId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Tin nhắn khách hàng',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1BA39C),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 1. ✅ ĐÃ SỬA: Xóa hoàn toàn .orderBy để né yêu cầu tạo Index từ Firestore
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('users', arrayContains: workerId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Đã xảy ra lỗi khi tải danh sách tin nhắn.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. ✅ Lấy mảng tài liệu thô về máy
          final List<DocumentSnapshot> rawChats = snapshot.data!.docs;

          if (rawChats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 70, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  const Text('Chưa có hội thoại nào với khách hàng.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // 3. ✅ ĐÃ SỬA: Tự sắp xếp danh sách bằng code Dart ngay trên RAM thiết bị (Client-side sort giống React)
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

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: rawChats.length,
            itemBuilder: (context, index) {
              final chatData = rawChats[index].data() as Map<String, dynamic>;

              final List users = chatData['users'] ?? [];
              final String clientId = users.firstWhere((id) => id != workerId, orElse: () => '');

              // Lấy tên động hiển thị theo cấu trúc 'name_clientId'
              final String clientName = chatData['name_$clientId'] ?? 'Khách hàng ẩn danh';
              final String jobTitle = chatData['jobTitle'] ?? 'Dịch vụ';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
                color: Colors.white,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF1BA39C), width: 1.5)),
                    child: const CircleAvatar(
                      backgroundColor: Color(0xFFF0F9F8),
                      child: Icon(Icons.person, color: Color(0xFF1BA39C)),
                    ),
                  ),
                  title: Text(
                    clientName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF333333)),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      '[$jobTitle] ${chatData['lastMessage'] ?? 'Bấm để bắt đầu cuộc trò chuyện...'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    if (clientId.isNotEmpty) {
                      context.push('/worker/chat/$clientId'); // Đẩy đúng clientId sang đồng bộ AppRouter
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}