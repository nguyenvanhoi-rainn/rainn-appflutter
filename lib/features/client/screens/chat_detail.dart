import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class ClientChatDetailScreen extends StatefulWidget {
  final String workerId;
  const ClientChatDetailScreen({super.key, required this.workerId});

  @override
  _ClientChatDetailScreenState createState() => _ClientChatDetailScreenState();
}

class _ClientChatDetailScreenState extends State<ClientChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final userId = FirebaseAuth.instance.currentUser?.uid;

  Map<String, dynamic>? workerData;
  bool _isUploadingImage = false; // Trạng thái đợi tải ảnh lên storage

  @override
  void initState() {
    super.initState();
    _loadWorkerInfo();
  }

  void _loadWorkerInfo() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.workerId)
        .snapshots()
        .listen((snap) {
      if (snap.exists && mounted) {
        setState(() => workerData = snap.data());
      }
    });
  }

  String getChatId() {
    return userId!.hashCode <= widget.workerId.hashCode
        ? '${userId}_${widget.workerId}'
        : '${widget.workerId}_$userId';
  }

  // 1. Gửi tin nhắn chung (Hỗ trợ text, location, image)
  void _sendGenericMessage({String? text, String type = 'text', Map<String, dynamic>? extraData}) async {
    final msg = text ?? _controller.text.trim();
    if (msg.isEmpty && type == 'text') return;

    if (type == 'text') _controller.clear();

    final messageData = {
      'text': msg,
      'senderId': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'type': type,
      ...?extraData,
    };

    await FirebaseFirestore.instance.collection('chats/${getChatId()}/messages').add(messageData);
    await FirebaseFirestore.instance.collection('chats').doc(getChatId()).update({
      'lastMessage': type == 'image' ? '📷 Hình ảnh' : msg,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 2. XỬ LÝ CHỌN VÀ TẢI ẢNH LÊN FIREBASE STORAGE
  Future<void> _handlePickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (image == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final String fileExtension = image.path.split('.').last;
      final String fileName = "${DateTime.now().millisecondsSinceEpoch}.$fileExtension";
      final Reference storageRef = FirebaseStorage.instance.ref().child('chats/${getChatId()}/$fileName');

      // Tải file trực tiếp lên Firebase Storage
      final UploadTask uploadTask = storageRef.putFile(File(image.path));
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Sau khi lấy được link URL, thực hiện gửi tin nhắn loại image
      _sendGenericMessage(
        text: '📷 Hình ảnh',
        type: 'image',
        extraData: {'fileUrl': downloadUrl},
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải ảnh: $e')));
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  // Modal đánh giá thợ (⭐)
  void _showReviewModal(String jobId) {
    int rating = 5;
    TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Hoàn thành công việc!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  icon: Icon(index < rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 40),
                  onPressed: () => setModalState(() => rating = index + 1),
                )),
              ),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(hintText: "Nhận xét của bạn...", border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              Navigator(
                onGenerateRoute: (_) => MaterialPageRoute(
                  builder: (context) => ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1BA39C), minimumSize: const Size(double.infinity, 50)),
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
                      if (mounted) Navigator.pop(context);
                    },
                    child: const Text("GỬI ĐÁNH GIÁ", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String workerName = workerData?['fullName'] ?? 'Đang tải...';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(workerName, style: const TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.bold)),
            const Text("Xem hồ sơ thợ", style: TextStyle(color: Color(0xFF1BA39C), fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.phone, color: Color(0xFF1BA39C)),
              onPressed: () {
                if (workerData?['phone'] != null) {
                  launchUrl(Uri.parse('tel:${workerData?['phone']}'));
                }
              }
          ),
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
                final jobDataMap = job.data() as Map<String, dynamic>;

                if (jobDataMap['status'] == 'completed') {
                  WidgetsBinding.instance.addPostFrameCallback((_) => _showReviewModal(job.id));
                }
                if (jobDataMap['status'] == 'quoted') {
                  final priceText = jobDataMap['price'] != null
                      ? NumberFormat("#,###").format(int.tryParse(jobDataMap['price'].toString()) ?? 0)
                      : '0';
                  return Container(
                    color: Colors.amber[50],
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Thợ báo giá: ${priceText}đ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1BA39C)),
                          child: const Text("Chấp nhận", style: TextStyle(color: Colors.white)),
                        )
                      ],
                    ),
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),

          // Danh sách tin nhắn phân loại hiển thị
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats/${getChatId()}/messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var docs = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var msg = docs[index].data() as Map<String, dynamic>;
                    bool isMe = msg['senderId'] == userId;
                    return _buildMessageBubble(msg, isMe);
                  },
                );
              },
            ),
          ),

          if (_isUploadingImage)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1BA39C))),
                  SizedBox(width: 10),
                  Text('Đang tải hình ảnh lên...', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),

          // Ô nhập liệu kết nối hàm xử lý
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                    icon: const Icon(Icons.image, color: Color(0xFF1BA39C)),
                    onPressed: _handlePickAndUploadImage // ✅ ĐÃ KẾT NỐI HÀM CHỌN ẢNH VÀO ĐÂY
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                        hintText: "Tin nhắn...",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30))
                    ),
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF1BA39C)),
                    onPressed: () => _sendGenericMessage()
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ ĐÃ THÊM: Hàm phân tách loại UI hiển thị bong bóng tin nhắn
  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    String type = msg['type'] ?? 'text';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: type == 'text' ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10) : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: type != 'text'
              ? Colors.transparent
              : (isMe ? const Color(0xFF1BA39C) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          boxShadow: type == 'text'
              ? [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))]
              : null,
        ),
        child: _buildMessageContent(msg, isMe),
      ),
    );
  }

  // ✅ ĐÃ THÊM: Hàm vẽ chi tiết nội dung (Bản đồ / Hình ảnh / Văn bản) tương thích dữ liệu Firestore
  Widget _buildMessageContent(Map<String, dynamic> msg, bool isMe) {
    String type = msg['type'] ?? 'text';

    if (type == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          msg['fileUrl'],
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50),
        ),
      );
    }

    if (type == 'location') {
      double lat = double.tryParse(msg['latitude'].toString()) ?? 10.9805;
      double lng = double.tryParse(msg['longitude'].toString()) ?? 106.6745;
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 160,
          width: 220,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: LatLng(lat, lng), zoom: 15),
            markers: {Marker(markerId: const MarkerId('job_loc'), position: LatLng(lat, lng))},
            liteModeEnabled: true, // Bật chế độ tối giản giúp cuộn mượt mà
          ),
        ),
      );
    }

    // Mặc định trả về văn bản thường
    return Text(
        msg['text'] ?? "",
        style: TextStyle(color: isMe ? Colors.white : const Color(0xFF2D3436), fontSize: 15)
    );
  }
}