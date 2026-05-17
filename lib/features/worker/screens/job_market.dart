import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class JobMarketScreen extends StatelessWidget {
  final String categoryId;
  final String categoryName;

  const JobMarketScreen({
    super.key,
    required this.categoryId,
    required this.categoryName
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Việc làm: $categoryName', // Hiển thị tên tiếng Việt đã được dịch ngược
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 1. LỌC REAL-TIME THEO ĐÚNG CHUYÊN MÔN VÀ TRẠNG THÁI CHỜ DUYỆT
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .where('categoryId', isEqualTo: categoryId)
            .where('status', isEqualTo: 'pending') // Chỉ hiện các việc thợ chưa nhận
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Đã xảy ra lỗi khi tải dữ liệu thị trường việc làm.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final availableJobs = snapshot.data!.docs;

          // Giao diện thông báo khi danh mục này hiện tại không có ai đặt lịch
          if (availableJobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.work_off_outlined, size: 70, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text(
                    'Hiện chưa có yêu cầu nào cho mục $categoryName.',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          // Hiển thị danh sách các bài đăng khách hàng đang gọi thợ
          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: availableJobs.length,
            itemBuilder: (context, index) {
              final job = availableJobs[index].data() as Map<String, dynamic>;
              final String jobId = availableJobs[index].id;

              // Xử lý chuỗi giá tiền giống các fragment cũ
              final String priceText = job['price'] == "Thương lượng"
                  ? "Thương lượng"
                  : "${NumberFormat("#,###").format(int.tryParse(job['price'].toString()) ?? 0)}đ";

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                elevation: 0,
                color: Colors.white,
                child: InkWell(
                  onTap: () => context.push('/worker/job/$jobId'), // Bấm để xem chi tiết bài đăng và bấm nhận việc
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      children: [
                        // Icon tròn thương hiệu
                        Container(
                          width: 45,
                          height: 45,
                          decoration: const BoxDecoration(color: Color(0xFFF0F9F8), shape: BoxShape.circle),
                          child: const Icon(Icons.handyman_outlined, color: Color(0xFF1BA39C), size: 20),
                        ),
                        const SizedBox(width: 15),

                        // Nội dung tóm tắt công việc
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job['subService'] ?? 'Yêu cầu sửa chữa',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF333333)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 13, color: Color(0xFF1BA39C)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      job['address'] ?? 'Thủ Dầu Một, Bình Dương',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '🕒 Lịch: ${job['workTime'] ?? '--:--'} ngày ${job['workDate'] ?? '---'}',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                              ),
                            ],
                          ),
                        ),

                        // Cột hiển thị giá tiền bên phải thẻ
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              priceText,
                              style: const TextStyle(color: Color(0xFF1BA39C), fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 5),
                            const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}