import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkerChatDetailScreen extends StatefulWidget {
  final String chatId;
  const WorkerChatDetailScreen({super.key, required this.chatId});

  @override
  State<WorkerChatDetailScreen> createState() => _WorkerChatDetailScreenState();
}

class _WorkerChatDetailScreenState extends State<WorkerChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final msg = _messageController.text.trim();
    _messageController.clear();

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'text': msg,
      'senderId': FirebaseAuth.instance.currentUser?.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Cập nhật tin nhắn cuối cùng để hiện ở danh sách chat
    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
      'lastMessage': msg,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nhắn tin với Khách')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    bool isMe = data['senderId'] == FirebaseAuth.instance.currentUser?.uid;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF1BA39C) : Colors.grey[300],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          data['text'] ?? '',
                          style: TextStyle(color: isMe ? Colors.white : Colors.black),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(hintText: 'Nhập tin nhắn...', border: OutlineInputBorder()),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send, color: Color(0xFF1BA39C)), onPressed: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}