import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  bool _isOnline = false;
  bool _isLoadingStatus = true;

  // Số liệu thật (Stats) tích hợp giống file React Native
  int _completedCount = 0;
  double _income = 0;
  final double _rating = 5.0; // Có thể liên kết với bảng reviews sau

  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadWorkerStatusAndStats();
  }

  // Lắng nghe dữ liệu trạng thái Trực tuyến & Tính toán doanh thu thực tế
  void _loadWorkerStatusAndStats() {
    if (_currentUserId.isEmpty) return;

    // 1. Lắng nghe trạng thái Online/Offline thực tế từ Firestore
    FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .snapshots()
        .listen((userSnap) {
      if (userSnap.exists && mounted) {
        setState(() {
          _isOnline = userSnap.data()?['isOnline'] ?? false;
          _isLoadingStatus = false;
        });
      }
    });

    // 2. Lắng nghe collection 'jobs' để đếm đơn hoàn thành và tổng thu nhập thật
    FirebaseFirestore.instance
        .collection('jobs')
        .where('workerId', isEqualTo: _currentUserId)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .listen((jobSnap) {
      double totalIncome = 0;
      for (var doc in jobSnap.docs) {
        final priceVal = doc.data()['price'];
        if (priceVal != null && priceVal != "Thương lượng") {
          totalIncome += double.tryParse(priceVal.toString().replaceAll(',', '')) ?? 0;
        }
      }
      if (mounted) {
        setState(() {
          _completedCount = jobSnap.size;
          _income = totalIncome;
        });
      }
    });
  }

  // Hàm cập nhật trạng thái Bật/Tắt hoạt động
  Future<void> _toggleOnlineStatus(bool value) async {
    setState(() => _isOnline = value);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .update({'isOnline': value});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cập nhật trạng thái thất bại")),
      );
    }
  }

  // Định dạng hiển thị tiền thu nhập gọn gàng (VD: 1.5M hoặc 500K)
  String _formatIncome(double income) {
    if (income >= 1000000) {
      return "${(income / 1000000).toStringAsFixed(1)}M";
    } else if (income >= 1000) {
      return "${(income / 1000).toStringAsFixed(0)}K";
    }
    return "${income.toStringAsFixed(0)}đ";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- BANNER TOP XANH RAINN + THỐNG KÊ REALTIME ---
            _buildTopBanner(),

            // --- THANH TÌM KIẾM NHANH ---
            _buildSearchBar(),

            // --- KHỐI CHUYÊN MÔN NHẬN VIỆC (CATEGORIES THẬT) ---
            _buildSpecializationGrid(),

            // --- KHỐI DANH SÁCH YÊU CẦU MỚI QUANH ĐÂY ---
            _buildRecentJobsSection(),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBanner() {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 35),
      decoration: const BoxDecoration(
        color: Color(0xFF1BA39C),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hội Worker",
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Chào mừng bạn quay trở lại!",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
              // Switch Bật/Tắt Trạng thái giống React
              Column(
                children: [
                  Text(
                    _isOnline ? "Đang nhận việc" : "Đang nghỉ",
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
// Thay thế đoạn Switch cũ trong _buildTopBanner bằng đoạn này:
                  _isLoadingStatus
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : Switch(
                    value: _isOnline,
                    onChanged: (bool value) { // Sửa từ onValueChange thành onChanged
                      _toggleOnlineStatus(value);
                    },
                    activeColor: Colors.white, // Màu của nút tròn khi BẬT
                    activeTrackColor: Colors.white24, // Màu của thanh nền khi BẬT
                    inactiveThumbColor: Colors.grey[300], // Màu của nút tròn khi TẮT
                    inactiveTrackColor: Colors.black26, // Màu của thanh nền khi TẮT
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Lưới thông số dạng Card ngang màu trong suốt
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem("$_completedCount", "Đơn xong"),
                _buildVerticalDivider(),
                _buildStatItem("$_rating ⭐", "Đánh giá"),
                _buildVerticalDivider(),
                _buildStatItem(_formatIncome(_income), "Thu nhập"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(width: 1, height: 30, color: Colors.white.withOpacity(0.3));
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.search, color: Colors.grey),
            SizedBox(width: 10),
            Expanded(
              child: TextField(
                decoration: InputDecoration(hintText: "Tìm việc làm...", border: InputBorder.none, hintStyle: TextStyle(color: Colors.grey)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecializationGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Chuyên môn nhận việc", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          const SizedBox(height: 15),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('categories').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();
              final categories = snapshot.data!.docs;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.85,
                ),
                itemCount: categories.length > 7 ? 7 : categories.length, // Lấy tối đa 7 danh mục như bản React
                itemBuilder: (context, index) {
                  final item = categories[index].data() as Map<String, dynamic>;
                  return GestureDetector(
                    onTap: () => context.push('/worker/job-market/${categories[index].id}/${Uri.encodeComponent(item['name'])}'),
                    child: Column(
                      children: [
                        Container(
                          width: 55,
                          height: 55,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1BA39C).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.engineering, color: Color(0xFF1BA39C), size: 24),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item['name'] ?? '',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF555555)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentJobsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Yêu cầu mới quanh đây", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          const SizedBox(height: 15),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('jobs')
                .where('status', isEqualTo: 'pending')
                .orderBy('createdAt', descending: true)
                .limit(5) // Lấy đúng 5 đơn mới nhất toàn hệ thống
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text("Đã xảy ra lỗi khi đồng bộ Firestore."));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final recentJobs = snapshot.data!.docs;
              if (recentJobs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text("Đang chờ yêu cầu từ khách hàng...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentJobs.length,
                itemBuilder: (context, index) {
                  final job = recentJobs[index].data() as Map<String, dynamic>;
                  final String priceText = job['price'] == "Thương lượng"
                      ? "Deal"
                      : "${NumberFormat("#,###").format(int.tryParse(job['price'].toString()) ?? 0)}đ";

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(color: Color(0xFFF8F9FA), shape: BoxShape.circle),
                        child: const Icon(Icons.notifications_active_outlined, color: Color(0xFF1BA39C), size: 20),
                      ),
                      title: Text(
                        job['subService'] ?? job['groupService'] ?? 'Dịch vụ sửa chữa',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          "📍 ${job['address'] ?? 'Thủ Dầu Một'}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            priceText,
                            style: const TextStyle(color: Color(0xFF1BA39C), fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(width: 5),
                          const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                        ],
                      ),
                      onTap: () => context.push('/worker/job/${recentJobs[index].id}'),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}