import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final DateTime? createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    this.icon = 'home_repair_service', // Giá trị mặc định
    this.createdAt,
  });

  // Chuyển đổi từ dữ liệu Firestore (JSON) sang Object Model
  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return CategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      icon: data['icon'] ?? 'home_repair_service',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  // Chuyển đổi từ Object Model sang JSON để lưu lên Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'icon': icon,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}