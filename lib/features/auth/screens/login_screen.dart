import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/user_model.dart'; // Import UserModel để đồng bộ

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // Hằng số Admin đặc biệt
  final String adminEmail = "admin@gmail.com";
  final String adminPass = "admin123456";

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Vui lòng nhập đầy đủ email và mật khẩu.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Logic xử lý Admin đặc biệt
      if (email == adminEmail && password == adminPass) {
        UserCredential res;
        try {
          res = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
        } catch (e) {
          // Tạo tài khoản admin nếu chưa tồn tại (chỉ dùng cho lab/demo)
          res = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
        }

        // Đồng bộ dữ liệu Admin theo cấu trúc UserModel
        final adminUser = UserModel(
          uid: res.user!.uid,
          email: email,
          fullName: 'Administrator',
          role: 'admin',
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(res.user!.uid)
            .set(adminUser.toMap(), SetOptions(merge: true));

        if (mounted) context.go('/admin');
        return;
      }

      // 2. Đăng nhập User thông thường
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password
      );

      // Lấy dữ liệu từ Firestore và chuyển đổi sang UserModel
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        // ĐỒNG BỘ: Sử dụng UserModel.fromFirestore
        final user = UserModel.fromFirestore(userDoc);

        // Giả sử status được lưu trong doc dữ liệu gốc (nếu bạn có trường status)
        final data = userDoc.data() as Map<String, dynamic>;
        if (data['status'] == 'locked') {
          _showError("Tài khoản của bạn hiện đang bị khóa.");
          await FirebaseAuth.instance.signOut();
          return;
        }

        // 3. Điều hướng theo Role từ Model
        if (mounted) {
          switch (user.role) {
            case 'admin':
              context.go('/admin');
              break;
            case 'worker':
              context.go('/worker');
              break;
            default: // client
              context.go('/');
          }
        }
      } else {
        _showError("Dữ liệu người dùng không tồn tại.");
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _showError("Email này chưa được đăng ký.");
      } else if (e.code == 'wrong-password') {
        _showError("Mật khẩu không chính xác.");
      } else {
        _showError("Lỗi đăng nhập: ${e.message}");
      }
    } catch (e) {
      _showError("Đã xảy ra lỗi không xác định.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo hoặc Tên App với Style mượt hơn
              const Icon(Icons.bolt, size: 80, color: Color(0xFF1BA39C)),
              const Text(
                "RAINN",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1BA39C),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 40),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Mật khẩu",
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1BA39C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "ĐĂNG NHẬP",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              TextButton(
                onPressed: () => context.push('/register'),
                child: const Text(
                  "Chưa có tài khoản? Đăng ký ngay",
                  style: TextStyle(color: Color(0xFF1BA39C), fontWeight: FontWeight.w500),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}