import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin nhắn'),
        backgroundColor: const Color(0xFF1BA39C),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Lấy các cuộc hội thoại mà user hiện tại tham gia
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: 'ID_USER_HIEN_TAI') // Cần lấy UID từ Auth
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final chats = snapshot.data!.docs;

          if (chats.isEmpty) {
            return const Center(child: Text('Chưa có tin nhắn nào.'));
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF1BA39C),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(chat['otherUserName'] ?? 'Người dùng'),
                subtitle: Text(chat['lastMessage'] ?? ''),
                trailing: Text(
                  _formatTime(chat['lastMessageTime']),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                onTap: () => context.push('/chat/${chats[index].id}'),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime date = (timestamp as Timestamp).toDate();
    return "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}