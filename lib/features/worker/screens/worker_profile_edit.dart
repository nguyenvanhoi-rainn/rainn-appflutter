import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkerProfileEdit extends StatefulWidget {
  const WorkerProfileEdit({super.key});

  @override
  State<WorkerProfileEdit> createState() => _WorkerProfileEditState();
}

class _WorkerProfileEditState extends State<WorkerProfileEdit> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _skillsController = TextEditingController(); // Cho thợ nhập kỹ năng cách nhau bởi dấu phẩy
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadWorkerData();
  }

  void _loadWorkerData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _nameController.text = data['fullName'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _skillsController.text = (data['skills'] as List<dynamic>?)?.join(', ') ?? '';
      });
    }
  }
  void _saveProfile() async {
    setState(() => _isSaving = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fullName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'skills': _skillsController.text.split(',').map((s) => s.trim()).toList(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật hồ sơ thành công!')));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa hồ sơ Thợ'), backgroundColor: const Color(0xFF1BA39C)),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Họ và tên')),
            const SizedBox(height: 15),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Số điện thoại')),
            const SizedBox(height: 15),
            TextField(
              controller: _skillsController,
              decoration: const InputDecoration(labelText: 'Kỹ năng (Ví dụ: Điện, Nước, Máy lạnh)', hintText: 'Cách nhau bằng dấu phẩy'),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1BA39C)),
                child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('LƯU HỒ SƠ', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}