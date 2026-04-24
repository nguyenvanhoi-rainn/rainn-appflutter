import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class WorkerScheduleScreen extends StatelessWidget {
  const WorkerScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lịch trình của tôi'),
          backgroundColor: const Color(0xFF1BA39C),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Đang thực hiện'),
              Tab(text: 'Đã hoàn thành'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildScheduleList(uid, 'accepted'), // Các việc đã nhận nhưng chưa xong
            _buildScheduleList(uid, 'completed'), // Các việc đã làm xong
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleList(String? workerId, String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('workerId', isEqualTo: workerId)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Đã có lỗi xảy ra'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final jobs = snapshot.data!.docs;
        if (jobs.isEmpty) {
          return Center(
            child: Text(status == 'accepted'
                ? 'Bạn không có lịch trình nào hôm nay.'
                : 'Bạn chưa hoàn thành công việc nào.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = jobs[index].data() as Map<String, dynamic>;
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(
                  status == 'accepted' ? Icons.access_time_filled : Icons.check_circle,
                  color: status == 'accepted' ? Colors.orange : Colors.green,
                ),
                title: Text(job['serviceName'] ?? 'Dịch vụ', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Khách: ${job['clientName']}\nĐ/c: ${job['address']}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => context.push('/worker/job/${jobs[index].id}'),
              ),
            );
          },
        );
      },
    );
  }
}