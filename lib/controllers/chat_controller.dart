import 'package:get/get.dart';
import 'dart:async';
import 'dart:convert';
import '../core/api_client.dart';
import 'auth_controller.dart';

class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime time;

  ChatMessage({required this.text, required this.isMe, required this.time});
}

class ChatController extends GetxController {
  final String orderId;
  final String senderType; // 'user' or 'driver'
  final bool isFood;
  
  var messages = <ChatMessage>[].obs;
  var isLoading = true.obs;
  
  Timer? _timer;

  ChatController({required this.orderId, required this.senderType, this.isFood = false});

  @override
  void onInit() {
    super.onInit();
    fetchMessages();
    // Polling setiap 3 detik
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      fetchMessages(isBackground: true);
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> fetchMessages({bool isBackground = false}) async {
    if (!isBackground) isLoading.value = true;
    
    try {
      // Karena routingnya ada di group /user/orders/chat dan /driver/orders/chat
      String endpoint = senderType == 'user' 
          ? (isFood ? '/user/orders/food-chat/$orderId' : '/user/orders/chat/$orderId') 
          : '/driver/orders/chat/$orderId'; // TODO: add driver food chat if needed
      final response = await ApiClient.get(endpoint);
      
      if (response.statusCode == 200) {
        var body = jsonDecode(response.body);
        if (body['data'] != null) {
          List<ChatMessage> newMessages = [];
          for (var msg in body['data']) {
            newMessages.add(ChatMessage(
              text: msg['message'],
              isMe: msg['sender_type'] == senderType,
              time: DateTime.parse(msg['created_at']),
            ));
          }
          messages.value = newMessages;
        }
      }
    } catch (e) {
      // ignore
    } finally {
      if (!isBackground) isLoading.value = false;
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final authController = Get.find<AuthController>();
    final senderId = authController.userData['id'];

    // Optimistic UI update
    messages.add(ChatMessage(
      text: text,
      isMe: true,
      time: DateTime.now(),
    ));

    try {
      String endpoint = senderType == 'user' 
          ? (isFood ? '/user/orders/food-chat' : '/user/orders/chat') 
          : '/driver/orders/chat';
      
      var payload = isFood ? {
        'food_order_id': orderId,
        'message': text,
      } : {
        'order_id': orderId,
        'sender_type': senderType,
        'sender_id': senderId,
        'message': text,
      };

      await ApiClient.post(endpoint, payload);
      // Background fetch akan menyinkronkan chat tak lama lagi
    } catch (e) {
      Get.snackbar('Error', 'Gagal mengirim pesan');
    }
  }
}
