import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class JobDetailScreen extends StatefulWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _isProcessing = false;

  // Hàm cập nhật trạng thái công việc
  Future<void> _updateJobStatus(String status) async {
    setState(() => _isProcessing = true);
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    try {
      Map<String, dynamic> updateData = {'status': status};

      if (status == 'accepted') {
        updateData['workerId'] = uid;
        updateData['acceptedAt'] = FieldValue.serverTimestamp();
      } else if (status == 'completed') {
        updateData['completedAt'] = FieldValue.serverTimestamp();
      }

      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.jobId)
          .update(updateData);

      if (mounted) {
        String msg = status == 'accepted' ? 'Đã nhận việc thành công!' : 'Chúc mừng bạn đã hoàn thành!';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết công việc')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('bookings').doc(widget.jobId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String status = data['status'] ?? 'pending';

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(data['serviceName'] ?? 'Dịch vụ'),
                const SizedBox(height: 20),
                _buildInfoSection('Thông tin khách hàng', [
                  'Tên: ${data['clientName']}',
                  'Địa chỉ: ${data['address']}',
                ]),
                const Divider(height: 40),
                _buildInfoSection('Mô tả công việc', [
                  data['description'] ?? 'Không có mô tả chi tiết.',
                ]),
                const Spacer(),
                _buildActionButton(status),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1BA39C)),
    );
  }

  Widget _buildInfoSection(String title, List<String> lines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        ...lines.map((line) => Text(line, style: const TextStyle(fontSize: 16, height: 1.5))),
      ],
    );
  }

  Widget _buildActionButton(String status) {
    if (status == 'completed') return const SizedBox.shrink();

    String btnText = status == 'pending' ? 'NHẬN CÔNG VIỆC' : 'HOÀN THÀNH CÔNG VIỆC';
    Color btnColor = status == 'pending' ? const Color(0xFF1BA39C) : Colors.orange;

    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : () => _updateJobStatus(status == 'pending' ? 'accepted' : 'completed'),
        style: ElevatedButton.styleFrom(
          backgroundColor: btnColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isProcessing
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(btnText, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}