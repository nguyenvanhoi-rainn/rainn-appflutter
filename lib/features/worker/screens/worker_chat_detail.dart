import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class WorkerChatDetailScreen extends StatefulWidget {
  final String chatId; // ID phòng chat (WorkerID_ClientID)
  const WorkerChatDetailScreen({super.key, required this.chatId});

  @override
  State<WorkerChatDetailScreen> createState() => _WorkerChatDetailScreenState();
}

class _WorkerChatDetailScreenState extends State<WorkerChatDetailScreen> {
  final _messageController = TextEditingController();
  final _quoteController = TextEditingController();
  final _scrollController = ScrollController();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  Map<String, dynamic>? jobData;
  Map<String, dynamic>? clientData;

  @override
  void initState() {
    super.initState();
    _loadChatMetadata();
  }

  // Tải thông tin Job và Khách hàng liên quan đến cuộc hội thoại này
  void _loadChatMetadata() async {
    // 1. Lấy thông tin phòng chat để biết ai là khách
    final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).get();
    if (chatDoc.exists) {
      final List users = chatDoc.data()?['users'] ?? [];
      final String clientId = users.firstWhere((id) => id != currentUserId, orElse: () => '');

      if (clientId.isNotEmpty) {
        // 2. Lắng nghe thông tin khách hàng
        FirebaseFirestore.instance.collection('users').doc(clientId).snapshots().listen((snap) {
          if (mounted) setState(() => clientData = snap.data());
        });

        // 3. Lắng nghe trạng thái công việc (Job)
        FirebaseFirestore.instance
            .collection('jobs')
            .where('workerId', isEqualTo: currentUserId)
            .where('clientId', isEqualTo: clientId)
            .snapshots()
            .listen((snap) {
          if (snap.docs.isNotEmpty && mounted) {
            setState(() => jobData = snap.docs.first.data()..['id'] = snap.docs.first.id);
          }
        });
      }
    }
  }

  // --- CÁC HÀM XỬ LÝ CHỨC NĂNG GIỐNG REACT ---

  // 1. Gửi tin nhắn văn bản
  void _sendMessage({String? text, String type = 'text', Map<String, dynamic>? extraData}) async {
    final msg = text ?? _messageController.text.trim();
    if (msg.isEmpty && type == 'text') return;

    if (type == 'text') _messageController.clear();

    final messageData = {
      'text': msg,
      'senderId': currentUserId,
      'createdAt': FieldValue.serverTimestamp(),
      'type': type,
      ...?extraData,
    };

    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('messages').add(messageData);
    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
      'lastMessage': type == 'image' ? '📷 Hình ảnh' : msg,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 2. Báo giá (Quote)
  void _showQuoteModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nhập báo giá (VNĐ)'),
        content: TextField(
          controller: _quoteController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Ví dụ: 200000', suffixText: 'đ'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final price = int.tryParse(_quoteController.text.trim());
              if (price == null || price <= 0 || jobData == null) return;

              await FirebaseFirestore.instance.collection('jobs').doc(jobData!['id']).update({
                'price': price,
                'status': 'quoted',
              });

              _sendMessage(
                  text: '💰 BÁO GIÁ: ${NumberFormat("#,###").format(price)} VNĐ',
                  type: 'quote'
              );

              _quoteController.clear();
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1BA39C)),
            child: const Text('Gửi giá', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 3. Hoàn thành công việc
  void _handleCompleteJob() {
    if (jobData?['price'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng báo giá trước khi hoàn thành.')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hoàn thành'),
        content: Text('Bạn muốn gửi yêu cầu thanh toán ${NumberFormat("#,###").format(jobData!['price'])} VNĐ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('jobs').doc(jobData!['id']).update({
                'status': 'waiting_payment',
                'completedAt': FieldValue.serverTimestamp(),
              });

              _sendMessage(
                  text: '🏁 Công việc hoàn thành. Vui lòng thanh toán: ${NumberFormat("#,###").format(jobData!['price'])} VNĐ',
                  type: 'payment_request',
                  extraData: {'amount': jobData!['price'], 'jobId': jobData!['id']}
              );
              Navigator.pop(context);
            },
            child: const Text('Gửi yêu cầu', style: TextStyle(color: Color(0xFF1BA39C))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(clientData?['fullName'] ?? 'Đang tải...', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Text('Khách hàng của RAINN', style: TextStyle(fontSize: 11, color: Color(0xFF1BA39C))),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: Color(0xFF1BA39C)),
            onPressed: () => launchUrl(Uri.parse('tel:${clientData?['phone']}')),
          ),
        ],
      ),
      body: Column(
        children: [
          // TOOLBAR GIỐNG BẢN REACT
          _buildToolBar(),

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
                  padding: const EdgeInsets.all(15),
                  itemCount: messages.length,
                  itemBuilder: (context, index) => _buildMessageBubble(messages[index]),
                );
              },
            ),
          ),

          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildToolBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
      color: Colors.white,
      child: Row(
        children: [
          _toolBtn('Báo giá', Icons.payments_outlined, _showQuoteModal),
          const SizedBox(width: 8),
          _toolBtn(
              'Hoàn thành',
              Icons.check_circle_outline,
              _handleCompleteJob,
              isActive: jobData?['status'] == 'confirmed',
              activeColor: const Color(0xFF1BA39C)
          ),
          const SizedBox(width: 8),
          _toolBtn('Hủy đơn', Icons.cancel_outlined, () {}, color: Colors.red),
        ],
      ),
    );
  }

  Widget _toolBtn(String label, IconData icon, VoidCallback onTap, {bool isActive = true, Color? color, Color? activeColor}) {
    return Expanded(
      child: InkWell(
        onTap: isActive ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: (isActive && activeColor != null) ? activeColor : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isActive ? (color ?? const Color(0xFF1BA39C)) : Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: isActive ? (activeColor != null ? Colors.white : (color ?? const Color(0xFF1BA39C))) : Colors.grey),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? (activeColor != null ? Colors.white : (color ?? const Color(0xFF1BA39C))) : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    bool isMe = data['senderId'] == currentUserId;
    String type = data['type'] ?? 'text';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? (type == 'quote' ? Colors.orange : const Color(0xFF1BA39C)) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 20),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
        ),
        child: _buildMessageContent(data, isMe),
      ),
    );
  }

  Widget _buildMessageContent(Map<String, dynamic> data, bool isMe) {
    String type = data['type'] ?? 'text';

    if (type == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(data['fileUrl'], fit: BoxFit.cover),
      );
    }

    if (type == 'location') {
      return SizedBox(
        height: 150,
        width: 200,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: LatLng(data['latitude'], data['longitude']), zoom: 15),
          markers: {Marker(markerId: const MarkerId('loc'), position: LatLng(data['latitude'], data['longitude']))},
          liteModeEnabled: true,
        ),
      );
    }

    return Text(
      data['text'] ?? '',
      style: TextStyle(color: isMe || type == 'quote' ? Colors.white : Colors.black87, fontSize: 15),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(left: 10, right: 10, top: 10, bottom: MediaQuery.of(context).padding.bottom + 10),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.image_outlined, color: Color(0xFF1BA39C)), onPressed: () {}),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(color: const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(25)),
              child: TextField(
                controller: _messageController,
                maxLines: null,
                decoration: const InputDecoration(hintText: 'Tin nhắn...', border: InputBorder.none),
              ),
            ),
          ),
          const SizedBox(width: 5),
          CircleAvatar(
            backgroundColor: const Color(0xFF1BA39C),
            child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: _sendMessage),
          ),
        ],
      ),
    );
  }
}