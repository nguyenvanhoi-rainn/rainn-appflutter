import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/services/momo_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _amountController = TextEditingController();
  final _commentController = TextEditingController();

  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  double _balance = 0;
  bool _isLoading = false;
  int _selectedRating = 5;
  Map<String, dynamic>? _selectedJob;

  @override
  void dispose() {
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleRechargeMomo() async {
    final int? amount = int.tryParse(_amountController.text.trim());
    if (amount == null || amount < 10000) {
      _showSnackBar("Nạp tối thiểu 10.000đ", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String orderId = "RECH_${DateTime.now().millisecondsSinceEpoch}";

      final res = await MomoService.createMoMoPayment(
        amount: amount,
        orderId: orderId,
        userId: _currentUserId,
      );

      if (res != null && res['payUrl'] != null) {
        final String payUrl = res['payUrl'];
        if (mounted) {
          _amountController.clear();
          _openMomoWebView(payUrl, orderId, amount);
        }
      } else {
        _showSnackBar("Không khởi tạo được giao dịch MoMo.", isError: true);
      }
    } catch (e) {
      _showSnackBar("Kết nối server thất bại.", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openMomoWebView(String url, String orderId, int amount) {
    final WebViewController controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onUrlChange: (UrlChange change) async {
            final String? changedUrl = change.url;
            if (changedUrl == null) return;

            if (changedUrl.contains("resultCode=0")) {
              if (mounted) {
                await FirebaseFirestore.instance.collection('users').doc(_currentUserId).update({
                  'balance': FieldValue.increment(amount)
                });

                if (mounted) {
                  context.pop();
                  context.push('/payment-result?resultCode=0&orderId=$orderId&amount=$amount');
                }
              }
            } else if (changedUrl.contains("resultCode=")) {
              if (mounted) {
                context.pop();
                context.push('/payment-result?resultCode=99&orderId=$orderId&amount=$amount');
              }
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(url));

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text(
              'Thanh toán MoMo',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: WebViewWidget(controller: controller),
        ),
      ),
    );
  }

  Future<void> _payWithWallet(Map<String, dynamic> order) async {
    final double jobPrice = double.tryParse(order['price'].toString()) ?? 0;

    if (_balance < jobPrice) {
      _showSnackBar("Số dư không đủ, vui lòng nạp thêm tiền vào ví.", isError: true);
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text('Thanh toán ${NumberFormat("#,###").format(jobPrice)}đ và kết thúc công việc chứ Hội?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xác nhận')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    final batch = FirebaseFirestore.instance.batch();

    try {
      final String workerId = order['workerId'] ?? '';
      final String chatId = _currentUserId.hashCode <= workerId.hashCode
          ? '${_currentUserId}_$workerId'
          : '${workerId}_$_currentUserId';

      batch.update(FirebaseFirestore.instance.collection('users').doc(_currentUserId), {'balance': FieldValue.increment(-jobPrice)});
      batch.update(FirebaseFirestore.instance.collection('users').doc(workerId), {'balance': FieldValue.increment(jobPrice)});
      batch.update(FirebaseFirestore.instance.collection('jobs').doc(order['id']), {'status': 'completed', 'paymentStatus': 'paid'});
      batch.delete(FirebaseFirestore.instance.collection('chats').doc(chatId));

      await batch.commit();

      setState(() {
        _selectedJob = order;
        _isLoading = false;
      });

      _showRatingDialog();

    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Thanh toán thất bại.", isError: true);
    }
  }

  Future<void> _submitRating() async {
    if (_selectedJob == null) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('reviews').add({
        'jobId': _selectedJob!['id'],
        'workerId': _selectedJob!['workerId'],
        'clientId': _currentUserId,
        'rating': _selectedRating,
        'comment': _commentController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        _showSnackBar("Cảm ơn bạn đã đánh giá dịch vụ!");
        setState(() {
          _commentController.clear();
          _selectedRating = 5;
          _selectedJob = null;
        });
      }
    } catch (e) {
      _showSnackBar("Không thể gửi nhận xét.", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, size: 50, color: Color(0xFFF1C40F)),
              const SizedBox(height: 10),
              const Text('Đánh giá thợ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  int starValue = index + 1;
                  return GestureDetector(
                    onTap: () => setDialogState(() => _selectedRating = starValue),
                    child: Icon(
                      starValue <= _selectedRating ? Icons.star : Icons.star_border,
                      size: 35, color: const Color(0xFFF1C40F),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Thợ làm việc thế nào Hội ơi?",
                  fillColor: const Color(0xFFF0F2F5),
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submitRating,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1BA39C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('GỬI NHẬN XÉT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Bỏ qua', style: TextStyle(color: Colors.grey)),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), backgroundColor: isError ? Colors.redAccent : const Color(0xFF1BA39C)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Ví & Thanh toán', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1BA39C))),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // --- CARD SỐ DƯ VÍ KHÁCH ---
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(color: const Color(0xFF1BA39C), borderRadius: BorderRadius.circular(25)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Số dư hiện tại', style: TextStyle(color: Color(0xE6FFFFFF), fontSize: 13)),
                    const SizedBox(height: 5),

                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(_currentUserId).snapshots(),
                      builder: (context, snap) {
                        final userData = snap.data?.data() as Map<String, dynamic>?;
                        double currentBal = double.tryParse(userData?['balance'].toString() ?? '0') ?? 0;
                        _balance = currentBal;
                        return Text('${NumberFormat("#,###").format(currentBal)}đ', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold));
                      },
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(15)),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                hintText: "Nhập số tiền nạp...",
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: Color(0x80FFFFFF)),
                              ),
                            ),
                          ),
                          const Text('VNĐ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  ],
                ),
              ),

              // --- NÚT NẠP TIỀN QUA MOMO ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton.icon(
                  onPressed: _handleRechargeMomo,
                  icon: const Icon(Icons.circle_notifications, color: Colors.white, size: 24),
                  label: const Text('NẠP QUA MOMO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA50064), minimumSize: const Size(double.infinity, 54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                ),
              ),

              // --- KHỐI TIÊU ĐỀ YÊU CẦU CẦN TRẢ TIỀN ---
              Padding(
                padding: const EdgeInsets.only(left: 25, right: 25, top: 25, bottom: 10),
                child: Row(
                  children: [
                    const Text('Yêu cầu cần trả tiền', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                    const SizedBox(width: 10),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('jobs').where('clientId', isEqualTo: _currentUserId).where('status', isEqualTo: 'waiting_payment').snapshots(),
                      builder: (context, snap) {
                        int pendingCount = snap.data?.size ?? 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFFF3B30), borderRadius: BorderRadius.circular(10)),
                          child: Text('$pendingCount', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        );
                      },
                    )
                  ],
                ),
              ),

              // --- DANH SÁCH ĐƠN CHỜ THANH TOÁN (REALTIME - KHÔNG CẦN INDEX) ---
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('jobs')
                      .where('clientId', isEqualTo: _currentUserId)
                      .where('status', isEqualTo: 'waiting_payment')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                    final List<DocumentSnapshot> jobDocs = snapshot.data!.docs;

                    if (jobDocs.isEmpty) {
                      return const Center(child: Text('Mọi thứ đã được thanh toán sạch sẽ!', style: TextStyle(color: Colors.grey)));
                    }

                    jobDocs.sort((a, b) {
                      final dataA = a.data() as Map<String, dynamic>;
                      final dataB = b.data() as Map<String, dynamic>;
                      final Timestamp? timeA = dataA['createdAt'] as Timestamp?;
                      final Timestamp? timeB = dataB['createdAt'] as Timestamp?;
                      return (timeB?.seconds ?? 0).compareTo(timeA?.seconds ?? 0);
                    });

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: jobDocs.length,
                      itemBuilder: (context, index) {
                        final order = jobDocs[index].data() as Map<String, dynamic>;
                        order['id'] = jobDocs[index].id;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(15),
                            title: Text(order['subService'] ?? order['groupService'] ?? 'Dịch vụ', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Thợ: ${order['workerName']} • Ngày: ${order['workDate']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${NumberFormat("#,###").format(int.tryParse(order['price'].toString()) ?? 0)}đ', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1BA39C), fontSize: 16)),
                                const Text('Bấm trả tiền', style: TextStyle(color: Color(0xFF007AFF), fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            onTap: () => _payWithWallet(order),
                          ),
                        );
                      },
                    );
                  },
                ),
              )
            ],
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator())
        ],
      ),
    );
  }
}