import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final _categoryController = TextEditingController();

  // Hàm thêm danh mục mới vào Firestore (Tương tự addDoc trong RN)
  Future<void> _addCategory() async {
    if (_categoryController.text.isEmpty) return;

    await FirebaseFirestore.instance.collection('categories').add({
      'name': _categoryController.text.trim(),
      'icon': 'home_repair_service', // Có thể thêm logic chọn icon sau
      'createdAt': FieldValue.serverTimestamp(),
    });

    _categoryController.clear();
    if (mounted) Navigator.pop(context);
  }

  // Hàm xóa danh mục (Tương tự deleteDoc trong RN)
  Future<void> _deleteCategory(String id) async {
    await FirebaseFirestore.instance.collection('categories').doc(id).delete();
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm danh mục mới'),
        content: TextField(
          controller: _categoryController,
          decoration: const InputDecoration(hintText: 'Tên danh mục (VD: Dọn dẹp)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(onPressed: _addCategory, child: const Text('Thêm')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý danh mục'),
        backgroundColor: const Color(0xFF1BA39C),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('categories').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              return ListTile(
                leading: const Icon(Icons.category, color: Color(0xFF1BA39C)),
                title: Text(doc['name']),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteCategory(doc.id),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF1BA39C),
        child: const Icon(Icons.add),
      ),
    );
  }
}