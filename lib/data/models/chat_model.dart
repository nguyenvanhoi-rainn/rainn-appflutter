import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final String clientId;
  final String workerId;
  final String lastMessage;
  final DateTime? lastMessageAt;

  ChatModel({
    required this.id,
    required this.clientId,
    required this.workerId,
    this.lastMessage = '',
    this.lastMessageAt,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      workerId: data['workerId'] ?? '',
      lastMessage: data['lastMessage'] ?? '',
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
    );
  }
}