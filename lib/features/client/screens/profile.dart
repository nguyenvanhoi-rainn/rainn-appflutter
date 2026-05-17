import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ClientProfileScreen extends StatelessWidget {
  const ClientProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Nền xám nhạt cao cấp
      appBar: AppBar(
        title: const Text(
          'Hồ sơ cá nhân',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1BA39C), // Màu xanh thương hiệu RAINN
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => context.push('/profile-edit'),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());

          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          final double balance = double.tryParse(userData?['balance'].toString() ?? '0') ?? 0; //

          return StreamBuilder<QuerySnapshot>(
            // Stream lắng nghe toàn bộ danh sách đơn hàng đã hoàn thành của user này để làm Dashboard thống kê
            stream: FirebaseFirestore.instance
                .collection('jobs')
                .where('clientId', isEqualTo: uid)
                .where('status', isEqualTo: 'completed') //
                .snapshots(),
            builder: (context, jobSnapshot) {
              final jobs = jobSnapshot.data?.docs ?? [];
              final int totalJobs = jobs.length;

              // Tính tổng chi tiêu thực tế từ các đơn đã thanh toán
              double totalSpent = 0;
              for (var doc in jobs) {
                final data = doc.data() as Map<String, dynamic>;
                totalSpent += double.tryParse(data['price'].toString()) ?? 0; //
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // --- 1. KHỐI THÔNG TIN CHÍNH (AVATAR & NAME) ---
                    _buildHeaderCard(userData),
                    const SizedBox(height: 16),

                    // --- 2. BẢNG THỐNG KÊ CHI TIÊU & ĐƠN ĐÃ ĐẶT (USER DASHBOARD) ---
                    _buildDashboardRow(totalJobs, totalSpent),
                    const SizedBox(height: 16),

                    // --- 3. KHỐI HIỂN THỊ SỐ DƯ VÍ & NẠP TIỀN NHANH ---
                    _buildWalletCard(context, balance),
                    const SizedBox(height: 20),

                    // --- 4. CÁC TIỆN ÍCH MỞ RỘNG (TIỆN ÍCH CỦA TÔI) ---
                    _buildSectionTitle('Tiện ích của tôi'),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Colors.white,
                      elevation: 0,
                      child: Column(
                        children: [
                          _buildMenuTile(Icons.location_on_outlined, 'Địa chỉ đã lưu', () {
                            _showFeatureUnderDevelopment(context, 'Quản lý địa chỉ');
                          }),
                          const Divider(height: 1, indent: 50),
                          _buildMenuTile(Icons.star_border_rounded, 'Thợ yêu thích', () {
                            _showFeatureUnderDevelopment(context, 'Danh sách thợ ruột');
                          }),
                          const Divider(height: 1, indent: 50),
                          _buildMenuTile(Icons.history_outlined, 'Lịch sử giao dịch ví', () { //
                            _showFeatureUnderDevelopment(context, 'Tra cứu dòng tiền');
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- 5. HỖ TRỢ & HỆ THỐNG ---
                    _buildSectionTitle('Hỗ trợ & Bảo mật'),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Colors.white,
                      elevation: 0,
                      child: Column(
                        children: [
                          _buildMenuTile(Icons.headset_mic_outlined, 'Tổng đài hỗ trợ RAINN', () {
                            _handleCallHotline(context);
                          }),
                          const Divider(height: 1, indent: 50),
                          _buildMenuTile(Icons.lock_outline_rounded, 'Thay đổi mật khẩu', () {
                            _showFeatureUnderDevelopment(context, 'Đổi mật khẩu');
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),

                    // --- 6. NÚT ĐĂNG XUẤT AN TOÀN ---
                    ElevatedButton.icon(
                      onPressed: () => _handleLogout(context),
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text('ĐĂNG XUẤT TÀI KHOẢN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // --- COPPYRIGHT INFO ---
                    const Text(
                      'RAINN SERVICES\nPhiên bản 1.0.0',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.5),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Khối Card đầu trang hiển thị Avatar tên tuổi
  Widget _buildHeaderCard(Map<String, dynamic>? userData) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 35,
            backgroundColor: Color(0xFFF0F9F8),
            child: Icon(Icons.person, size: 40, color: Color(0xFF1BA39C)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userData?['fullName'] ?? 'Khách hàng RAINN',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                ),
                const SizedBox(height: 4),
                Text(
                  userData?['phone'] ?? 'Chưa cập nhật số điện thoại',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Khối Dashboard hiển thị thống kê đơn hàng và chi tiêu
  Widget _buildDashboardRow(int totalJobs, double totalSpent) {
    final currencyFormat = NumberFormat("#,###", "vi_VN");
    return Row(
      children: [
        Expanded(
          child: _buildStatItem('Đơn hoàn thành', '$totalJobs đơn', Icons.task_alt_rounded, Colors.green),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem('Tổng chi tiêu', '${currencyFormat.format(totalSpent)}đ', Icons.analytics_outlined, const Color(0xFF1BA39C)), //
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Khối hiện Ví tiền của Khách ngay trên Profile
  Widget _buildWalletCard(BuildContext context, double balance) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1BA39C), Color(0xFF168A84)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ví tiền của tôi', style: TextStyle(color: Color(0xDEFFFFFF), fontSize: 13)),
              const SizedBox(height: 6),
              Text('${NumberFormat("#,###", "vi_VN").format(balance)}đ', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)), //
            ],
          ),
          ElevatedButton(
            onPressed: () {
              // Vì Hội đã gộp Payment thành 1 tab trong MainWrapper nên chúng ta chỉ cần chuyển tab (ở đây là nhảy đến vị trí số 3)
              // Hoặc nếu muốn điều hướng trang độc lập Hội gọi: context.push('/payment');
              _showSnackBar(context, "Mời Hội chuyển qua Tab Ví tiền trên thanh BottomNav để nạp MoMo nhé!");
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('NẠP TIỀN', style: TextStyle(color: Color(0xFF1BA39C), fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 10),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(color: Color(0xFFF0F9F8), shape: BoxShape.circle),
        child: Icon(icon, color: const Color(0xFF1BA39C), size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF333333))),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }

  // --- LOGIC XỬ LÝ HÀM ĐĂNG XUẤT AN TOÀN ---
  Future<void> _handleLogout(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Hội có chắc chắn muốn đăng xuất khỏi ứng dụng không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Đăng xuất', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        context.go('/login'); // Ép điều hướng xoá sạch stack màn hình cũ
      }
    }
  }

  // --- HÀM GIẢ LẬP GỌI ĐIỆN HOTLINE ---
  void _handleCallHotline(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tổng đài RAINN'),
        content: const Text('Hệ thống sẽ kết nối cuộc gọi đến Hotline: 1900 8888.\nCước phí cuộc gọi là 1.000đ/phút.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ĐÓNG')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('GỌI NGAY', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1BA39C)))),
        ],
      ),
    );
  }

  // Hàm thông báo chung cho các nút mở rộng chức năng phụ
  void _showFeatureUnderDevelopment(BuildContext context, String title) {
    _showSnackBar(context, 'Tính năng "$title" đang được phát triển nâng cấp!');
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: const Color(0xFF1BA39C), duration: const Duration(seconds: 2)));
  }
}