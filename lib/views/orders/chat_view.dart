import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import '../../core/contact_helper.dart';
import '../../controllers/chat_controller.dart';

class ChatView extends StatelessWidget {
  final String orderId;
  final String driverName;
  final String? driverPhoto;
  final bool isFood;
  final String? driverPhone;
  
  const ChatView({
    super.key, 
    required this.orderId, 
    required this.driverName, 
    this.driverPhoto, 
    this.isFood = false,
    this.driverPhone,
  });

  @override
  Widget build(BuildContext context) {
    // Note: Use Get.put to initialize the controller for this order
    final ChatController chatController = Get.put(ChatController(orderId: orderId, senderType: 'user', isFood: isFood), tag: orderId);
    final TextEditingController _controller = TextEditingController();
    final ScrollController _scrollController = ScrollController();

    final List<String> quickReplies = [
      'Oke, saya tunggu',
      'Tolong agak cepat ya',
      'Sesuai titik ya Pak',
      'Saya pakai baju merah',
      'Terima kasih'
    ];

    // Auto scroll saat ada pesan baru
    ever(chatController.messages, (_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(ApiClient.getImageUrl(driverPhoto)),
              radius: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driverName,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isFood ? 'Mitra MaiFood' : 'Driver Maijek',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (driverPhone != null && driverPhone!.trim().isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
              tooltip: 'Chat WhatsApp',
              onPressed: () {
                ContactHelper.openWhatsApp(
                  phone: driverPhone,
                  name: driverName,
                  orderId: orderId,
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.phone_in_talk, color: Colors.white),
              tooltip: 'Panggilan Telepon',
              onPressed: () {
                ContactHelper.makePhoneCall(driverPhone);
              },
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Info Banner
          Container(
            color: Colors.orange.shade50,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.shield, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pesan Anda aman. Jangan berikan informasi sensitif seperti password.',
                    style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          
          // Chat List
          Expanded(
            child: Obx(() {
              if (chatController.isLoading.value && chatController.messages.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: chatController.messages.length,
                itemBuilder: (context, index) {
                  final msg = chatController.messages[index];
                  return _buildMessageBubble(msg, context);
                },
              );
            }),
          ),
          
          // Input Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: quickReplies.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            label: Text(quickReplies[index], style: TextStyle(fontSize: 12, color: AppTheme.primaryBlue)),
                            backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            onPressed: () {
                              chatController.sendMessage(quickReplies[index]);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: 'Ketik pesan...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade200,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onSubmitted: (text) {
                            if (text.trim().isNotEmpty) {
                              chatController.sendMessage(text);
                              _controller.clear();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: AppTheme.primaryBlue,
                        radius: 24,
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white, size: 20),
                          onPressed: () {
                            if (_controller.text.trim().isNotEmpty) {
                              chatController.sendMessage(_controller.text);
                              _controller.clear();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, BuildContext context) {
    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: msg.isMe 
              ? const LinearGradient(colors: [AppTheme.primaryBlue, AppTheme.secondaryBlue])
              : null,
          color: msg.isMe ? null : Colors.white,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: msg.isMe ? const Radius.circular(0) : const Radius.circular(20),
            bottomLeft: !msg.isMe ? const Radius.circular(0) : const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))
          ],
          border: msg.isMe ? null : Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                color: msg.isMe ? Colors.white : AppTheme.textMain,
                fontSize: 15,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: msg.isMe ? Colors.white70 : AppTheme.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (msg.isMe) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.done_all, color: Colors.white70, size: 12),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
