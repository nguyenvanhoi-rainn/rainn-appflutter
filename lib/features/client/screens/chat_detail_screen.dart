import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class ClientChatDetailScreen extends StatefulWidget {
  final String workerId;
  final String workerName;

  ClientChatDetailScreen({required this.workerId, required this.workerName});

  @override
  _ClientChatDetailScreenState createState() => _ClientChatDetailScreenState();
}

class _ClientChatDetailScreenState extends State<ClientChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final userId = FirebaseAuth.instance.currentUser?.uid;

  String getChatId() {
    return userId!.hashCode <= widget.workerId.hashCode
        ? '${userId}_${widget.workerId}'
        : '${widget.workerId}_$userId';
  }

  // Gửi tin nhắn văn bản
  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    await FirebaseFirestore.instance
        .collection('chats/${getChatId()}/messages')
        .add({
      'text': _controller.text.trim(),
      'senderId': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'type': 'text',
    });

    await FirebaseFirestore.instance.collection('chats').doc(getChatId()).update({
      'lastMessage': _controller.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    _controller.clear();
  }

  // Modal đánh giá thợ (⭐)
  void _showReviewModal(String jobId) {
    int rating = 5;
    TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Hoàn thành công việc!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  icon: Icon(index < rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 40),
                  onPressed: () => setModalState(() => rating = index + 1),
                )),
              ),
              TextField(
                controller: commentController,
                decoration: InputDecoration(hintText: "Nhận xét của bạn...", border: OutlineInputBorder()),
                maxLines: 3,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1BA39C), minimumSize: Size(double.infinity, 50)),
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('reviews').add({
                    'jobId': jobId,
                    'workerId': widget.workerId,
                    'clientId': userId,
                    'rating': rating,
                    'comment': commentController.text,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({'status': 'reviewed'});
                  Navigator.pop(context);
                },
                child: Text("GỬI ĐÁNH GIÁ", style: TextStyle(color: Colors.white)),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.workerName, style: TextStyle(color: Colors.black, fontSize: 17)),
            Text("Xem hồ sơ thợ", style: TextStyle(color: Color(0xFF1BA39C), fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(icon: Icon(Icons.phone, color: Color(0xFF1BA39C)), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Lắng nghe trạng thái đơn hàng (Job Status)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('jobs')
                .where('clientId', isEqualTo: userId)
                .where('workerId', isEqualTo: widget.workerId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                var job = snapshot.data!.docs.first;
                if (job['status'] == 'completed') {
                  // Tự động hiện modal nếu hoàn thành
                  WidgetsBinding.instance.addPostFrameCallback((_) => _showReviewModal(job.id));
                }
                if (job['status'] == 'quoted') {
                  return Container(
                    color: Colors.amber[50],
                    padding: EdgeInsets.all(10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Thợ báo giá: ${job['price']}đ"),
                        ElevatedButton(
                          onPressed: () {},
                          child: Text("Chấp nhận"),
                          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1BA39C)),
                        )
                      ],
                    ),
                  );
                }
              }
              return SizedBox.shrink();
            },
          ),
          // Danh sách tin nhắn
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats/${getChatId()}/messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                var docs = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var msg = docs[index];
                    bool isMe = msg['senderId'] == userId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.all(8),
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Color(0xFF1BA39C) : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(msg['text'] ?? "", style: TextStyle(color: isMe ? Colors.white : Colors.black)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Ô nhập liệu
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(icon: Icon(Icons.image, color: Color(0xFF1BA39C)), onPressed: () {}),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(hintText: "Tin nhắn...", border: OutlineInputBorder(borderRadius: BorderRadius.circular(30))),
                  ),
                ),
                IconButton(icon: Icon(Icons.send, color: Color(0xFF1BA39C)), onPressed: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}