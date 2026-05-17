import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; //
import 'package:intl/intl.dart';

class BookingScreen extends StatefulWidget {
  final String serviceId;
  const BookingScreen({super.key, required this.serviceId});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  // --- Controllers & Form State ---
  final _descController = TextEditingController();
  final _priceController = TextEditingController();

  String _selectedSubService = "";
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isNegotiable = false;
  LatLng? _selectedLocation;

  List<String> _subServices = [];
  String _categoryName = "Dịch vụ";
  bool _isLoadingData = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 1. Tải dữ liệu Danh mục và Dịch vụ con giống code React
  Future<void> _loadData() async {
    try {
      // Lấy tên danh mục
      final catDoc = await FirebaseFirestore.instance.collection('categories').doc(widget.serviceId).get();

      // Lấy danh sách dịch vụ con (sub-services)
      final serviceQuery = await FirebaseFirestore.instance
          .collection('services')
          .where('categoryId', isEqualTo: widget.serviceId)
          .get();

      if (mounted) {
        setState(() {
          _categoryName = catDoc.data()?['name'] ?? "Dịch vụ";
          _subServices = serviceQuery.docs.map((doc) => doc.data()['name'] as String).toList();
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  // 2. Hàm ghim vị trí trên Map
  void _openMapPicker() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            AppBar(
              title: const Text("Ghim vị trí công việc", style: TextStyle(fontSize: 16)),
              leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("XONG", style: TextStyle(color: Color(0xFF1BA39C), fontWeight: FontWeight.bold)),
                )
              ],
            ),
            Expanded(
              child: GoogleMapsPicker(
                initialLocation: _selectedLocation ?? const LatLng(10.9805, 106.6745), // Tọa độ Bình Dương
                onLocationSelected: (location) {
                  setState(() => _selectedLocation = location);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Hàm gửi yêu cầu (Booking)
  Future<void> _handleConfirm() async {
    if (_selectedSubService.isEmpty || _selectedLocation == null || (!_isNegotiable && _priceController.text.isEmpty)) {
      _showSnackBar("Vui lòng nhập đầy đủ thông tin (*)");
      return;
    }

    setState(() => _isSubmitting = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      final formattedTime = "${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}";

      await FirebaseFirestore.instance.collection('jobs').add({
        'clientId': user?.uid,
        'clientName': user?.displayName ?? "Khách hàng",
        'categoryId': widget.serviceId,
        'groupService': _categoryName,
        'subService': _selectedSubService,
        'description': _descController.text.trim(),
        'workDate': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'workTime': formattedTime,
        'location': {
          'latitude': _selectedLocation!.latitude,
          'longitude': _selectedLocation!.longitude,
        },
        'address': "Tọa độ: ${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}",
        'price': _isNegotiable ? "Thương lượng" : _priceController.text.replaceAll(',', ''),
        'status': "pending",
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showSnackBar("Gửi yêu cầu thành công!");
        context.go('/');
      }
    } catch (e) {
      _showSnackBar("Lỗi: Không thể gửi yêu cầu.");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Text(_categoryName, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Dịch vụ chi tiết (Chips)
            const Text("1. Dịch vụ chi tiết *", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: _subServices.map((s) => ChoiceChip(
                label: Text(s),
                selected: _selectedSubService == s,
                onSelected: (val) => setState(() => _selectedSubService = s),
                selectedColor: const Color(0xFF1BA39C),
                labelStyle: TextStyle(color: _selectedSubService == s ? Colors.white : Colors.black),
              )).toList(),
            ),

            // Section 2: Ngày & Giờ
            const SizedBox(height: 20),
            const Text("2. Chọn ngày & giờ *", style: TextStyle(fontWeight: FontWeight.bold)),
            CalendarDatePicker(
              initialDate: _selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime(2027),
              onDateChanged: (date) => setState(() => _selectedDate = date),
            ),
            ListTile(
              tileColor: const Color(0xFFF0F9F8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.access_time, color: Color(0xFF1BA39C)),
              title: Text("Giờ hẹn: ${_selectedTime.format(context)}"),
              onTap: () async {
                final time = await showTimePicker(context: context, initialTime: _selectedTime);
                if (time != null) setState(() => _selectedTime = time);
              },
            ),

            // Section 3: Giá tiền
            const SizedBox(height: 25),
            const Text("3. Giá tiền mong muốn (VNĐ) *", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    enabled: !_isNegotiable,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Ví dụ: 200,000",
                      filled: true,
                      fillColor: _isNegotiable ? Colors.grey[200] : const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _isNegotiable ? const Color(0xFF1BA39C) : Colors.transparent,
                    side: const BorderSide(color: Color(0xFF1BA39C)),
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                  ),
                  onPressed: () => setState(() => _isNegotiable = !_isNegotiable),
                  child: Text("Thương lượng", style: TextStyle(color: _isNegotiable ? Colors.white : const Color(0xFF1BA39C))),
                ),
              ],
            ),

            // Section 4: Vị trí
            const SizedBox(height: 25),
            const Text("4. Vị trí nơi làm việc *", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            InkWell(
              onTap: _openMapPicker,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: _selectedLocation != null ? const Color(0xFFF0F9F8) : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _selectedLocation != null ? const Color(0xFF1BA39C) : Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_searching, color: _selectedLocation != null ? const Color(0xFF1BA39C) : Colors.grey),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedLocation != null
                            ? "Đã ghim: ${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}"
                            : "Nhấn để chọn vị trí trên bản đồ...",
                        style: TextStyle(color: _selectedLocation != null ? const Color(0xFF1BA39C) : Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Section 5: Mô tả
            const SizedBox(height: 25),
            const Text("5. Mô tả chi tiết công việc", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Ghi chú thêm cho thợ...",
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),

            // Nút xác nhận
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1BA39C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: _isSubmitting ? null : _handleConfirm,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("XÁC NHẬN ĐẶT LỊCH", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// Widget hỗ trợ chọn vị trí trên Google Maps
class GoogleMapsPicker extends StatefulWidget {
  final LatLng initialLocation;
  final Function(LatLng) onLocationSelected;

  const GoogleMapsPicker({super.key, required this.initialLocation, required this.onLocationSelected});

  @override
  State<GoogleMapsPicker> createState() => _GoogleMapsPickerState();
}

class _GoogleMapsPickerState extends State<GoogleMapsPicker> {
  late LatLng _currentPos;

  @override
  void initState() {
    super.initState();
    _currentPos = widget.initialLocation;
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: _currentPos, zoom: 15),
      onTap: (pos) {
        setState(() => _currentPos = pos);
        widget.onLocationSelected(pos);
      },
      markers: {
        Marker(markerId: const MarkerId("selected"), position: _currentPos),
      },
    );
  }
}