import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../views/main/main_layout_view.dart';
import '../controllers/notification_controller.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final FlutterLocalNotificationsPlugin localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );
  await localNotificationsPlugin.initialize(settings: initializationSettings);

  const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
    'maijek_user_general_v7',
    'Notifikasi Pelanggan Maijek',
    description: 'Saluran notifikasi utama untuk status perjalanan dan pesan.',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('courier_near'),
    enableVibration: true,
    audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
  );

  const AndroidNotificationChannel orderChannel = AndroidNotificationChannel(
    'maijek_user_order_v7',
    'Status Pesanan Maijek',
    description: 'Saluran notifikasi pembaruan pesanan dan makanan.',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('courier_near'),
    enableVibration: true,
    audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
  );

  final androidImpl = localNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  try {
    await androidImpl?.deleteNotificationChannel(channelId: 'maijek_user_general_v6');
    await androidImpl?.deleteNotificationChannel(channelId: 'maijek_user_general_v5');
    await androidImpl?.deleteNotificationChannel(channelId: 'maijek_user_general_v4');
    await androidImpl?.deleteNotificationChannel(channelId: 'maijek_user_order_v6');
    await androidImpl?.deleteNotificationChannel(channelId: 'maijek_user_order_v5');
    await androidImpl?.deleteNotificationChannel(channelId: 'maijek_user_order_v4');
    await androidImpl?.deleteNotificationChannel(channelId: 'high_importance_channel');
  } catch (_) {}
  await androidImpl?.createNotificationChannel(defaultChannel);
  await androidImpl?.createNotificationChannel(orderChannel);

  // Jika payload data-only (tanpa notifikasi sistem otomatis)
  if (message.notification == null && message.data.isNotEmpty) {
    String? title = message.data['title'];
    String? body = message.data['message'] ?? message.data['body'];
    if (title != null && title.isNotEmpty) {
      int notificationId = NotificationService.resolveNotificationId(message.data);
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
            sound: const RawResourceAndroidNotificationSound('courier_near'),
            enableVibration: true,
            visibility: NotificationVisibility.public,
            audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
            ticker: title,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }
}

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel defaultChannel =
      AndroidNotificationChannel(
        'maijek_user_general_v7',
        'Notifikasi Pelanggan Maijek',
        description:
            'Saluran notifikasi utama untuk status perjalanan dan pesan.',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('courier_near'),
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
      );

  static const AndroidNotificationChannel orderChannel =
      AndroidNotificationChannel(
        'maijek_user_order_v7',
        'Status Pesanan Maijek',
        description: 'Saluran notifikasi pembaruan pesanan dan makanan.',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('courier_near'),
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
      );

  static Future<void> playAlertSound() async {
    try {
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.release);
      await player.setVolume(1.0);
      await player.play(AssetSource('audio/courier_near.mp3'));
    } catch (_) {}
  }

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

    // Konfigurasi audio global agar memutar di volume nada dering / notifikasi
    try {
      await AudioPlayer.global.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.notificationRingtone,
          audioFocus: AndroidAudioFocus.gainTransientExclusive,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
      ));
    } catch (_) {}

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    // Permissions already requested via FirebaseMessaging above.
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle navigasi jika notifikasi diklik
        _handleNotificationClick(response.payload);
      },
    );

    final androidImpl = _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    try {
      await androidImpl?.deleteNotificationChannel(channelId: 'maijek_user_general_v6');
      await androidImpl?.deleteNotificationChannel(channelId: 'maijek_user_general_v5');
      await androidImpl?.deleteNotificationChannel(channelId: 'maijek_user_general_v4');
      await androidImpl?.deleteNotificationChannel(channelId: 'maijek_user_order_v6');
      await androidImpl?.deleteNotificationChannel(channelId: 'maijek_user_order_v5');
      await androidImpl?.deleteNotificationChannel(channelId: 'maijek_user_order_v4');
      await androidImpl?.deleteNotificationChannel(channelId: 'high_importance_channel');
    } catch (_) {}
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
      // Putar nada dering resmi pelanggan saat ada notifikasi masuk di foreground
      playAlertSound();

      if (message.notification != null) {
        _showNotification(message.notification, message.data);
      } else if (message.data.isNotEmpty && message.data['title'] != null) {
        int notificationId = resolveNotificationId(message.data);
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
              sound: const RawResourceAndroidNotificationSound('courier_near'),
              enableVibration: true,
              visibility: NotificationVisibility.public,
              audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
              ticker: message.data['title'],
            ),
          ),
          payload: message.data.toString(),
        );
      }
    });

    // Handle saat aplikasi dibuka dari keadaan mati (terminated) karena notifikasi diklik
    RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();
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

  /// Resolusi ID notifikasi: Notifikasi dengan order_id yang sama selalu menggunakan ID tetap
  /// sehingga di status bar Android hanya muncul SATU notifikasi saja (notifikasi lama langsung ditimpa status terbaru).
  static int resolveNotificationId(Map<String, dynamic> data) {
    final orderId = data['order_id'] ?? data['orderId'] ?? data['id'];
    if (orderId != null && orderId.toString().isNotEmpty) {
      final parsed = int.tryParse(orderId.toString()) ?? orderId.hashCode.abs();
      return 70000 + (parsed % 10000);
    }
    final type = data['type']?.toString();
    if (type != null &&
        (type.contains('order') ||
            type.contains('food') ||
            type.contains('ride') ||
            type.contains('mart') ||
            type.contains('status'))) {
      return 77777;
    }
    return DateTime.now().millisecondsSinceEpoch % 100000;
  }

  static void _showNotification(
    RemoteNotification? notification,
    Map<String, dynamic> data,
  ) {
    if (notification != null) {
      int notificationId = resolveNotificationId(data);
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
            sound: const RawResourceAndroidNotificationSound('courier_near'),
            enableVibration: true,
            visibility: NotificationVisibility.public,
            audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
            ticker: notification.title,
            fullScreenIntent: false,
          ),
        ),
        payload: data.toString(),
      );
    }
  }

  /// Tampilkan notifikasi lokal untuk status penting (seperti kurir dekat)
  /// Menggunakan ID pesanan agar menimpa notifikasi pesanan sebelumnya (jadi satu notifikasi saja)
  static Future<void> showLocalAlert({
    required String title,
    required String body,
    String? sound,
    String? payload,
    String? orderId,
  }) async {
    try {
      int notificationId = resolveNotificationId({'order_id': orderId});
      await _localNotificationsPlugin.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            orderChannel.id,
            orderChannel.name,
            channelDescription: orderChannel.description,
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            sound: RawResourceAndroidNotificationSound(sound ?? 'courier_near'),
            enableVibration: true,
            visibility: NotificationVisibility.public,
            audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
            ticker: title,
          ),
        ),
        payload: payload ?? '',
      );
    } catch (e) {
      debugPrint('showLocalAlert error: $e');
    }
  }
}
