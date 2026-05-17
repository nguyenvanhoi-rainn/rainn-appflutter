import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class JobDetailScreen extends StatefulWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _isProcessing = false;

  // Định dạng tiền tệ VNĐ
  String _formatPrice(dynamic p) {
    if (p == null || p == "Thương lượng") return "Thỏa thuận";
    final formatter = NumberFormat("#,###", "vi_VN");
    try {
      return "${formatter.format(int.parse(p.toString().replaceAll(',', '')))} VNĐ";
    } catch (e) {
      return "$p VNĐ";
    }
  }

  // HÀM NHẬN VIỆC & TỰ ĐỘNG GỬI VỊ TRÍ + GIÁ (ĐÃ ĐỒNG BỘ ROUTER CHAT)
  Future<void> _handleAcceptJob(Map<String, dynamic> job) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn đồng ý nhận công việc này và bắt đầu trao đổi với khách?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Đồng ý')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final String currentUserName = FirebaseAuth.instance.currentUser?.displayName ?? 'Người làm';
    final String clientId = job['clientId'] ?? '';

    try {
      // 1. Cập nhật trạng thái Job sang accepted
      final jobRef = FirebaseFirestore.instance.collection('jobs').doc(widget.jobId);
      await jobRef.update({
        'status': 'accepted',
        'workerId': currentUserId,
        'workerName': currentUserName,
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // 2. Tạo Chat ID theo quy tắc đối sánh băm tài khoản để gom nhóm hội thoại cố định
      final String chatId = currentUserId.hashCode <= clientId.hashCode
          ? '${currentUserId}_$clientId'
          : '${clientId}_$currentUserId';

      // 3. Tạo/Cập nhật Metadata phòng chat
      await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'lastMessage': '📍 Hệ thống đã cập nhật thông tin công việc',
        'updatedAt': FieldValue.serverTimestamp(),
        'users': [currentUserId, clientId],
        'jobTitle': job['subService'],
        'name_$clientId': job['clientName'] ?? 'Khách hàng',
        'name_$currentUserId': currentUserName,
      }, SetOptions(merge: true));

      // 4. Gửi tin nhắn vị trí bản đồ tự động (Nếu có ghim tọa độ)
      if (job['location'] != null) {
        await FirebaseFirestore.instance.collection('chats/$chatId/messages').add({
          'text': '📍 Vị trí công việc',
          'senderId': clientId,
          'createdAt': FieldValue.serverTimestamp(),
          'type': 'location',
          'latitude': job['location']['latitude'],
          'longitude': job['location']['longitude'],
        });
      }

      // 5. Gửi tin nhắn báo giá dự kiến
      if (job['price'] != null && job['price'] != "Thương lượng") {
        await FirebaseFirestore.instance.collection('chats/$chatId/messages').add({
          'text': '💰 Giá dự kiến cho dịch vụ này là: ${_formatPrice(job['price'])}',
          'senderId': clientId,
          'createdAt': FieldValue.serverTimestamp(),
          'type': 'text',
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã nhận việc thành công!')),
        );
        // ✅ ĐÃ SỬA: Điều hướng dựa theo cấu trúc định danh clientId của AppRouter
        context.push('/worker/chat/$clientId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Chi tiết công việc',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Không tìm thấy công việc"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String status = data['status'] ?? 'pending';

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMainCard(data),
                      const SizedBox(height: 20),
                      _buildWarningBox(),
                    ],
                  ),
                ),
              ),
              _buildFooter(status, data),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMainCard(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data['groupService']?.toUpperCase() ?? 'DỊCH VỤ',
                style: const TextStyle(
                  color: Color(0xFF1BA39C),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatPrice(data['price']),
                  style: const TextStyle(
                    color: Color(0xFF1BA39C),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            data['subService'] ?? 'Dịch vụ',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Khách hàng: ${data['clientName'] ?? "Ẩn danh"}',
            style: const TextStyle(color: Colors.grey),
          ),
          const Divider(height: 30),
          _buildIconInfo(Icons.calendar_today, 'Ngày: ${data['workDate']}'),
          _buildIconInfo(Icons.access_time, 'Giờ: ${data['workTime']}'),
          _buildIconInfo(
            Icons.location_on,
            'Địa chỉ: ${data['address']}',
            iconColor: Colors.redAccent,
          ),
          const SizedBox(height: 20),
          const Text(
            "MÔ TẢ CHI TIẾT",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              data['description'] ?? 'Không có mô tả chi tiết.',
              style: const TextStyle(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconInfo(IconData icon, String text, {Color iconColor = const Color(0xFF1BA39C)}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildWarningBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF9E7),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFFCF3CF)),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_outlined, color: Color(0xFF9A7D0A)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Mọi giao dịch nên được thực hiện qua ứng dụng để đảm bảo quyền lợi tốt nhất.",
              style: TextStyle(color: Color(0xFF9A7D0A), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(String status, Map<String, dynamic> jobData) {
    final String clientId = jobData['clientId'] ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          // Nút nhắn tin trao đổi nhanh với khách
          OutlinedButton(
            onPressed: () {
              if (clientId.isNotEmpty) {
                // ✅ ĐÃ SỬA: Thay thế việc truyền chuỗi ghép phức tạp thành cấu trúc clientId gọn đẹp
                context.push('/worker/chat/$clientId');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Không thể kết nối phòng chat với khách hàng này.')),
                );
              }
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              side: const BorderSide(color: Color(0xFF1BA39C)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Icon(Icons.chat_bubble_outline, color: Color(0xFF1BA39C)),
          ),
          const SizedBox(width: 12),
          // Nút bấm xác nhận xử lý nhận việc
          Expanded(
            child: ElevatedButton(
              onPressed: (_isProcessing || status == 'completed')
                  ? null
                  : () => _handleAcceptJob(jobData),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1BA39C),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                status == 'pending' ? 'NHẬN VIỆC' : 'ĐANG THỰC HIỆN',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}