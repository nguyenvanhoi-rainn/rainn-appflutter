import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/category_model.dart';

class ClientHomeScreen extends StatelessWidget {
  const ClientHomeScreen({super.key});

  // Hàm ánh xạ tên icon từ Firestore sang IconData của Flutter
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'home_repair_service': return Icons.home_repair_service;
      case 'electrical_services': return Icons.electrical_services;
      case 'plumbing': return Icons.plumbing;
      case 'air_conditioning': return Icons.ac_unit;
      case 'cleaning_services': return Icons.cleaning_services;
      case 'water_damage': return Icons.water_drop;
      default: return Icons.build;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar với hiệu ứng Parallax
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'RAINN SERVICES',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              centerTitle: true,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/banner_home.png',
                    fit: BoxFit.cover,
                  ),
                  // Lớp phủ tối để làm nổi bật tiêu đề
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black26, Colors.black54],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Phần nội dung chính
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tất cả dịch vụ',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Chọn loại hình sửa chữa bạn đang cần',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  _buildServiceGrid(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceGrid(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('categories').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Lỗi tải dữ liệu'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final categories = snapshot.data!.docs.map((doc) {
          return CategoryModel.fromFirestore(doc);
        }).toList();

        if (categories.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 50),
              child: Text('Hiện chưa có dịch vụ nào khả dụng.'),
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 25,
            crossAxisSpacing: 15,
            childAspectRatio: 0.8,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return InkWell(
              onTap: () => context.push('/booking/${category.id}'),
              borderRadius: BorderRadius.circular(15),
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFF1BA39C).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      _getIconData(category.icon),
                      color: const Color(0xFF1BA39C),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF34495E),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}