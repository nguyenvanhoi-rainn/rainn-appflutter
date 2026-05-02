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
  int _currentStep = 1;
  String? _selectedRole;
  bool _isLoading = false;

  // Controllers
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cccdController = TextEditingController();
  final _skillController = TextEditingController(); // Cho Worker

  // Bước 1: Tài khoản
  Widget _buildStep1() {
    return Column(
      children: [
        const Text("Thông tin đăng nhập", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1BA39C))),
        const SizedBox(height: 15),
        TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email *", border: OutlineInputBorder())),
        const SizedBox(height: 15),
        TextField(controller: _passController, obscureText: true, decoration: const InputDecoration(labelText: "Mật khẩu *", border: OutlineInputBorder())),
        const SizedBox(height: 15),
        TextField(controller: _confirmPassController, obscureText: true, decoration: const InputDecoration(labelText: "Nhập lại mật khẩu *", border: OutlineInputBorder())),
        const SizedBox(height: 25),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              if (_passController.text != _confirmPassController.text) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mật khẩu không khớp!")));
                return;
              }
              setState(() => _currentStep = 2);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1BA39C)),
            child: const Text("TIẾP THEO", style: TextStyle(color: Colors.white)),
          ),
        )
      ],
    );
  }

  // Bước 2: Thông tin cá nhân & Worker Info
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Thông tin cá nhân", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1BA39C))),
        const SizedBox(height: 15),
        TextField(controller: _fullNameController, decoration: const InputDecoration(labelText: "Họ và tên thật *", border: OutlineInputBorder())),
        const SizedBox(height: 15),
        TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Số điện thoại *", border: OutlineInputBorder())),
        const SizedBox(height: 15),
        TextField(controller: _addressController, decoration: const InputDecoration(labelText: "Địa chỉ", border: OutlineInputBorder())),

        if (_selectedRole == 'worker') ...[
          const SizedBox(height: 25),
          const Text("Hồ sơ năng lực (Worker)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1BA39C))),
          const SizedBox(height: 15),
          TextField(controller: _cccdController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Số CCCD (12 số) *", border: OutlineInputBorder())),
          const SizedBox(height: 15),
          TextField(controller: _skillController, decoration: const InputDecoration(labelText: "Chuyên môn chính (VD: Điện nước) *", border: OutlineInputBorder())),
        ],

        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _completeRegistration,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1BA39C)),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("HOÀN TẤT ĐĂNG KÝ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        )
      ],
    );
  }

  Future<void> _completeRegistration() async {
    setState(() => _isLoading = true);
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
      );

      final String uid = userCredential.user!.uid;
      final Map<String, dynamic> userData = {
        'uid': uid,
        'email': _emailController.text.trim(),
        'fullName': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'role': _selectedRole,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Đẩy đủ thông tin cho Admin duyệt thợ[cite: 9, 16]
      if (_selectedRole == 'worker') {
        userData['verifyStatus'] = 'pending';
        userData['workerInfo'] = {
          'cccd': _cccdController.text.trim(),
          'mainSkill': _skillController.text.trim(),
          'isVerified': false,
        };
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).set(userData);

      if (mounted) {
        context.go(_selectedRole == 'client' ? '/' : '/worker');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedRole == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Bạn là ai?", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1BA39C))),
                const SizedBox(height: 40),
                _roleCard("Khách hàng", Icons.people, "client"),
                const SizedBox(height: 20),
                _roleCard("Người làm việc (Worker)", Icons.engineering, "worker"),
                TextButton(onPressed: () => context.go('/login'), child: const Text("Đã có tài khoản? Đăng nhập"))
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Đăng ký ${_selectedRole == 'client' ? 'Khách' : 'Worker'} ($_currentStep/2)"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _currentStep == 1 ? setState(() => _selectedRole = null) : setState(() => _currentStep = 1),
        ),
      ),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: _currentStep == 1 ? _buildStep1() : _buildStep2()),
    );
  }

  Widget _roleCard(String title, IconData icon, String role) {
    return InkWell(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
        child: Column(children: [Icon(icon, size: 50, color: const Color(0xFF1BA39C)), const SizedBox(height: 10), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
      ),
    );
  }
}