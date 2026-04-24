import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/models/category_model.dart';

class BookingScreen extends StatefulWidget {
  final String serviceId;
  const BookingScreen({super.key, required this.serviceId});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _addressController = TextEditingController();
  final _descController = TextEditingController();
  final _dateController = TextEditingController(text: DateTime.now().toString().split(' ')[0]);

  CategoryModel? _category;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadServiceDetail();
  }

  // Lấy thông tin dịch vụ từ ID để hiển thị tên và giá chuẩn
  Future<void> _loadServiceDetail() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('categories')
          .doc(widget.serviceId)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _category = CategoryModel.fromFirestore(doc);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createBooking() async {
    if (_addressController.text.trim().isEmpty) {
      _showSnackBar("Vui lòng nhập địa chỉ thực hiện");
      return;
    }

    setState(() => _isSubmitting = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      // ĐỒNG BỘ: Sử dụng BookingModel để đóng gói dữ liệu
      final newBooking = BookingModel(
        id: '', // Firestore tự sinh ID
        clientId: user?.uid ?? '',
        clientName: user?.displayName ?? 'Khách hàng',
        serviceName: _category?.name ?? 'Dịch vụ lạ',
        address: _addressController.text.trim(),
        description: _descController.text.trim(),
        price: 200000, // Bạn có thể thêm trường giá vào CategoryModel nếu muốn
        date: _dateController.text,
        status: 'pending',
        paymentStatus: 'unpaid',
      );

      await FirebaseFirestore.instance
          .collection('bookings')
          .add(newBooking.toFirestore());

      if (mounted) {
        _showSnackBar("Đặt dịch vụ thành công!");
        context.go('/');
      }
    } catch (e) {
      _showSnackBar("Lỗi khi đặt lịch: $e");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Đặt ${_category?.name ?? 'Dịch vụ'}"),
        backgroundColor: const Color(0xFF1BA39C),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header hiển thị loại dịch vụ
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1BA39C).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.build_circle, size: 50, color: Color(0xFF1BA39C)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _category?.name ?? 'Thông tin dịch vụ',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            const Text("Thông tin đặt lịch", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 15),

            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: "Địa chỉ thực hiện *",
                prefixIcon: const Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _dateController,
              readOnly: true,
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2027),
                );
                if (pickedDate != null) {
                  setState(() => _dateController.text = pickedDate.toString().split(' ')[0]);
                }
              },
              decoration: InputDecoration(
                labelText: "Ngày thực hiện",
                prefixIcon: const Icon(Icons.calendar_today_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Ghi chú cho thợ (không bắt buộc)",
                hintText: "Ví dụ: Máy lạnh hiệu Daikin, bị chảy nước...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _createBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1BA39C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                    "XÁC NHẬN ĐẶT LỊCH",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}