import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class WorkerReviewsScreen extends StatelessWidget {
  const WorkerReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Đánh giá & Phản hồi',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF333333)),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .where('workerId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final reviews = snapshot.data?.docs ?? [];

          if (reviews.isEmpty) {
            return _buildEmptyState();
          }

          // Tính toán số sao trung bình thực tế
          double totalRating = 0;
          for (var doc in reviews) {
            totalRating += (doc.data() as Map<String, dynamic>)['rating'] ?? 0;
          }
          double avgRating = totalRating / reviews.length;

          return Column(
            children: [
              // --- 1. KHỐI TÓM TẮT ĐÁNH GIÁ (DASHBOARD SUMMARY) ---
              _buildSummaryHeader(avgRating, reviews.length),

              const Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F5)),

              // --- 2. DANH SÁCH CHI TIẾT CÁC NHẬN XÉT ---
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final data = reviews[index].data() as Map<String, dynamic>;
                    return _buildReviewItem(data);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Giao diện khi chưa có ai đánh giá
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_outline_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 15),
          const Text(
            'Bạn chưa có phản hồi nào từ khách hàng.',
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
        ],
      ),
    );
  }

  // Khối Header hiện tổng quan số sao
  Widget _buildSummaryHeader(double avg, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30),
      width: double.infinity,
      color: const Color(0xFFF9FAFB),
      child: Column(
        children: [
          Text(
            avg.toStringAsFixed(1),
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
          ),
          const SizedBox(height: 5),
          _buildStarRating(avg.round()), // Hiển thị 5 ngôi sao vàng
          const SizedBox(height: 10),
          Text(
            'Dựa trên $count nhận xét từ khách hàng',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị danh sách ngôi sao dựa trên số điểm
  Widget _buildStarRating(int rating, {double size = 20}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          color: const Color(0xFFFFD700),
          size: size,
        );
      }),
    );
  }

  // Widget hiển thị từng dòng nhận xét chi tiết
  Widget _buildReviewItem(Map<String, dynamic> data) {
    final Timestamp? createdAt = data['createdAt'];
    final String dateStr = createdAt != null
        ? DateFormat('dd/MM/yyyy').format(createdAt.toDate())
        : 'Gần đây';

    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lấy ảnh đại diện khách hàng (Nếu có clientId thì có thể Stream thêm thông tin user)
          const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFFF0F2F5),
            child: Icon(Icons.person, color: Colors.grey, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Khách hàng RAINN', // Hội có thể Stream thêm tên thật nếu muốn xịn hơn
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                _buildStarRating(data['rating'] ?? 5, size: 16),
                const SizedBox(height: 8),
                Text(
                  data['comment'] ?? 'Không có nội dung nhận xét.',
                  style: const TextStyle(color: Color(0xFF4A4A4A), fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}