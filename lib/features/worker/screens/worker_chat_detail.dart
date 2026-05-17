import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class WorkerChatDetailScreen extends StatefulWidget {
  final String chatId; // Router truyền vào đây thực chất là clientId (mã ID Khách)
  const WorkerChatDetailScreen({super.key, required this.chatId});

  @override
  State<WorkerChatDetailScreen> createState() => _WorkerChatDetailScreenState();
}

class _WorkerChatDetailScreenState extends State<WorkerChatDetailScreen> {
  final _messageController = TextEditingController();
  final _quoteController = TextEditingController();
  final _scrollController = ScrollController();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  String actualChatId = ''; // Biến lưu chuỗi ID phòng chat thực tế (workerId_clientId)
  Map<String, dynamic>? jobData;
  Map<String, dynamic>? clientData;
  bool _isUploadingImage = false; // Trạng thái hiển thị vòng tải khi up ảnh

  @override
  void initState() {
    super.initState();
    _setupChatAndLoadMetadata();
  }

  void _setupChatAndLoadMetadata() {
    final String clientId = widget.chatId; // Định danh rõ ràng tham số nhận từ router

    // Dựng ID phòng chat cố định chung giữa 2 user
    setState(() {
      actualChatId = currentUserId.hashCode <= clientId.hashCode
          ? '${currentUserId}_$clientId'
          : '${clientId}_$currentUserId';
    });

    if (clientId.isNotEmpty) {
      // 1. Lắng nghe thông tin thông tin Khách hàng để hiện lên Header
      FirebaseFirestore.instance.collection('users').doc(clientId).snapshots().listen((snap) {
        if (mounted) {
          setState(() => clientData = snap.data());
        }
      });

      // 2. Lắng nghe trạng thái công việc (Job) đang xử lý giữa 2 người
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

  // Cập nhật hàm xử lý gửi tin nhắn linh hoạt các loại tham số dữ liệu
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

    // Đẩy tin nhắn vào nhóm sub-collection của phòng chat thực tế
    await FirebaseFirestore.instance.collection('chats/$actualChatId/messages').add(messageData);

    // Cập nhật dòng trạng thái tin nhắn cuối cùng ngoài danh sách chat
    await FirebaseFirestore.instance.collection('chats').doc(actualChatId).update({
      'lastMessage': type == 'image' ? '📷 Hình ảnh' : msg,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _handlePickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (image == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final String fileExtension = image.path.split('.').last;
      final String fileName = "${DateTime.now().millisecondsSinceEpoch}.$fileExtension";
      final Reference storageRef = FirebaseStorage.instance.ref().child('chats/$actualChatId/$fileName');

      // Thực hiện đẩy tệp tin lên kho lưu trữ đám mây Storage
      final UploadTask uploadTask = storageRef.putFile(File(image.path));
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Đẩy gói tin nhắn chứa liên kết ảnh lên phòng chat Firestore
      _sendMessage(
        text: '📷 Hình ảnh',
        type: 'image',
        extraData: {'fileUrl': downloadUrl},
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải ảnh phía Thợ: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thực hiện báo giá trước khi gửi yêu cầu hoàn thành.')),
      );
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
    if (actualChatId.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
            onPressed: () {
              if (clientData?['phone'] != null) {
                launchUrl(Uri.parse('tel:${clientData?['phone']}'));
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // TOOLBAR CHỨC NĂNG
          _buildToolBar(),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats/$actualChatId/messages')
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

          // Thanh trạng thái loading ngắn gọn khi thợ đang đẩy hình ảnh lên storage
          if (_isUploadingImage)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1BA39C))),
                  SizedBox(width: 8),
                  Text('Đang tải hình ảnh lên...', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),

          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildToolBar() {
    final String currentStatus = jobData?['status'] ?? '';
    final dynamic rawPrice = jobData?['price'];

    bool isNegotiable = rawPrice == "Thương lượng" || currentStatus == 'quoted';

    bool showQuoteBtn = false;
    bool showCompleteBtn = false;
    bool isCompleteActive = false;

    if (!isNegotiable) {
      showQuoteBtn = false;
      showCompleteBtn = true;

      isCompleteActive = currentStatus == 'accepted' || currentStatus == 'confirmed';
    } else {
      if (currentStatus == 'confirmed') {
        showQuoteBtn = false;
        showCompleteBtn = true;
        isCompleteActive = true;
      } else {
        showQuoteBtn = true;
        showCompleteBtn = false;
        isCompleteActive = false;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
      color: Colors.white,
      child: Row(
        children: [
          if (showQuoteBtn) ...[
            _toolBtn('Báo giá', Icons.payments_outlined, _showQuoteModal),
            const SizedBox(width: 8),
          ],

          if (showCompleteBtn) ...[
            _toolBtn(
                'Hoàn thành',
                Icons.check_circle_outline,
                _handleCompleteJob,
                isActive: isCompleteActive,
                activeColor: const Color(0xFF1BA39C)
            ),
            const SizedBox(width: 8),
          ],

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
        child: Image.network(
          data['fileUrl'],
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40, color: Colors.grey),
        ),
      );
    }

    if (type == 'location') {
      double lat = double.tryParse(data['latitude'].toString()) ?? 10.9805;
      double lng = double.tryParse(data['longitude'].toString()) ?? 106.6745;
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 150,
          width: 200,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: LatLng(lat, lng), zoom: 15),
            markers: {Marker(markerId: const MarkerId('loc'), position: LatLng(lat, lng))},
            liteModeEnabled: true,
          ),
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
          IconButton(
              icon: const Icon(Icons.image_outlined, color: Color(0xFF1BA39C)),
              onPressed: _handlePickAndUploadImage
          ),
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
            child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: () => _sendMessage()
            ),
          ),
        ],
      ),
    );
  }
}