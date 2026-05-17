import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart'; // Thư viện lịch cao cấp giống RN
import 'package:intl/intl.dart';

class WorkerScheduleScreen extends StatefulWidget {
  const WorkerScheduleScreen({super.key});

  @override
  State<WorkerScheduleScreen> createState() => _WorkerScheduleScreenState();
}

class _WorkerScheduleScreenState extends State<WorkerScheduleScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Lưu trữ danh sách ngày có việc để hiển thị vòng tròn màu đỏ
  Map<String, List<dynamic>> _markedDates = {};

  @override
  void initState() {
    super.initState();
    _listenToWorkerSchedule();
  }

  // ✅ 1. LẮNG NGHE REALTIME TOÀN BỘ LỊCH TRÌNH ĐỂ TÔ VÒNG TRÒN ĐỎ ĐỒNG BỘ REACT
  void _listenToWorkerSchedule() {
    if (_currentUserId.isEmpty) return;

    FirebaseFirestore.instance
        .collection('jobs') // Sử dụng đồng bộ collection 'jobs'
        .where('workerId', isEqualTo: _currentUserId)
        .where('status', isEqualTo: 'accepted') // Chỉ lấy việc đã nhận giống React
        .snapshots()
        .listen((snapshot) {
      final Map<String, List<dynamic>> tempMarks = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final String? workDateStr = data['workDate']; // Định dạng chuỗi "YYYY-MM-DD"
        if (workDateStr != null && workDateStr.isNotEmpty) {
          if (tempMarks[workDateStr] == null) {
            tempMarks[workDateStr] = [];
          }
          tempMarks[workDateStr]!.add(data);
        }
      }

      if (mounted) {
        setState(() {
          _markedDates = tempMarks;
        });
      }
    });
  }

  // Hàm chuyển đổi DateTime sang chuỗi String "yyyy-MM-dd" để so khớp bộ lọc
  String _formatDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // Cung cấp sự kiện cho bộ lịch để hiển thị chấm/vòng tròn
  List<dynamic> _getEventsForDay(DateTime day) {
    return _markedDates[_formatDateKey(day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final String selectedDateStr = _formatDateKey(_selectedDay);

    return Scaffold(
      backgroundColor: Colors.white,
      // AppBar đồng bộ thương hiệu xanh RAINN
      appBar: AppBar(
        title: const Text(
          'Lịch trình của tôi',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1BA39C)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF333333), size: 26),
            onPressed: () => context.push('/worker/chat-list'), // Điều hướng sang danh sách chat
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF5F5F5), height: 1),
        ),
      ),
      body: Column(
        children: [
          // --- 2. KHỐI BỘ LỊCH THÁNG ĐỒNG BỘ STYLE VÒNG TRÒN ĐỎ GIỐNG BẢN REACT ---
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 10),
            child: TableCalendar(
              firstDay: DateTime.utc(2025, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: _getEventsForDay,
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              // Style nâng cấp kết hợp màu đỏ rực khi có việc
              calendarStyle: CalendarStyle(
                todayTextStyle: const TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.bold),
                todayDecoration: const BoxDecoration(shape: BoxShape.circle),
                selectedDecoration: BoxDecoration(
                  // Nếu ngày được chọn có việc -> Tô Đỏ rực, nếu rảnh -> Tô Xanh thương hiệu
                  color: _getEventsForDay(_selectedDay).isNotEmpty ? const Color(0xFFFF5252) : const Color(0xFF1BA39C),
                  shape: BoxShape.circle,
                ),
                // Custom giao diện cho ngày có việc (Đốm sự kiện nằm ngầm phía dưới)
                markerDecoration: const BoxDecoration(
                  color: Color(0xFFFF5252),
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 1,
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),

          // Thanh ngăn cách xám nhẹ tạo chiều sâu giống bản gốc
          Container(height: 8, color: const Color(0xFFF9FAFB)),

          // --- 3. TIÊU ĐỀ NGÀY ĐANG CHỌN & SỐ LƯỢNG VIỆC VÀO THỜI GIAN THỰC ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ngày $selectedDateStr',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF2D3436)),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('jobs')
                      .where('workerId', isEqualTo: _currentUserId)
                      .where('workDate', isEqualTo: selectedDateStr)
                      .snapshots(),
                  builder: (context, snap) {
                    int count = snap.data?.size ?? 0;
                    return Text('$count công việc', style: const TextStyle(color: Colors.grey, fontSize: 13));
                  },
                ),
              ],
            ),
          ),

          // --- 4. DANH SÁCH CÔNG VIỆC LỌC THEO NGÀY CHỌN (REALTIME FIRESTORE) ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('jobs')
                  .where('workerId', isEqualTo: _currentUserId)
                  .where('workDate', isEqualTo: selectedDateStr)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Đã có lỗi xảy ra'));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final dayJobs = snapshot.data!.docs;

                // Giao diện trống khi Thợ đang rảnh
                if (dayJobs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month_outlined, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        const Text('Ngày này bạn đang rảnh', style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 15)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  itemCount: dayJobs.length,
                  itemBuilder: (context, index) {
                    final job = dayJobs[index].data() as Map<String, dynamic>;
                    final String jobId = dayJobs[index].id;
                    final String clientId = job['clientId'] ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF0F0F0)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: InkWell(
                        onTap: () {
                          if (clientId.isNotEmpty) {
                            context.push('/worker/chat/$clientId'); // Đẩy đúng clientId sang
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Không thể kết nối với khách hàng của đơn này.')),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Row(
                            children: [
                              // Cột Giờ hẹn bên trái
                              Container(
                                padding: const EdgeInsets.only(right: 15),
                                decoration: const BoxDecoration(
                                  border: Border(right: BorderSide(color: Color(0xFFEEEEEE))),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      job['workTime'] ?? '--:--',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1BA39C)),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(4)),
                                      child: const Text('Đã nhận', style: TextStyle(color: Color(0xFF1BA39C), fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ),

                              // Nội dung công việc ở giữa
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        job['subService'] ?? 'Dịch vụ sửa chữa',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, size: 14, color: Color(0xFF1BA39C)),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              job['address'] ?? 'Chưa cập nhật địa chỉ',
                                              style: const TextStyle(fontSize: 12, color: Color(0xFF777777)),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Icon Chat nhanh ở góc phải
                              Icon(Icons.chat_bubble_outline, color: const Color(0xFF1BA39C), size: 24),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}