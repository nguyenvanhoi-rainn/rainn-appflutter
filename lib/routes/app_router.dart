import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// --- AUTH ---
import '../features/admin/screens/admin_jobs_management.dart';
import '../features/admin/screens/admin_services_management.dart';
import '../features/admin/screens/admin_users.dart';
import '../features/admin/screens/settings.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';

// --- CLIENT ---
import '../features/client_main_wrapper.dart';
import '../features/client/screens/chat_detail.dart';
import '../features/client/screens/profile_edit.dart';
import '../features/client/screens/booking.dart';
import '../features/client/screens/payment.dart';
import '../features/client/screens/payment_result.dart';

// --- WORKER ---
import '../features/worker_main_wrapper.dart';
import '../features/worker/screens/job_detail.dart';
import '../features/worker/screens/worker_chat_detail.dart';
import '../features/worker/screens/worker_profile_edit.dart';
import '../features/worker/screens/wallet.dart';
import '../features/worker/screens/worker_schedule.dart';
import '../features/worker/screens/worker_reviews.dart';
import '../features/worker/screens/job_market.dart';

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
      // ==========================================
      // 1. NHÓM AUTH (Đăng nhập & Đăng ký)
      // ==========================================
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

      // ==========================================
      // 2. NHÓM CLIENT (Gốc: MainWrapper)
      // ==========================================
      GoRoute(
        path: '/',
        name: 'main',
        builder: (context, state) => const MainWrapper(),
        routes: [
          GoRoute(
            path: 'chat/:workerId', // Nhận duy nhất mã ID thợ
            builder: (context, state) {
              final workerId = state.pathParameters['workerId']!;
              return ClientChatDetailScreen(workerId: workerId);
            },
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
          // Sửa đổi Router nạp tiền: Trang ví/thanh toán tổng của Client giờ không cần param ép buộc ở URL
          GoRoute(
            path: 'payment',
            builder: (context, state) => const PaymentScreen(),
          ),
          GoRoute(
            path: 'payment-result',
            builder: (context, state) {
              return PaymentResultScreen(
                resultCode: state.uri.queryParameters['resultCode'] ?? '',
                orderId: state.uri.queryParameters['orderId'] ?? '',
                amount: state.uri.queryParameters['amount'] ?? '',
              );
            },
          ),
        ],
      ),

      // ==========================================
      // 3. NHÓM WORKER (Gốc: WorkerMainWrapper)
      // ==========================================
      GoRoute(
        path: '/worker',
        name: 'worker_main',
        builder: (context, state) => const WorkerMainWrapper(),
        routes: [
          GoRoute(
            path: 'job/:jobId',
            builder: (context, state) => JobDetailScreen(
              jobId: state.pathParameters['jobId']!,
            ),
          ),
          // Sửa đổi Router Chat của thợ: Đổi từ chatId thành clientId để đồng bộ.tsx]
          GoRoute(
            path: 'chat/:clientId',
            builder: (context, state) => WorkerChatDetailScreen(
              chatId: state.pathParameters['clientId']!, // Nhận ID Khách để truy vấn realtime.tsx]
            ),
          ),
          GoRoute(
            path: 'profile-edit',
            builder: (context, state) => const WorkerProfileEdit(),
          ),
          GoRoute(
            path: 'wallet',
            builder: (context, state) => const WalletScreen(), //
          ),
          GoRoute(
            path: 'schedule',
            builder: (context, state) => const WorkerScheduleScreen(), //
          ),
          GoRoute(
            path: 'reviews',
            builder: (context, state) => const WorkerReviewsScreen(), //
          ),
          GoRoute(
            path: 'job-market/:categoryId/:categoryName',
            builder: (context, state) => JobMarketScreen(
              categoryId: state.pathParameters['categoryId']!,
              categoryName: Uri.decodeComponent(state.pathParameters['categoryName']!), //
            ),
          ),
        ],
      ),

      // ==========================================
      // 4. NHÓM ADMIN (Quản trị viên)
      // ==========================================
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
            path: 'categories',
            builder: (context, state) => const AdminCategoriesScreen(),
          ),
          GoRoute(
            path: 'services',
            builder: (context, state) => const ManageServices(),
          ),
          GoRoute(
            path: 'analytics',
            builder: (context, state) => const AdminAnalyticsScreen(),
          ),
          GoRoute(
            path: 'users',
            builder: (context, state) => const ManageUsers(),
          ),
          GoRoute(
            path: 'jobs',
            builder: (context, state) => const AdminJobsManagement(),
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const AdminSettingsScreen(),
          ),
        ],
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            Text('Lỗi điều hướng: ${state.error}', textAlign: TextAlign.center),
            const SizedBox(height: 16),
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