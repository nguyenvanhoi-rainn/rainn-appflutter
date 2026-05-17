import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PaymentResultScreen extends StatelessWidget {
  final String resultCode;
  final String orderId;
  final String amount;

  const PaymentResultScreen({
    super.key,
    required this.resultCode,
    required this.orderId,
    required this.amount
  });

  @override
  Widget build(BuildContext context) {
    // resultCode == "0" là thành công
    final bool isSuccess = resultCode == "0";

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.cancel, //
                size: 100,
                color: isSuccess ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C), //
              ),
              const SizedBox(height: 15),
              Text(
                isSuccess ? "Nạp tiền thành công!" : "Giao dịch thất bại", //
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Text("Mã đơn: $orderId", style: const TextStyle(fontSize: 16, color: Colors.grey)), //
              Text("Số tiền: $amountđ", style: const TextStyle(fontSize: 16, color: Colors.grey)), //
              const SizedBox(height: 40),
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    context.go('/payment'); // Quay lại trang thanh toán
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1BA39C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), //
                  ),
                  child: const Text('Tiếp tục sử dụng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), //
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}