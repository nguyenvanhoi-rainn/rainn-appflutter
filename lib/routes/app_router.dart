import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// --- AUTH ---
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';

// --- CLIENT ---
import '../features/main_wrapper.dart';
import '../features/client/screens/chat_detail_screen.dart';
import '../features/client/screens/profile_edit_screen.dart';
import '../features/client/screens/booking_screen.dart';
import '../features/client/screens/payment_screen.dart';

// --- WORKER ---
import '../features/worker_main_wrapper.dart';
import '../features/worker/screens/job_detail.dart';
import '../features/worker/screens/worker_chat_detail.dart';
import '../features/worker/screens/worker_profile_edit.dart';
import '../features/worker/screens/wallet_screen.dart';
import '../features/worker/screens/worker_schedule_screen.dart';

// --- ADMIN ---
import '../features/admin/screens/admin_dashboard.dart';
import '../features/admin/screens/verify_workers.dart';
import '../features/admin/screens/admin_categories.dart';
import '../features/admin/screens/admin_analytics.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    routes: [
      // 1. NHÓM AUTH (Đăng nhập & Đăng ký)
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // 2. NHÓM CLIENT (Sử dụng MainWrapper làm gốc)
      GoRoute(
        path: '/',
        name: 'main',
        builder: (context, state) => const MainWrapper(),
        routes: [
          GoRoute(
            path: 'chat/:chatId',
            builder: (context, state) => ChatDetailScreen(
              chatId: state.pathParameters['chatId']!,
            ),
          ),
          GoRoute(
            path: 'profile-edit',
            builder: (context, state) => const ProfileEditScreen(),
          ),
          GoRoute(
            path: 'booking/:serviceId',
            builder: (context, state) => BookingScreen(
              serviceId: state.pathParameters['serviceId']!,
            ),
          ),
          GoRoute(
            path: 'payment/:bookingId/:amount',
            builder: (context, state) => PaymentScreen(
              bookingId: state.pathParameters['bookingId']!,
              amount: double.parse(state.pathParameters['amount']!),
            ),
          ),
        ],
      ),

      // 3. NHÓM WORKER (Sử dụng WorkerMainWrapper làm gốc)
      GoRoute(
        path: '/worker',
        name: 'worker_main',
        builder: (context, state) => const WorkerMainWrapper(),
        routes: [
          // Chi tiết công việc
          GoRoute(
            path: 'job/:jobId',
            builder: (context, state) => JobDetailScreen(
              jobId: state.pathParameters['jobId']!,
            ),
          ),
          // Nhắn tin với khách
          GoRoute(
            path: 'chat/:chatId',
            builder: (context, state) => WorkerChatDetailScreen(
              chatId: state.pathParameters['chatId']!,
            ),
          ),
          // Chỉnh sửa hồ sơ thợ
          GoRoute(
            path: 'profile-edit',
            builder: (context, state) => const WorkerProfileEdit(),
          ),
          // Ví tiền & Thu nhập
          GoRoute(
            path: 'wallet',
            builder: (context, state) => const WalletScreen(),
          ),
          // Lịch trình (Nếu muốn mở trang riêng thay vì dùng tab)
          GoRoute(
            path: 'schedule',
            builder: (context, state) => const WorkerScheduleScreen(),
          ),
        ],
      ),

      // 4. NHÓM ADMIN (Quản trị viên)
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) => const AdminDashboardScreen(),
        routes: [
          GoRoute(
            path: 'verify-workers',
            builder: (context, state) => const VerifyWorkersScreen(),
          ),
          GoRoute(
            path: 'services',
            builder: (context, state) => const AdminCategoriesScreen(),
          ),
          GoRoute(
            path: 'analytics',
            builder: (context, state) => const AdminAnalyticsScreen(),
          ),
        ],
      ),
    ],

    // Xử lý lỗi khi đường dẫn không tồn tại
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            Text('Lỗi điều hướng: ${state.error}', textAlign: TextAlign.center),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('Quay lại Đăng nhập'),
            )
          ],
        ),
      ),
    ),
  );
}