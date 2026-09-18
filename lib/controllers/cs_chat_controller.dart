import 'package:get/get.dart';
import 'dart:async';
import 'dart:convert';
import '../core/api_client.dart';

class CsChatMessage {
  final String text;
  final bool isMe;
  final DateTime time;
  final String senderType;

  CsChatMessage({required this.text, required this.isMe, required this.time, required this.senderType});
}

class CsChatController extends GetxController {
  final String role; // 'user', 'driver', or 'merchant'
  
  var messages = <CsChatMessage>[].obs;
  var isLoading = true.obs;
  var isResolved = false.obs;
  
  Timer? _timer;

  CsChatController({required this.role});

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
      String endpoint = '/$role/cs/messages';
      final response = await ApiClient.get(endpoint);
      
      if (response.statusCode == 200) {
        var body = jsonDecode(response.body);
        if (body['data'] != null) {
          List<CsChatMessage> newMessages = [];
          for (var msg in body['data']) {
            newMessages.add(CsChatMessage(
              text: msg['message'],
              isMe: msg['sender_type'] == role,
              time: msg['created_at'] != null ? DateTime.parse(msg['created_at']) : DateTime.now(),
              senderType: msg['sender_type'] ?? '',
            ));
          }
          messages.value = newMessages;
          
          if (newMessages.isNotEmpty && newMessages.last.senderType == 'system' && newMessages.last.text == 'CHAT_RESOLVED') {
            isResolved.value = true;
          } else {
            isResolved.value = false;
          }
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

    // Optimistic UI update
    messages.add(CsChatMessage(
      text: text,
      isMe: true,
      time: DateTime.now(),
      senderType: role,
    ));

    try {
      String endpoint = '/$role/cs/send';
      
      var payload = {
        'message': text,
      };

      await ApiClient.post(endpoint, payload);
      // Fetch messages again to ensure sync
      fetchMessages(isBackground: true);
    } catch (e) {
      // Revert optimistic update? Or just show error
      Get.snackbar('Gagal', 'Pesan gagal dikirim');
    }
  }
}
