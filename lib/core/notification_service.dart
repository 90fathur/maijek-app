import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../views/main/main_layout_view.dart';
import '../controllers/notification_controller.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  
  final FlutterLocalNotificationsPlugin localNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await localNotificationsPlugin.initialize(settings: initializationSettings);

  const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
    'high_importance_channel',
    'Notifikasi Penting Maijek',
    description: 'Saluran notifikasi utama untuk status perjalanan dan pesan.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  const AndroidNotificationChannel orderChannel = AndroidNotificationChannel(
    'maifood_order_channel_v2',
    'Status Pesanan Maijek',
    description: 'Saluran notifikasi pembaruan pesanan dan makanan.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  final androidImpl = localNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  await androidImpl?.createNotificationChannel(defaultChannel);
  await androidImpl?.createNotificationChannel(orderChannel);

  // Jika payload data-only (tanpa notifikasi sistem otomatis)
  if (message.notification == null && message.data.isNotEmpty) {
    String? title = message.data['title'];
    String? body = message.data['message'] ?? message.data['body'];
    if (title != null && title.isNotEmpty) {
      int notificationId = DateTime.now().millisecondsSinceEpoch % 100000;
      localNotificationsPlugin.show(
        id: notificationId,
        title: title,
        body: body ?? '',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            defaultChannel.id,
            defaultChannel.name,
            channelDescription: defaultChannel.description,
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            visibility: NotificationVisibility.public,
            ticker: title,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }
}

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
    'high_importance_channel',
    'Notifikasi Penting Maijek',
    description: 'Saluran notifikasi utama untuk status perjalanan dan pesan.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static const AndroidNotificationChannel orderChannel = AndroidNotificationChannel(
    'maifood_order_channel_v2',
    'Status Pesanan Maijek',
    description: 'Saluran notifikasi pembaruan pesanan dan makanan.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static Future<void> init() async {
    // Request permission (termasuk Android 13+ & iOS)
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Set opsi presentasi foreground agar notifikasi tetap berbunyi saat aplikasi terbuka
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle navigasi jika notifikasi diklik
        _handleNotificationClick(response.payload);
      },
    );

    final androidImpl = _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(defaultChannel);
    await androidImpl?.createNotificationChannel(orderChannel);
    await androidImpl?.requestNotificationsPermission();

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Otomatis sinkronisasi token saat Firebase merotasi token baru
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      try {
        if (Get.isRegistered<AuthController>()) {
          Get.find<AuthController>().updateFcmToken();
        }
      } catch (_) {}
    });

    // Subscribe ke topic broadcast umum agar broadcast instan seketika
    try {
      _firebaseMessaging.subscribeToTopic('all');
      _firebaseMessaging.subscribeToTopic('users');
    } catch (_) {}

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showNotification(message.notification, message.data);
      } else if (message.data.isNotEmpty && message.data['title'] != null) {
        int notificationId = DateTime.now().millisecondsSinceEpoch % 100000;
        _localNotificationsPlugin.show(
          id: notificationId,
          title: message.data['title'],
          body: message.data['message'] ?? message.data['body'] ?? '',
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              defaultChannel.id,
              defaultChannel.name,
              channelDescription: defaultChannel.description,
              icon: '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
              visibility: NotificationVisibility.public,
              ticker: message.data['title'],
            ),
          ),
          payload: message.data.toString(),
        );
      }
    });

    // Handle saat aplikasi dibuka dari keadaan mati (terminated) karena notifikasi diklik
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      Future.delayed(const Duration(milliseconds: 700), () {
        _handleNotificationClick(initialMessage.data.toString());
      });
    }

    // Handle saat aplikasi dibuka dari keadaan notifikasi di-tap (background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(message.data.toString());
    });
  }

  static void _handleNotificationClick(String? payload) {
    debugPrint('[FCM] Notification clicked with payload: $payload');
    try {
      if (payload != null && payload.contains('order')) {
        Get.toNamed('/history');
      } else {
        // Navigasi langsung ke Kotak Masuk (Tab Notifikasi)
        if (Get.isRegistered<MainLayoutController>()) {
          Get.find<MainLayoutController>().changePage(3);
        } else {
          Get.toNamed('/inbox');
        }
        if (Get.isRegistered<NotificationController>()) {
          Get.find<NotificationController>().fetchNotifications();
        }
      }
    } catch (e) {
      debugPrint('[FCM] Error navigating from notification: $e');
      try {
        Get.toNamed('/inbox');
      } catch (_) {}
    }
  }

  static Future<String?> getToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      debugPrint('[FCM] Token retrieved: $token');
      return token;
    } catch (e) {
      debugPrint('[FCM] Error getting FCM token: $e');
      return null;
    }
  }

  static void _showNotification(RemoteNotification? notification, Map<String, dynamic> data) {
    if (notification != null) {
      int notificationId = DateTime.now().millisecondsSinceEpoch % 100000;
      _localNotificationsPlugin.show(
        id: notificationId,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            defaultChannel.id,
            defaultChannel.name,
            channelDescription: defaultChannel.description,
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            visibility: NotificationVisibility.public,
            ticker: notification.title,
            fullScreenIntent: false,
          ),
        ),
        payload: data.toString(),
      );
    }
  }
}
