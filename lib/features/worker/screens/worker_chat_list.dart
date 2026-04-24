import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class WorkerChatList extends StatelessWidget {
  const WorkerChatList({super.key});

  @override
  Widget build(BuildContext context) {
    final workerId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin nhắn khách hàng'),
        backgroundColor: const Color(0xFF1BA39C),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Lấy các cuộc hội thoại mà Worker này tham gia
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('workerId', isEqualTo: workerId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final chats = snapshot.data!.docs;
          if (chats.isEmpty) return const Center(child: Text('Chưa có tin nhắn nào.'));

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(chat['clientName'] ?? 'Khách hàng'),
                subtitle: Text(chat['lastMessage'] ?? 'Bấm để nhắn tin...'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/worker/chat/${chats[index].id}'),
              );
            },
          );
        },
      ),
    );
  }
}