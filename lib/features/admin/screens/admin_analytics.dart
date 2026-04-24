import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Cần thêm: flutter pub add fl_chart

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê doanh thu'),
        backgroundColor: const Color(0xFF1BA39C),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Biểu đồ tăng trưởng đơn hàng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Biểu đồ đường (LineChart) tương đương với logic hiển thị dữ liệu trong analytics.tsx
            AspectRatio(
              aspectRatio: 1.7,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 3),
                        FlSpot(2, 5),
                        FlSpot(4, 4),
                        FlSpot(6, 8),
                      ],
                      isCurved: true,
                      color: const Color(0xFF1BA39C),
                      barWidth: 4,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            _buildSummaryTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTable() {
    return Card(
      child: Column(
        children: [
          ListTile(title: const Text('Tổng doanh thu'), trailing: const Text('50.000.000đ', style: TextStyle(fontWeight: FontWeight.bold))),
          const Divider(),
          ListTile(title: const Text('Số đơn hoàn thành'), trailing: const Text('120')),
        ],
      ),
    );
  }
}