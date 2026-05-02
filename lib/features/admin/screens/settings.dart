import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _hotlineController = TextEditingController();
  bool _isMaintenance = false;

  @override
  void initState() {
    super.initState();
    // Tải dữ liệu cấu hình hiện tại
    FirebaseFirestore.instance.collection('system').doc('config').get().then((doc) {
      if (doc.exists) {
        setState(() {
          _hotlineController.text = doc['hotline'] ?? '';
          _isMaintenance = doc['isMaintenance'] ?? false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt hệ thống')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("Cấu hình chung", style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(controller: _hotlineController, decoration: const InputDecoration(labelText: 'Số Hotline hỗ trợ')),
          SwitchListTile(
            title: const Text("Chế độ bảo trì"),
            subtitle: const Text("Tạm dừng hoạt động ứng dụng đối với khách hàng"),
            value: _isMaintenance,
            onChanged: (val) => setState(() => _isMaintenance = val),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('system').doc('config').set({
                'hotline': _hotlineController.text,
                'isMaintenance': _isMaintenance,
                'updatedAt': FieldValue.serverTimestamp(),
              });
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã lưu cài đặt!")));
            },
            child: const Text("LƯU CẤU HÌNH"),
          )
        ],
      ),
    );
  }
}