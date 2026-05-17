import 'dart:convert';
import 'package:http/http.dart' as http;

class MomoService {
  // Đường dẫn Ngrok chạy Server Backend Node.js của Hội
  static const String apiUrl = "https://anew-android-batboy.ngrok-free.dev";

  // Hàm gọi lên Backend để khởi tạo giao dịch lấy link WebView
  static Future<Map<String, dynamic>?> createMoMoPayment({
    required int amount,
    required String orderId,
    required String userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/create-momo-payment'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "amount": amount,
          "orderId": orderId,
          "userId": userId,
        }), //
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>; // Trả về data chứa payUrl
      } else {
        print("❌ Lỗi Server Backend: ${response.body}");
        return null;
      }
    } catch (error) {
      print("❌ Lỗi kết nối API Backend MoMo: $error"); //
      return null;
    }
  }
}