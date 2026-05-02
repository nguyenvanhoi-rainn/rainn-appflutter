import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ionicons/ionicons.dart';

class ManageServices extends StatefulWidget {
  const ManageServices({super.key});

  @override
  State<ManageServices> createState() => _ManageServicesState();
}

class _ManageServicesState extends State<ManageServices> {
  String? _selectedCategoryId;
  final _serviceController = TextEditingController();

  // Thêm dịch vụ con vào Firestore[cite: 6]
  Future<void> _addService() async {
    if (_serviceController.text.isEmpty || _selectedCategoryId == null) return;
    await FirebaseFirestore.instance.collection('services').add({
      'name': _serviceController.text.trim(),
      'categoryId': _selectedCategoryId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    _serviceController.clear();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý dịch vụ chi tiết')),
      body: Column(
        children: [
          // 1. Chọn danh mục lớn trước[cite: 6]
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('categories').snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const LinearProgressIndicator();
              final cats = snap.data!.docs;
              return Container(
                height: 60,
                padding: const EdgeInsets.all(10),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: cats.length,
                  itemBuilder: (context, i) {
                    bool isSelected = _selectedCategoryId == cats[i].id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        label: Text(cats[i]['name']),
                        selected: isSelected,
                        onSelected: (val) => setState(() => _selectedCategoryId = cats[i].id),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          // 2. Hiển thị dịch vụ con theo danh mục đã chọn[cite: 6]
          Expanded(
            child: _selectedCategoryId == null
                ? const Center(child: Text("Vui lòng chọn một danh mục."))
                : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('services')
                  .where('categoryId', isEqualTo: _selectedCategoryId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final services = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: services.length,
                  itemBuilder: (context, index) => ListTile(
                    leading: const Icon(Icons.settings_suggest, color: Color(0xFF1BA39C)),
                    title: Text(services[index]['name']),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => FirebaseFirestore.instance.collection('services').doc(services[index].id).delete(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm dịch vụ con'),
        content: TextField(controller: _serviceController, decoration: const InputDecoration(hintText: 'VD: Thay bóng đèn')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(onPressed: _addService, child: const Text('Lưu')),
        ],
      ),
    );
  }
}