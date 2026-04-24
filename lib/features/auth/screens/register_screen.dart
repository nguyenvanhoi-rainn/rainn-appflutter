import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _currentStep = 1; // Quản lý step 1/2 tương tự bản RN
  String? _selectedRole; // 'client' hoặc 'worker'

  // Controllers cho các trường thông tin
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  // Widget chọn vai trò (Bước khởi đầu)
  Widget _buildRoleChoice() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Bạn là ai?", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1BA39C))),
        const SizedBox(height: 30),
        _roleCard("Khách hàng", Icons.people, "client"),
        _roleCard("Người làm việc (Worker)", Icons.engineering, "worker"),
      ],
    );
  }

  Widget _roleCard(String title, IconData icon, String role) {
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, size: 50, color: const Color(0xFF1BA39C)),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // Hàm hoàn tất đăng ký
  Future<void> _completeRegistration() async {
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
      );

      final userData = {
        'uid': userCredential.user!.uid,
        'email': _emailController.text.trim(),
        'fullName': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': _selectedRole,
        'createdAt': DateTime.now().toIso8601String(),
      };

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set(userData);

      if (mounted) {
        context.go(_selectedRole == 'client' ? '/' : '/worker');  }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedRole == null) return Scaffold(body: Center(child: _buildRoleChoice()));

    return Scaffold(
      appBar: AppBar(
        title: Text("Đăng ký ${_selectedRole == 'client' ? 'Khách' : 'Worker'} ($_currentStep/2)"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _currentStep == 1 ? setState(() => _selectedRole = null) : setState(() => _currentStep = 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _currentStep == 1 ? _buildStep1() : _buildStep2(),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      children: [
        TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email *")),
        TextField(controller: _passController, obscureText: true, decoration: const InputDecoration(labelText: "Mật khẩu *")),
        const SizedBox(height: 20),
        ElevatedButton(
            onPressed: () => setState(() => _currentStep = 2),
            child: const Text("TIẾP THEO")
        )
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        TextField(controller: _fullNameController, decoration: const InputDecoration(labelText: "Họ và tên *")),
        TextField(controller: _phoneController, decoration: const InputDecoration(labelText: "Số điện thoại *")),
        const SizedBox(height: 20),
        ElevatedButton(
            onPressed: _completeRegistration,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1BA39C)),
            child: const Text("HOÀN TẤT ĐĂNG KÝ", style: TextStyle(color: Colors.white))
        )
      ],
    );
  }
}