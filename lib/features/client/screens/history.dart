import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Đồng bộ màu nền xám nhẹ giống React
      appBar: AppBar(
        title: const Text(
          'Lịch sử hoạt động',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1BA39C), // Màu xanh thương hiệu RAINN
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .where('clientId', isEqualTo: uid) // Lấy các job của khách hiện tại
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Đã có lỗi xảy ra khi tải lịch sử.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Lấy danh sách tài liệu thô về máy
          final List<DocumentSnapshot> rawJobs = snapshot.data!.docs;
          if (rawJobs.isEmpty) {
            return _buildEmptyState(context);
          }

          rawJobs.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;

            final Timestamp? timeA = dataA['createdAt'] as Timestamp?;
            final Timestamp? timeB = dataB['createdAt'] as Timestamp?;

            final int secondsA = timeA?.seconds ?? 0;
            final int secondsB = timeB?.seconds ?? 0;

            // Đơn hàng nào mới đặt (seconds lớn hơn) sẽ đứng đầu danh sách
            return secondsB.compareTo(secondsA);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: rawJobs.length,
            itemBuilder: (context, index) {
              final doc = rawJobs[index];
              final data = doc.data() as Map<String, dynamic>;

              final String jobId = doc.id;
              final String status = data['status'] ?? 'pending';
              final String paymentStatus = data['paymentStatus'] ?? 'unpaid';

              final String serviceName = data['subService'] ?? data['groupService'] ?? 'Dịch vụ không tên';
              final String workDate = data['workDate'] ?? 'Chưa có ngày';
              final String workTime = data['workTime'] ?? '--:--';
              final String workerName = data['workerName'] ?? 'Đang tìm thợ...';
              final dynamic priceRaw = data['price'];

              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Bo góc tròn giống React
                elevation: 2,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header của Card: Tên dịch vụ & Badge Trạng thái
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              serviceName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF2D3436)),
                            ),
                          ),
                          _buildStatusBadge(status, paymentStatus),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Body của Card: Thông tin ngày giờ & Tên thợ đảm nhận
                      Row(
                        children: [
                          const Icon(Icons.calendar_month_outlined, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            '$workDate • $workTime',
                            style: const TextStyle(color: Color(0xFF636E72), fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.engineering_outlined, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            'Thợ: $workerName',
                            style: const TextStyle(color: Color(0xFF636E72), fontSize: 14),
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: Color(0xFFF1F2F6)), // Thanh ngăn cách giống React

                      // Footer của Card: Giá cả hiển thị bên phải
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tổng thanh toán:', style: TextStyle(color: Color(0xFF95A5A6), fontSize: 13)),
                          Text(
                            _formatPrice(priceRaw),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1BA39C)),
                          ),
                        ],
                      ),

                      // Nút Thanh toán hiển thị khi công việc hoàn thành nhưng chưa tất toán ví
                      if (status == 'completed' && paymentStatus != 'paid') ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Chuyển hướng sang màn hình thanh toán ví nạp MoMo của Hội
                              context.push('/payment');
                            },
                            icon: const Icon(Icons.payment, size: 18),
                            label: const Text('THANH TOÁN NGAY', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatPrice(dynamic p) {
    if (p == null || p == "Thương lượng") return "Thỏa thuận";
    try {
      final int numPrice = p is String ? int.parse(p) : (p as num).toInt();
      return '${NumberFormat("#,###", "vi_VN").format(numPrice)} VNĐ';
    } catch (e) {
      return "Thỏa thuận";
    }
  }

  Widget _buildStatusBadge(String status, String paymentStatus) {
    String text = status;
    Color color = Colors.grey;
    Color bg = const Color(0xFFF5F5F5);

    switch (status) {
      case 'pending':
        text = "Đang chờ thợ";
        color = const Color(0xFFE67E22);
        bg = const Color(0xFFFFF3E0);
        break;
      case 'accepted':
        text = "Thợ đang đến";
        color = const Color(0xFF1BA39C);
        bg = const Color(0xFFE0F2F1);
        break;
      case 'completed':
        if (paymentStatus == 'paid') {
          text = "Đã hoàn thành";
          color = const Color(0xFF4CAF50);
          bg = const Color(0xFFE8F5E9);
        } else {
          text = "Chờ thanh toán";
          color = const Color(0xFFFF3B30);
          bg = const Color(0xFFFFEBEE);
        }
        break;
      case 'cancelled':
        text = "Đã hủy";
        color = const Color(0xFFFF3B30);
        bg = const Color(0xFFFFEBEE);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 75, color: Colors.grey[300]),
          const SizedBox(height: 15),
          const Text(
            'Bạn chưa có lịch sử hoạt động nào',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Color(0xFFAAAAAA)), // TextStyle chỉ giữ cấu hình giao diện chữ
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              context.go('/home'); // Điều hướng quay lại trang chủ đặt việc
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1BA39C),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
            child: const Text('Đặt dịch vụ ngay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}