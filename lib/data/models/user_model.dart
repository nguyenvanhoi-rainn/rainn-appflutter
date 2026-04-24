import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String role; // 'client', 'worker', 'admin'
  final String phone;
  final bool isVerified;
  final List<String>? skills; // Dành riêng cho thợ

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone = '',
    this.isVerified = false,
    this.skills,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      role: data['role'] ?? 'client',
      phone: data['phone'] ?? '',
      isVerified: data['isVerified'] ?? false,
      skills: data['skills'] is List ? List<String>.from(data['skills']) : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'role': role,
      'phone': phone,
      'isVerified': isVerified,
      'skills': skills,
    };
  }
}