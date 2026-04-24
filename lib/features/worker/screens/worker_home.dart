import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/booking_model.dart'; // Import model để đồng bộ

class WorkerHomeScreen extends StatelessWidget {
  const WorkerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'BẢNG CÔNG VIỆC',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
          ),
          backgroundColor: const Color(0xFF1BA39C),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'VIỆC MỚI', icon: Icon(Icons.work_outline)),
              Tab(text: 'ĐANG LÀM', icon: Icon(Icons.assignment_turned_in)),
            ],
          ),
        ),
        body: Container(
          color: Colors.grey[100], // Nền xám nhạt cho chuyên nghiệp
          child: TabBarView(
            children: [
              // Tab 1: Danh sách việc đang chờ (Chưa có ai nhận)
              _buildJobList(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('status', isEqualTo: 'pending')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
              ),
              // Tab 2: Danh sách việc thợ HIỆN TẠI đã nhận
              _buildJobList(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('workerId', isEqualTo: uid)
                    .where('status', isEqualTo: 'accepted')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJobList({required Stream<QuerySnapshot> stream}) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Đã có lỗi xảy ra khi tải dữ liệu'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 10),
                const Text('Hiện không có công việc nào.',
                    style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          );
        }

        // ĐỒNG BỘ: Chuyển đổi docs sang List<BookingModel>
        final jobs = docs.map((doc) => BookingModel.fromFirestore(doc)).toList();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = jobs[index];

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: InkWell(
                onTap: () => context.push('/worker/job/${job.id}'),
                borderRadius: BorderRadius.circular(15),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    children: [
                      // Vòng tròn chứa icon dịch vụ (Có thể tùy biến theo loại dịch vụ)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1BA39C).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.build_circle, color: Color(0xFF1BA39C), size: 30),
                      ),
                      const SizedBox(width: 15),

                      // Thông tin chi tiết
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.serviceName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Khách: ${job.clientName}',
                              style: TextStyle(color: Colors.grey[700], fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 14, color: Colors.redAccent),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    job.address,
                                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Giá tiền và icon mũi tên
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${job.price.toStringAsFixed(0)}đ',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                                fontSize: 15
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}