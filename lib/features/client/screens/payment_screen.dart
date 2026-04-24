import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class PaymentScreen extends StatefulWidget {
  final String bookingId;
  final double amount;

  const PaymentScreen({super.key, required this.bookingId, required this.amount});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'cash'; // Mặc định là tiền mặt
  bool _isProcessing = false;

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      // 1. Cập nhật trạng thái booking thành 'paid'
      await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).update({
        'paymentStatus': 'paid',
        'paymentMethod': _selectedMethod,
        'paidAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi thanh toán: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text('Thanh toán thành công! Cảm ơn bạn đã sử dụng dịch vụ RAINN.', textAlign: TextAlign.center),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => context.go('/'), // Quay về trang chủ
              child: const Text('XÁC NHẬN'),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tổng số tiền cần thanh toán:', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text('${widget.amount.toStringAsFixed(0)} VNĐ',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1BA39C))),
            const SizedBox(height: 30),
            const Text('Chọn phương thức thanh toán:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildPaymentOption('cash', 'Tiền mặt', Icons.money),
            _buildPaymentOption('momo', 'Ví MoMo', Icons.wallet),
            _buildPaymentOption('bank', 'Chuyển khoản ngân hàng', Icons.account_balance),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1BA39C)),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('XÁC NHẬN THANH TOÁN', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String value, String label, IconData icon) {
    return RadioListTile(
      value: value,
      groupValue: _selectedMethod,
      onChanged: (val) => setState(() => _selectedMethod = val.toString()),
      title: Text(label),
      secondary: Icon(icon, color: const Color(0xFF1BA39C)),
      activeColor: const Color(0xFF1BA39C),
    );
  }
}