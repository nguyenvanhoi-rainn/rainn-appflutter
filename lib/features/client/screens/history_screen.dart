import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử dịch vụ'),
        backgroundColor: const Color(0xFF1BA39C),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('clientId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Đã có lỗi xảy ra.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = snapshot.data!.docs;
          if (bookings.isEmpty) {
            return const Center(child: Text('Bạn chưa có yêu cầu dịch vụ nào.'));
          }

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final doc = bookings[index];
              final data = doc.data() as Map<String, dynamic>;
              final String jobId = doc.id;
              final String status = data['status'] ?? 'pending';
              final String paymentStatus = data['paymentStatus'] ?? 'unpaid';
              final double price = (data['price'] ?? 200000).toDouble(); // Mặc định 200k nếu chưa có giá

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      ListTile(
                        leading: _buildStatusIcon(status),
                        title: Text(
                          data['serviceName'] ?? 'Dịch vụ',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            Text('Ngày đặt: ${data['date'] ?? 'Không rõ'}'),
                            Text('Thợ: ${data['workerName'] ?? 'Đang tìm thợ...'}'),
                            const SizedBox(height: 5),
                            _buildStatusChip(status, paymentStatus),
                          ],
                        ),
                        trailing: Text(
                          '${price.toStringAsFixed(0)}đ',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                        ),
                      ),

                      // Nút Thanh toán hiển thị khi việc đã xong nhưng chưa trả tiền
                      if (status == 'completed' && paymentStatus != 'paid')
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => context.push('/payment/$jobId/$price'),
                              icon: const Icon(Icons.payment),
                              label: const Text('THANH TOÁN NGAY'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ),
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

  // Icon biểu thị trạng thái
  Widget _buildStatusIcon(String status) {
    IconData icon;
    Color color;
    switch (status) {
      case 'completed':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'accepted':
        icon = Icons.engineering;
        color = Colors.blue;
        break;
      default:
        icon = Icons.pending_actions;
        color = Colors.orange;
    }
    return Icon(icon, color: color, size: 35);
  }

  // Nhãn trạng thái (Status Chip)
  Widget _buildStatusChip(String status, String paymentStatus) {
    String label = 'Đang chờ';
    Color color = Colors.orange;

    if (status == 'accepted') {
      label = 'Thợ đang đến';
      color = Colors.blue;
    } else if (status == 'completed') {
      if (paymentStatus == 'paid') {
        label = 'Hoàn thành & Đã thanh toán';
        color = Colors.green;
      } else {
        label = 'Chờ thanh toán';
        color = Colors.red;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}