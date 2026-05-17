import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class WorkerProfileScreen extends StatelessWidget {
  const WorkerProfileScreen({super.key});

  // ✅ Hàm xử lý Đăng xuất an toàn kèm Dialog xác nhận chuẩn React Native
  Future<void> _handleLogout(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut(); //
      if (context.mounted) {
        context.go('/login'); // Ép xoá lịch sử stack điều hướng
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white, // Nền trắng thanh lịch
      appBar: AppBar(
        title: const Text(
          'Hồ sơ cá nhân',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF333333)),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF5F5F5), height: 1), // Đường line dưới Header
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(), //
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());

          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          final bool isVerified = userData?['workerInfo']?['isVerified'] == true; //

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // --- 1. KHỐI THÔNG TIN THỢ (PROFILE INFO HEADER) ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  color: const Color(0xFFF9FAFB), // Nền xám nhạt cao cấp
                  child: Column(
                    children: [
                      // Avatar dạng hình tròn kèm tích xanh xác minh lồng nhau
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: userData?['profileImage'] != null
                                  ? NetworkImage(userData!['profileImage'])
                                  : const NetworkImage('https://cdn-icons-png.flaticon.com/512/3135/3135715.png'), //
                            ),
                          ),
                          if (isVerified) // Hiện tích xanh khi thợ đã được Admin duyệt hồ sơ
                            const Positioned(
                              bottom: 2,
                              right: 2,
                              child: CircleAvatar(
                                radius: 13,
                                backgroundColor: Colors.white,
                                child: Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 24), //
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        userData?['fullName'] ?? 'Thợ sửa chữa', //
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                      ),

                      // Khối hiển thị Sao và Đánh giá Realtime đổ từ collection 'reviews'
                      const SizedBox(height: 8),
                      _buildRealtimeRatingRow(uid),

                      const SizedBox(height: 6),
                      Text(userData?['email'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 14)), //

                      // --- 💡 Ý TƯỞNG MỚI ĐẮT GIÁ: TRẠNG THÁI HOẠT ĐỘNG THỰC TẾ ---
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: (userData?['isOnline'] == true) ? const Color(0xFFE0F2F1) : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          (userData?['isOnline'] == true) ? "● Đang trực tuyến (Sẵn sàng nhận việc)" : "○ Ngoại tuyến (Đang nghỉ)",
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: (userData?['isOnline'] == true) ? const Color(0xFF1BA39C) : Colors.grey.shade600
                          ),
                        ),
                      ),

                      // --- 2. HỘP KỸ NĂNG CHUYÊN MÔN CHỐNG DÍNH CHÙM ---
                      const SizedBox(height: 15),
                      _buildSkillContainer(userData),
                    ],
                  ),
                ),

                // --- 3. KHỐI QUAN LÝ TÀI KHOẢN (MENU ITEMS) ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'QUẢN LÝ TÀI KHOẢN', //
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFBBBBBB), letterSpacing: 1),
                      ),
                      const SizedBox(height: 15),

                      _buildMenuTile(
                        icon: Icons.create_outlined, //
                        iconBgColor: const Color(0xFFE0F2F1), //
                        iconColor: const Color(0xFF1BA39C), //
                        title: 'Chỉnh sửa hồ sơ cá nhân', //
                        onTap: () => context.push('/worker/profile-edit'), //
                      ),

                      _buildRealtimeReviewMenuTile(uid), // Menu phản hồi có kẹp Badge đếm số lượng tin mới

                      const SizedBox(height: 10),
                      // Khối Đăng xuất bo góc phong cách mới
                      Card(
                        elevation: 0,
                        color: const Color(0xFFFFEBEE), //
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: const Icon(Icons.logout_rounded, color: Color(0xFFF44336)), //
                          title: const Text('Đăng xuất tài khoản', style: TextStyle(color: Color(0xFFF44336), fontWeight: FontWeight.bold)), //
                          trailing: const Icon(Icons.chevron_right, color: Color(0xFFF44336)),
                          onTap: () => _handleLogout(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget tính toán số sao trung bình thời gian thực giống React Native
  Widget _buildRealtimeRatingRow(String? workerId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('reviews').where('workerId', isEqualTo: workerId).snapshots(), //
      builder: (context, snapshot) {
        double avgRating = 5.0; // Mặc định là 5.0
        int totalReviews = snapshot.data?.size ?? 0; //

        if (snapshot.hasData && totalReviews > 0) {
          double total = snapshot.data!.docs.fold(0.0, (acc, d) => acc + (d.data() as Map<String, dynamic>)['rating']); //
          avgRating = total / totalReviews; //
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star, color: Color(0xFFFFD700), size: 18), //
            Text(
              ' ${totalReviews > 0 ? avgRating.toStringAsFixed(1) : "5.0"} ', //
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
            ),
            Text('($totalReviews đánh giá)', style: const TextStyle(color: Colors.grey, fontSize: 13)), //
          ],
        );
      },
    );
  }

  // Widget render cụm kỹ năng chuyên môn chuẩn UI bo góc mượt mà
  Widget _buildSkillContainer(Map<String, dynamic>? userData) {
    final skillData = userData?['workerInfo']?['mainSkill']; //
    List<String> skills = [];

    if (skillData != null) {
      if (skillData is List) {
        skills = List<String>.from(skillData); //
      } else if (skillData is String && skillData.isNotEmpty) {
        skills = [skillData]; //
      }
    }

    if (skills.isEmpty) {
      return const Text('Chưa cập nhật chuyên môn', style: TextStyle(color: Colors.grey, fontSize: 12)); //
    }

    return Wrap(
      spacing: 8, // Khoảng cách ngang giữa các Skill
      runSpacing: 8, // Khoảng cách dọc khi xuống hàng
      alignment: WrapAlignment.center,
      children: skills.map((skill) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), //
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2F1), //
          borderRadius: BorderRadius.circular(15), //
          border: Border.all(color: const Color(0xFFB2DFDB)), //
        ),
        child: Text(
          skill,
          style: const TextStyle(color: Color(0xFF1BA39C), fontWeight: FontWeight.bold, fontSize: 12), //
        ),
      )).toList(),
    );
  }

  // Widget lắng nghe đếm số lượt phản hồi để hiện số thông báo nhỏ dạng Badge màu đỏ rực
  Widget _buildRealtimeReviewMenuTile(String? workerId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('reviews').where('workerId', isEqualTo: workerId).snapshots(), //
      builder: (context, snapshot) {
        int totalReviews = snapshot.data?.size ?? 0; //

        return _buildMenuTile(
          icon: Icons.chat_bubble_outline, //
          iconBgColor: const Color(0xFFFFF9E6), //
          iconColor: const Color(0xFFFFB300), //
          title: 'Phản hồi từ khách hàng', //
          badgeCount: totalReviews > 0 ? totalReviews : null, //
          onTap: () => context.push('/worker/reviews'), //
        );
      },
    );
  }

  // Khung sườn tổng quát thiết kế các ô điều hướng bo viền tròn tinh tế
  Widget _buildMenuTile({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    int? badgeCount,
  }) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF5F5F5))), //
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(12)), //
          child: Icon(icon, color: iconColor, size: 20), //
        ),
        title: Text(title, style: const TextStyle(fontSize: 16, color: Color(0xFF333333))), //
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badgeCount != null) // Hiển thị vòng tròn đỏ đếm số phản hồi mới
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFFF5252), borderRadius: BorderRadius.circular(10)), //
                child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)), //
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 18), //
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}