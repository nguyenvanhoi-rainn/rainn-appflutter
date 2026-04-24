import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminJobsManagement extends StatelessWidget {
  const AdminJobsManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tất cả công việc')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('bookings').snapshots(), //
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final jobs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(job['serviceName'] ?? 'Dịch vụ không tên'),
                  subtitle: Text('Khách: ${job['clientName']} - Trạng thái: ${job['status']}'),
                  trailing: _buildStatusChip(job['status']),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    Color color = Colors.grey;
    if (status == 'pending') color = Colors.orange;
    if (status == 'accepted') color = Colors.blue;
    if (status == 'completed') color = Colors.green;

    return Chip(
      label: Text(status ?? 'N/A', style: const TextStyle(color: Colors.white, fontSize: 10)),
      backgroundColor: color,
    );
  }
}