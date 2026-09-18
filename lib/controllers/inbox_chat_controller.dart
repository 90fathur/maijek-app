import 'dart:convert';
import 'package:get/get.dart';
import '../core/api_client.dart';

class InboxChatController extends GetxController {
  var isLoading = false.obs;
  var chats = [].obs;

  @override
  void onInit() {
    super.onInit();
    fetchChats();
  }

  Future<void> fetchChats() async {
    isLoading.value = true;
    try {
      final response = await ApiClient.get('/user/inbox-chats');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['data'] != null) {
          chats.value = body['data'];
        }
      }
    } catch (e) {
      print('Error fetching inbox chats: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
