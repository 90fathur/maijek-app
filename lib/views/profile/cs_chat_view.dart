import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme.dart';
import '../../controllers/cs_chat_controller.dart';

class CsChatView extends StatelessWidget {
  const CsChatView({super.key});

  @override
  Widget build(BuildContext context) {
    // Assuming this view is used in User app, so role = 'user'
    final CsChatController chatController = Get.put(CsChatController(role: 'user'));
    final TextEditingController textController = TextEditingController();
    final ScrollController scrollController = ScrollController();

    final List<String> quickReplies = [
      'Halo CS, saya mau lapor',
      'Barang saya ketinggalan',
      'Pesanan tidak sesuai',
      'Kendala teknis aplikasi',
      'Terima kasih'
    ];

    ever(chatController.messages, (_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
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
            const CircleAvatar(
              backgroundColor: Colors.white,
              radius: 18,
              child: Icon(Icons.support_agent, color: AppTheme.primaryBlue),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pusat Bantuan CS', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Layanan 24/7', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Info Banner
          Container(
            color: Colors.blue.shade50,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Silakan ceritakan kendala Anda. Tim CS kami akan segera membantu.',
                    style: TextStyle(color: Colors.blue.shade800, fontSize: 12),
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
              if (chatController.messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('Belum ada pesan.\nMulai obrolan dengan CS.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                controller: scrollController,
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
          Obx(() {
            if (chatController.isResolved.value) {
              return Container(
                padding: const EdgeInsets.all(16),
                color: Colors.amber.shade50,
                width: double.infinity,
                child: const Text(
                  'Sesi chat ini telah diselesaikan oleh Admin. Jika butuh bantuan lebih lanjut, silakan mulai chat baru atau kembali nanti.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.amber, fontStyle: FontStyle.italic),
                ),
              );
            }
            return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
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
                            label: Text(quickReplies[index], style: const TextStyle(fontSize: 12, color: AppTheme.primaryNavy)),
                            backgroundColor: AppTheme.primaryNavy.withValues(alpha: 0.1),
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
                          controller: textController,
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
                              textController.clear();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: AppTheme.primaryNavy,
                        radius: 24,
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white, size: 20),
                          onPressed: () {
                            if (textController.text.trim().isNotEmpty) {
                              chatController.sendMessage(textController.text);
                              textController.clear();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    ),
  );
}

  Widget _buildMessageBubble(CsChatMessage msg, BuildContext context) {
    if (msg.senderType == 'system') {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.amber.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            msg.text == 'CHAT_RESOLVED' ? 'Sesi chat telah diselesaikan.' : msg.text,
            style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }
    
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
