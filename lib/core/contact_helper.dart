import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'theme.dart';
import 'api_client.dart';

class ContactHelper {
  /// Normalisasi nomor ke format internasional WhatsApp (628...)
  static String normalizeWhatsAppNumber(String? phone) {
    if (phone == null || phone.isEmpty) return '';
    String clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.startsWith('0')) {
      return '62${clean.substring(1)}';
    } else if (clean.startsWith('8')) {
      return '62$clean';
    }
    return clean;
  }

  /// Format nomor untuk tampilan visual pengguna (+62 812-3456-7890)
  static String formatDisplayPhone(String? phone) {
    if (phone == null || phone.isEmpty) return '-';
    String wa = normalizeWhatsAppNumber(phone);
    if (wa.startsWith('62') && wa.length >= 10) {
      String prefix = '+62';
      String part1 = wa.substring(2, 2 + (wa.length > 5 ? 3 : wa.length - 2));
      String part2 = wa.length > 5 ? wa.substring(5, (wa.length > 9 ? 9 : wa.length)) : '';
      String part3 = wa.length > 9 ? wa.substring(9) : '';
      return '$prefix $part1-$part2${part3.isNotEmpty ? '-$part3' : ''}';
    }
    return phone;
  }

  /// Membuka aplikasi WhatsApp dengan pesan pembuka otomatis
  static Future<void> openWhatsApp({
    required String? phone,
    String? name,
    String? orderId,
    String? customMessage,
  }) async {
    if (phone == null || phone.trim().isEmpty) {
      Get.snackbar(
        'Nomor Tidak Tersedia',
        'Nomor WhatsApp belum terdaftar untuk kontak ini.',
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    String waNumber = normalizeWhatsAppNumber(phone);
    if (waNumber.isEmpty) {
      Get.snackbar(
        'Format Tidak Valid',
        'Format nomor WhatsApp tidak valid.',
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return;
    }

    String text = customMessage ??
        'Halo ${name != null && name.isNotEmpty ? name : 'Driver'}, saya pemesan Maijek${orderId != null && orderId.isNotEmpty ? ' (Order #$orderId)' : ''}. Mau konfirmasi posisi saat ini ya Pak/Bu, terima kasih.';

    final Uri url = Uri.parse('https://wa.me/$waNumber?text=${Uri.encodeComponent(text)}');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar(
          'Gagal Membuka WhatsApp',
          'Pastikan aplikasi WhatsApp terpasang di ponsel Anda.',
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Terjadi kesalahan saat membuka WhatsApp: $e',
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    }
  }

  /// Melakukan panggilan telepon langsung (GSM / Pulsa Seluler)
  static Future<void> makePhoneCall(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      Get.snackbar(
        'Nomor Tidak Tersedia',
        'Nomor telepon belum terdaftar untuk kontak ini.',
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    String clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri url = Uri.parse('tel:$clean');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar(
          'Gagal Memanggil',
          'Tidak dapat membuka dialer telepon di perangkat Anda.',
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Terjadi kesalahan saat memanggil: $e',
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    }
  }

  /// Menampilkan modal bottom sheet interaktif pilihan kontak (Chat App, WhatsApp, Telepon)
  static void showContactModal(
    BuildContext context, {
    required String name,
    required String? phone,
    String? role = 'Driver',
    String? photoUrl,
    String? orderId,
    VoidCallback? onChatApp,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Header info
              Row(
                children: [
                  ClipOval(
                    child: Image.network(
                      ApiClient.getImageUrl(photoUrl),
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 52,
                        height: 52,
                        color: Colors.grey.shade200,
                        child: Icon(
                          role == 'Restoran' ? Icons.restaurant : Icons.person,
                          color: AppTheme.primaryBlue,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textMain,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$role • ${formatDisplayPhone(phone)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Action 1: Chat Aplikasi (Jika disediakan)
              if (onChatApp != null)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.chat_bubble_outline, color: AppTheme.primaryBlue, size: 24),
                  ),
                  title: const Text(
                    'Chat di Aplikasi',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  subtitle: const Text('Kirim pesan teks langsung di aplikasi Maijek', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(ctx);
                    onChatApp();
                  },
                ),

              // Action 2: Chat via WhatsApp
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.chat, color: Color(0xFF25D366), size: 24),
                ),
                title: const Text(
                  'WhatsApp',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                subtitle: const Text('Kirim pesan cepat via aplikasi WhatsApp', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  Navigator.pop(ctx);
                  openWhatsApp(phone: phone, name: name, orderId: orderId);
                },
              ),

              // Action 3: Panggilan Telepon (GSM)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.phone_in_talk, color: Colors.blue.shade700, size: 24),
                ),
                title: const Text(
                  'Panggilan Telepon (GSM)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                subtitle: const Text('Hubungi langsung nomor ponsel driver melalui pulsa seluler', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  Navigator.pop(ctx);
                  makePhoneCall(phone);
                },
              ),

              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Batal', style: TextStyle(color: Colors.grey, fontSize: 14)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Membagikan detail keamanan perjalanan ke WhatsApp keluarga / teman
  static void shareTripViaWhatsApp({
    required BuildContext context,
    required String serviceName,
    required String? orderId,
    required String? driverName,
    required String? vehiclePlate,
    required String? vehicleType,
    String? vehicleBrand,
    dynamic vehicleCapacity,
    required String? pickupAddress,
    required String? dropoffAddress,
    required String? statusText,
    required String? etaText,
  }) {
    final String cleanDriver = (driverName != null && driverName.trim().isNotEmpty) ? driverName : 'Mitra Pengemudi';
    final String cleanPlate = (vehiclePlate != null && vehiclePlate.trim().isNotEmpty) ? vehiclePlate.trim() : '';
    final String cleanBrand = (vehicleBrand != null && vehicleBrand.trim().isNotEmpty) ? vehicleBrand.trim() : '';
    final String cleanCap = (vehicleCapacity != null && vehicleCapacity.toString().isNotEmpty) ? '$vehicleCapacity Penumpang' : '';

    String vehicleLine = '';
    if (cleanBrand.isNotEmpty || cleanPlate.isNotEmpty) {
      final List<String> vParts = [];
      if (cleanBrand.isNotEmpty) vParts.add(cleanBrand);
      if (cleanPlate.isNotEmpty) vParts.add('[$cleanPlate]');
      if (cleanCap.isNotEmpty) vParts.add('($cleanCap)');
      vehicleLine = '\n🚘 *Kendaraan:* ${vParts.join(' ')}';
    }

    final String cleanPickup = (pickupAddress != null && pickupAddress.trim().isNotEmpty) ? pickupAddress : '-';
    final String cleanDropoff = (dropoffAddress != null && dropoffAddress.trim().isNotEmpty) ? dropoffAddress : '-';
    final String cleanStatus = (statusText != null && statusText.trim().isNotEmpty) ? statusText : 'Dalam Perjalanan';
    final String cleanEta = (etaText != null && etaText.trim().isNotEmpty) ? '⏱️ *Estimasi Tiba:* $etaText\n' : '';
    final String cleanOrderId = (orderId != null && orderId.trim().isNotEmpty) ? ' #$orderId' : '';

    final String message = 
'''🛡️ *INFORMASI PERJALANAN MAIJEK*
Halo! Saya sedang dalam perjalanan menggunakan aplikasi *Maijek*:

🛵 *Layanan:* $serviceName$cleanOrderId
👤 *Pengemudi:* $cleanDriver$vehicleLine
📍 *Titik Jemput:* $cleanPickup
🏁 *Tujuan:* $cleanDropoff
🚦 *Status:* $cleanStatus
$cleanEta
Perjalanan ini terpantau secara real-time demi keamanan dan kenyamanan bersama. Pesan dikirim dari aplikasi resmi Maijek.''';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
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
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.shield_rounded, color: Colors.teal.shade700, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bagikan Perjalanan',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Kirim detail rute & pengemudi ke keluarga / teman',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Preview Card Teks
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryNavy.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          serviceName,
                          style: const TextStyle(color: AppTheme.primaryNavy, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        cleanStatus,
                        style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          cleanBrand.isNotEmpty ? '$cleanDriver • $cleanBrand ($cleanPlate)' : (cleanPlate.isNotEmpty ? '$cleanDriver ($cleanPlate)' : cleanDriver),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.navigation, size: 16, color: Colors.redAccent),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(cleanDropoff, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                      ),
                    ],
                  ),
                  if (cleanEta.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 16, color: Colors.teal),
                        const SizedBox(width: 6),
                        Text(cleanEta.replaceAll('⏱️', '').replaceAll('*', '').trim(), style: TextStyle(fontSize: 12, color: Colors.teal.shade800, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Tombol 1: Buka WhatsApp
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.chat_rounded, size: 20),
                label: const Text('Kirim ke WhatsApp Keluarga', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 1,
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final Uri waScheme = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(message)}');
                  final Uri waWeb = Uri.parse('https://api.whatsapp.com/send?text=${Uri.encodeComponent(message)}');
                  try {
                    if (await canLaunchUrl(waScheme)) {
                      await launchUrl(waScheme, mode: LaunchMode.externalApplication);
                    } else if (await canLaunchUrl(waWeb)) {
                      await launchUrl(waWeb, mode: LaunchMode.externalApplication);
                    } else {
                      Clipboard.setData(ClipboardData(text: message));
                      Get.snackbar(
                        'Informasi Disalin',
                        'WhatsApp tidak ditemukan. Detail perjalanan telah disalin ke clipboard!',
                        backgroundColor: AppTheme.primaryNavy,
                        colorText: Colors.white,
                        snackPosition: SnackPosition.TOP,
                      );
                    }
                  } catch (e) {
                    Clipboard.setData(ClipboardData(text: message));
                    Get.snackbar(
                      'Informasi Disalin',
                      'Detail perjalanan telah disalin ke clipboard!',
                      backgroundColor: AppTheme.primaryNavy,
                      colorText: Colors.white,
                      snackPosition: SnackPosition.TOP,
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 10),
            // Tombol 2: Salin Pesan
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Salin Teks Perjalanan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryNavy,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Clipboard.setData(ClipboardData(text: message));
                  Get.snackbar(
                    '🛡️ Teks Perjalanan Disalin!',
                    'Detail perjalanan siap Anda kirimkan ke keluarga/teman melalui pesan SMS atau aplikasi chat.',
                    backgroundColor: AppTheme.primaryNavy,
                    colorText: Colors.white,
                    snackPosition: SnackPosition.TOP,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
