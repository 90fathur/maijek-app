import 'dart:convert';
import 'package:get/get.dart';
import '../core/api_client.dart';
import 'auth_controller.dart';

class NotificationController extends GetxController {
  var isLoading = false.obs;
  var notifications = [].obs;

  int get unreadCount => notifications.where((n) => n['is_read'] == 0 || n['is_read'] == '0' || n['is_read'] == false).length;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    if (Get.isRegistered<AuthController>() && !Get.find<AuthController>().isLogged.value) {
      notifications.clear();
      return;
    }

    isLoading.value = true;
    try {
      final response = await ApiClient.get('/user/notifications');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['data'] != null) {
          final rawList = List.from(body['data']);
          // Saring agar notifikasi status untuk nomor pesanan yang sama hanya tampil 1 yang paling baru
          final Map<String, bool> seenOrders = {};
          final List filtered = [];
          for (var item in rawList) {
            final text = '${item['title'] ?? ''} ${item['message'] ?? ''}';
            final match = RegExp(r'#(\d+)').firstMatch(text);
            if (match != null) {
              final orderId = match.group(1)!;
              if (seenOrders.containsKey(orderId)) {
                // Lewati status pesanan yang lebih lama
                continue;
              }
              seenOrders[orderId] = true;
            }
            filtered.add(item);
          }
          notifications.value = filtered;
        }
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Tambah atau perbarui notifikasi status pesanan agar hanya 1 notifikasi terakhir yang tampil untuk pesanan tersebut
  void addOrUpdateOrderNotification({
    required String orderId,
    required String title,
    required String message,
    String type = 'order_status_update',
  }) {
    var notifList = List.from(notifications);
    // Hapus status notifikasi lama untuk pesanan yang sama
    notifList.removeWhere((item) {
      final text = '${item['title'] ?? ''} ${item['message'] ?? ''}';
      return text.contains('#$orderId');
    });

    // Masukkan notifikasi status terbaru di urutan paling atas
    notifList.insert(0, {
      'id': 'temp_$orderId',
      'title': title,
      'message': message,
      'type': type,
      'is_read': 0,
      'created_at': DateTime.now().toIso8601String(),
    });

    notifications.value = notifList;
  }

  Future<void> markAsRead(int index, String id) async {
    if (notifications[index]['is_read'] == 0 || notifications[index]['is_read'] == "0") {
      // Optimistic UI update
      var notifList = List.from(notifications);
      notifList[index]['is_read'] = 1;
      notifications.value = notifList;
      
      try {
        await ApiClient.post('/user/notifications/$id/read', {});
      } catch (e) {
        print('Error marking notification as read: $e');
      }
    }
  }
}
