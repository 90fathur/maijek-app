import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme.dart';
import '../../controllers/notification_controller.dart';
import '../../controllers/inbox_chat_controller.dart';

class InboxView extends StatelessWidget {
  const InboxView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: const Text('Kotak Masuk'),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            labelColor: AppTheme.primaryBlue,
            unselectedLabelColor: AppTheme.textMuted,
            indicatorColor: AppTheme.primaryBlue,
            tabs: [
              Tab(text: 'Notifikasi'),
              Tab(text: 'Chat'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildNotificationList(),
            _buildChatList(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList() {
    final NotificationController notifController = Get.put(NotificationController());

    return Obx(() {
      if (notifController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (notifController.notifications.isEmpty) {
        return RefreshIndicator(
          onRefresh: notifController.fetchNotifications,
          child: ListView(
            children: const [
              SizedBox(height: 100),
              Center(child: Text('Belum ada notifikasi.', style: TextStyle(color: AppTheme.textMuted))),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: notifController.fetchNotifications,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifController.notifications.length,
          itemBuilder: (context, index) {
            var notif = notifController.notifications[index];
            IconData icon = Icons.notifications;
            if (notif['type'] == 'promo') icon = Icons.local_offer;
            if (notif['type'] == 'transaction') icon = Icons.account_balance_wallet;
            if (notif['type'] == 'system') icon = Icons.security;

            bool isUnread = notif['is_read'] == 0 || notif['is_read'] == "0";

            return GestureDetector(
              onTap: () {
                if (isUnread) {
                  notifController.markAsRead(index, notif['id'].toString());
                }
                _showNotificationDetail(context, notif, icon);
              },
              child: _buildNotificationItem(
                icon, 
                notif['title'] ?? '', 
                notif['message'] ?? '', 
                _formatDate(notif['created_at']),
                isUnread: isUnread,
              ),
            );
          },
        ),
      );
    });
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      DateTime date = DateTime.parse(dateStr);
      DateTime now = DateTime.now();
      Duration diff = now.difference(date);
      
      if (diff.inMinutes < 60) {
          if(diff.inMinutes <= 0) return 'Baru saja';
          return '${diff.inMinutes} mnt lalu';
      }
      if (diff.inHours < 24) return '${diff.inHours} jam lalu';
      if (diff.inDays == 1) return 'Kemarin';
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }

  Widget _buildChatList() {
    final InboxChatController chatController = Get.put(InboxChatController());

    return Obx(() {
      if (chatController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (chatController.chats.isEmpty) {
        return RefreshIndicator(
          onRefresh: chatController.fetchChats,
          child: ListView(
            children: const [
              SizedBox(height: 100),
              Center(child: Text('Belum ada pesan obrolan.', style: TextStyle(color: AppTheme.textMuted))),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: chatController.fetchChats,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: chatController.chats.length,
          itemBuilder: (context, index) {
            var chat = chatController.chats[index];
            return _buildChatItem(
              chat['name'] ?? '',
              chat['last_message'] ?? '',
              _formatDate(chat['time']),
              chat['initials'] ?? '',
              isUnread: chat['is_unread'] ?? false,
              chatData: chat,
            );
          },
        ),
      );
    });
  }

  Widget _buildNotificationItem(IconData icon, String title, String desc, String time, {bool isUnread = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread ? Colors.white : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: isUnread ? Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(time, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildChatItem(String name, String message, String time, String initials, {bool isUnread = false, Map? chatData}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppTheme.secondaryBlue,
        child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      title: Text(name, style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.w600)),
      subtitle: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(time, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          if (isUnread)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 8, height: 8,
              decoration: const BoxDecoration(color: AppTheme.error, shape: BoxShape.circle),
            )
        ],
      ),
      onTap: () {
        if (chatData != null) {
          if (chatData['type'] == 'cs') {
            Get.toNamed('/cs-chat'); // Assuming you have a route for CS Chat
          } else if (chatData['type'] == 'ride') {
            // Get.toNamed('/order-chat', arguments: chatData['target_id']);
          }
        }
      },
    );
  }

  void _showNotificationDetail(BuildContext context, dynamic notif, IconData icon) {
    String type = (notif['type'] ?? 'system').toString();
    Color badgeColor = AppTheme.primaryNavy;
    String typeLabel = 'Sistem';
    if (type == 'promo') {
      badgeColor = Colors.orange.shade800;
      typeLabel = 'Promo & Diskon';
    } else if (type == 'transaction') {
      badgeColor = Colors.green.shade700;
      typeLabel = 'Transaksi';
    } else {
      badgeColor = AppTheme.primaryNavy;
      typeLabel = 'Informasi Maijek';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: badgeColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            typeLabel,
                            style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(notif['created_at']),
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                notif['title'] ?? '',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 280),
                child: SingleChildScrollView(
                  child: Text(
                    notif['message'] ?? '',
                    style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF374151)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryNavy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Tutup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
