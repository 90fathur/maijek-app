import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme.dart';
import 'core/notification_service.dart';
import 'controllers/auth_controller.dart';
import 'views/auth/login_view.dart';
import 'views/auth/register_view.dart';
import 'views/auth/verify_otp_view.dart';
import 'views/main/main_layout_view.dart';
import 'views/profile/profile_view.dart';
import 'views/orders/order_history_view.dart';
import 'views/orders/order_tracking_view.dart';
import 'views/orders/rating_view.dart';
import 'views/wallet/wallet_view.dart';
import 'views/food/tracking_view.dart';
import 'views/send/send_view.dart';
import 'views/titip/titip_view.dart';
import 'views/profile/cs_chat_view.dart';
import 'views/inbox/inbox_view.dart';
import 'views/mart/mart_view.dart';
import 'controllers/mart_controller.dart';
import 'controllers/food_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.init();
  Get.put(AuthController());
  Get.lazyPut(() => MartController(), fenix: true);
  Get.lazyPut(() => FoodController(), fenix: true);
  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('token');

  runApp(MyApp(initialRoute: token != null ? '/home' : '/login'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Maijek App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: initialRoute,
      getPages: [
        GetPage(name: '/login', page: () => const LoginView()),
        GetPage(name: '/register', page: () => const RegisterView()),
        GetPage(name: '/verify-otp', page: () => const VerifyOtpView()),
        GetPage(name: '/home', page: () => MainLayoutView()),
        GetPage(name: '/profile', page: () => const ProfileView()),
        GetPage(name: '/wallet', page: () => const WalletView()),
        GetPage(name: '/history', page: () => const OrderHistoryView()),
        GetPage(name: '/order-tracking', page: () => const OrderTrackingView()),
        GetPage(name: '/rating', page: () => const RatingView()),
        GetPage(name: '/food/tracking', page: () => FoodTrackingView()),
        GetPage(name: '/mart', page: () => const MartView()),
        GetPage(name: '/send', page: () => const SendView()),
        GetPage(name: '/titip', page: () => const TitipView()),
        GetPage(name: '/cs-chat', page: () => const CsChatView()),
        GetPage(name: '/inbox', page: () => const InboxView()),
      ],
    );
  }
}
