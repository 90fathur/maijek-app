import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/school_controller.dart';
import '../../core/theme.dart';

class SchoolChatView extends StatefulWidget {
  final int driverId;
  final String driverName;
  final String driverPlate;

  const SchoolChatView({
    super.key,
    required this.driverId,
    required this.driverName,
    required this.driverPlate,
  });

  @override
  State<SchoolChatView> createState() => _SchoolChatViewState();
}

class _SchoolChatViewState extends State<SchoolChatView> {
  final SchoolController controller = Get.find<SchoolController>();

  @override
  void initState() {
    super.initState();
    controller.fetchInquiries(widget.driverId);
  }

  void _sendQuickText(String text) {
    controller.chatTextController.text = text;
    controller.sendInquiry(widget.driverId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.driverName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
            Text(
              'Plat: ${widget.driverPlate} • Diskusi Pra-Booking',
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8)),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          // Banner Keamanan & SOP
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFE0F2FE),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFF0284C7), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Diskusikan rute rumah, jam jemput, atau kebutuhan khusus anak Anda dengan mitra driver.',
                    style: TextStyle(fontSize: 11, color: Colors.blue.shade900),
                  ),
                ),
              ],
            ),
          ),

          // Daftar Pesan
          Expanded(
            child: Obx(() {
              final messages = controller.chatMessages;

              if (messages.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 54, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'Mulai Percakapan',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pilih pertanyaan cepat di bawah atau ketik pesan Anda sendiri.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe = msg['sender_type'] == 'user';

                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      decoration: BoxDecoration(
                        color: isMe ? const Color(0xFF059669) : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(14),
                          topRight: const Radius.circular(14),
                          bottomLeft: Radius.circular(isMe ? 14 : 2),
                          bottomRight: Radius.circular(isMe ? 2 : 14),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Text(
                        msg['message'] ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: isMe ? Colors.white : AppTheme.textMain,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),

          // Quick Suggestion Chips
          Container(
            height: 38,
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildQuickChip('Apakah sedia helm anak?'),
                _buildQuickChip('Muat bawa tas ransel besar?'),
                _buildQuickChip('Bisa tunggu di depan gerbang?'),
                _buildQuickChip('Bisa jemput jam 06.15 pagi?'),
              ],
            ),
          ),

          // Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.chatTextController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Tulis pesan untuk mitra driver...',
                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Color(0xFF059669))),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Obx(() {
                    return CircleAvatar(
                      backgroundColor: const Color(0xFF059669),
                      radius: 20,
                      child: controller.isSendingChat.value
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : IconButton(
                              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                              onPressed: () => controller.sendInquiry(widget.driverId),
                            ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF065F46), fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFECFDF5),
        side: BorderSide(color: Colors.green.shade200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: () => _sendQuickText(text),
      ),
    );
  }
}
