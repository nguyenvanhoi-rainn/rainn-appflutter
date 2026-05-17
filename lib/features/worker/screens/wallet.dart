import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  // Controllers cho Modal Rút tiền
  final _amountController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNoController = TextEditingController();
  final _ownerController = TextEditingController();

  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  double _balance = 0; // Số dư tài khoản thực tế
  bool _isSubmitting = false; // Trạng thái loading khi nhấn rút tiền

  // Trạng thái bộ lọc lịch sử giao dịch (Tính năng gợi ý mới)
  String _activeFilter = 'all'; // 'all', 'income', 'withdraw'

  @override
  void initState() {
    super.initState();
    _listenToWalletData();
  }

  // Lắng nghe Real-time Số dư tài khoản từ collection 'users'
  void _listenToWalletData() {
    if (_currentUserId.isEmpty) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        setState(() {
          _balance = double.tryParse(snapshot.data() != null ? (snapshot.data() as Map<String, dynamic>)['balance'].toString() : '0') ?? 0;
        });
      }
    });
  }

  // ✅ HÀM GỬI YÊU CẦU RÚT TIỀN LÊN FIREBASE (Đồng bộ 100% bản React)
  Future<void> _submitWithdrawRequest() async {
    final int? amount = int.tryParse(_amountController.text.trim());

    if (amount == null || amount < 50000) { //
      _showSnackBar("Số tiền rút tối thiểu là 50,000đ", isError: true);
      return;
    }
    if (amount > _balance) { //
      _showSnackBar("Số dư tài khoản không đủ để thực hiện.", isError: true);
      return;
    }
    if (_bankNameController.text.isEmpty || _accountNoController.text.isEmpty || _ownerController.text.isEmpty) { //
      _showSnackBar("Vui lòng nhập đầy đủ thông tin ngân hàng.", isError: true);
      return;
    }

    setState(() => _isSubmitting = true); //

    try {
      final batch = FirebaseFirestore.instance.batch();

      // 1. Tạo bản ghi yêu cầu rút tiền vào collection 'withdrawals'
      final withdrawRef = FirebaseFirestore.instance.collection('withdrawals').doc();
      batch.set(withdrawRef, {
        'userId': _currentUserId, //
        'userName': FirebaseAuth.instance.currentUser?.displayName ?? "Worker", //
        'amount': amount, //
        'bankName': _bankNameController.text.trim(), //
        'accountNo': _accountNoController.text.trim(), //
        'accountOwner': _ownerController.text.trim().toUpperCase(), //
        'status': 'pending', // Chờ admin duyệt
        'createdAt': FieldValue.serverTimestamp(), //
      });

      // 2. Tạo song song lịch sử trừ tiền hiển thị ngay tại ví
      final transactionRef = FirebaseFirestore.instance.collection('transactions').doc();
      batch.set(transactionRef, {
        'userId': _currentUserId,
        'jobTitle': 'Rút tiền về t/k ${_bankNameController.text.trim()}',
        'amount': amount,
        'type': 'withdraw', // Loại trừ tiền
        'status': 'pending', // Đang xử lý
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Trừ số dư ví ngầm tạm thời của Thợ
      final userRef = FirebaseFirestore.instance.collection('users').doc(_currentUserId);
      batch.update(userRef, {'balance': _balance - amount});

      await batch.commit();

      if (mounted) {
        Navigator.pop(context); // Đóng BottomSheet
        _showSnackBar("Yêu cầu rút tiền đã được gửi! Admin sẽ duyệt trong 24h.");
        _clearFormFields();
      }
    } catch (e) {
      _showSnackBar("Đã xảy ra lỗi hệ thống, vui lòng thử lại.", isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false); //
    }
  }

  void _clearFormFields() {
    _amountController.clear();
    _bankNameController.clear();
    _accountNoController.clear();
    _ownerController.clear();
  }

  void _showSnackBar(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: isError ? Colors.redAccent : const Color(0xFF1BA39C)),
    );
  }

  // ✅ HIỂN THỊ MODAL BOTTOM SHEET RÚT TIỀN (Giống Modal bản React)
  void _openWithdrawBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))), //
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom, // Đẩy giao diện khi hiện bàn phím
              left: 25, right: 25, top: 25
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Yêu cầu rút tiền', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF333333))), //
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)), //
                  ],
                ),
                const SizedBox(height: 10),
                _buildInputField(_amountController, 'Số tiền muốn rút (VNĐ)', 'Ví dụ: 100000', TextInputType.number), //
                _buildInputField(_bankNameController, 'Ngân hàng', 'Ví dụ: Vietcombank, MB Bank...', TextInputType.text), //
                _buildInputField(_accountNoController, 'Số tài khoản', 'Nhập số tài khoản ngân hàng', TextInputType.number), //
                _buildInputField(_ownerController, 'Tên chủ tài khoản', 'NGUYEN VAN A', TextInputType.text, capitalize: true), //

                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : () async {
                      setModalState(() => _isSubmitting = true);
                      await _submitWithdrawRequest();
                      setModalState(() => _isSubmitting = false);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1BA39C),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)) //
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white) //
                        : const Text('XÁC NHẬN RÚT TIỀN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), //
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Xây dựng Query Firestore tùy biến theo bộ lọc được chọn (Gợi ý tính năng mới)
    Query txQuery = FirebaseFirestore.instance.collection('transactions').where('userId', isEqualTo: _currentUserId).orderBy('createdAt', descending: true);
    if (_activeFilter != 'all') {
      txQuery = txQuery.where('type', isEqualTo: _activeFilter);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Ví tiền của tôi', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1BA39C))), //
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          // --- BẢNG SỐ DƯ HIỆN TẠI (ĐỒNG BỘ STYLE BANNER RÚT TIỀN) ---
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: const Color(0xFF1BA39C),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [BoxShadow(color: const Color(0xFF1BA39C).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))], //
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Số dư hiện tại', style: const TextStyle(color: Colors.white70, fontSize: 14)), //
                const SizedBox(height: 8),
                Text('${NumberFormat("#,###").format(_balance)}đ', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)), //
                const SizedBox(height: 20),
                InkWell(
                  onTap: _openWithdrawBottomSheet, //
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: const Color(0xFF333333), borderRadius: BorderRadius.circular(15)), //
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Rút tiền về thẻ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), //
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),

          // --- ✨ TÍNH NĂNG MỚI: BỘ LỌC TABS LỊCH SỬ THÔNG MINH ---
          _buildFilterTabs(),

          // --- DANH SÁCH LỊCH SỬ GIAO DỊCH REAL-TIME (CỘNG VÀ TRỪ TIỀN) ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: txQuery.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final txList = snapshot.data!.docs;
                if (txList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        const Text('Bạn chưa có giao dịch nào.', style: TextStyle(color: Colors.grey)), //
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: txList.length,
                  itemBuilder: (context, index) {
                    final tx = txList[index].data() as Map<String, dynamic>;
                    final bool isIncome = tx['type'] == 'income'; //
                    final int amount = int.tryParse(tx['amount'].toString()) ?? 0;
                    final Timestamp? createdAt = tx['createdAt'];

                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF9F9F9)))), //
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: isIncome ? const Color(0xFFE0F2F1) : const Color(0xFFFFEBEE), //
                            radius: 22,
                            child: Icon(
                              isIncome ? Icons.arrow_downward : Icons.arrow_upward, //
                              color: isIncome ? const Color(0xFF1BA39C) : const Color(0xFFFF3B30), //
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tx['jobTitle'] ?? 'Giao dịch', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF333333))), //
                                const SizedBox(height: 4),
                                Text(
                                  createdAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(createdAt.toDate()) : 'Đang xử lý...', //
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${isIncome ? "+" : "-"}${NumberFormat("#,###").format(amount)}đ', //
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isIncome ? const Color(0xFF1BA39C) : const Color(0xFFFF3B30)), //
                              ),
                              if (tx['status'] == 'pending')
                                const Text('Chờ duyệt', style: TextStyle(color: Colors.orange, fontSize: 10, fontStyle: FontStyle.italic)),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  // Khối giao diện tạo các ô nhập thông tin bo tròn
  Widget _buildInputField(TextEditingController controller, String label, String hint, TextInputType inputType, {bool capitalize = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF666666), fontWeight: FontWeight.w500)), //
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: inputType,
            textCapitalization: capitalize ? TextCapitalization.characters : TextCapitalization.none, //
            decoration: InputDecoration(
              hintText: hint,
              fillColor: const Color(0xFFF5F5F5),
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), //
              contentPadding: const EdgeInsets.all(15),
            ),
          ),
        ],
      ),
    );
  }

  // Giao diện thanh chọn bộ lọc ngang (Tính năng mở rộng mới gợi ý)
  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          _filterChip('all', 'Tất cả'),
          const SizedBox(width: 8),
          _filterChip('income', 'Tiền cộng'),
          const SizedBox(width: 8),
          _filterChip('withdraw', 'Tiền rút'),
        ],
      ),
    );
  }

  Widget _filterChip(String filterKey, String label) {
    final bool isSelected = _activeFilter == filterKey;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = filterKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1BA39C) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black54, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }
}