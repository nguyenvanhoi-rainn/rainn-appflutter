import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Thu nhập của tôi'), backgroundColor: const Color(0xFF1BA39C)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('workerId', isEqualTo: uid)
            .where('status', isEqualTo: 'completed')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final completedJobs = snapshot.data!.docs;
          // Giả định mỗi công việc có giá tiền cố định hoặc lưu trong field 'price'
          double totalBalance = completedJobs.length * 200000; // Ví dụ 200k/việc

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                color: const Color(0xFF1BA39C),
                child: Column(
                  children: [
                    const Text('Tổng số dư', style: TextStyle(color: Colors.white70)),
                    Text('${totalBalance.toStringAsFixed(0)} VNĐ',
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: completedJobs.length,
                  itemBuilder: (context, index) {
                    final job = completedJobs[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: const Icon(Icons.add_circle, color: Colors.green),
                      title: Text(job['serviceName'] ?? 'Dịch vụ'),
                      subtitle: Text('Hoàn thành ngày: ${job['date']}'),
                      trailing: const Text('+200.000đ', style: TextStyle(fontWeight: FontWeight.bold)),
                    );
                  },
                ),
              )
            ],
          );
        },
      ),
    );
  }
}