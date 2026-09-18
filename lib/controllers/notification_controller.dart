import 'dart:convert';
import 'package:get/get.dart';
import '../core/api_client.dart';

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
    isLoading.value = true;
    try {
      final response = await ApiClient.get('/user/notifications');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['data'] != null) {
          notifications.value = body['data'];
        }
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    } finally {
      isLoading.value = false;
    }
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
