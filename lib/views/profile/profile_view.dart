import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme.dart';
import '../../core/contact_helper.dart';
import '../../controllers/auth_controller.dart';
import 'edit_profile_view.dart';
import 'cs_chat_view.dart';
import 'legal_view.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Profil Saya', style: TextStyle(color: AppTheme.textMain, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppTheme.textMain),
      ),
      body: Obx(() {
        final user = authController.userData;
        String userName = (user['name'] ?? 'Pengguna Maijek').toString();
        String userPhone = (user['phone'] ?? '').toString();
        String? userEmail = user['email']?.toString();
        int coins = int.tryParse(user['coins']?.toString() ?? '0') ?? 0;
        int nameChangesCount = int.tryParse(user['name_changes_count']?.toString() ?? '0') ?? 0;
        bool canChangeName = user['can_change_name'] != false && nameChangesCount < 1;

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            // 1. Avatar & Info Header
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNavy,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.accentGold, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryNavy.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: (user['photo_url'] != null && user['photo_url'].toString().isNotEmpty)
                          ? (user['photo_url'].toString().startsWith('http')
                              ? Image.network(
                                  user['photo_url'].toString(),
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => const Icon(Icons.person, color: Colors.white, size: 50),
                                )
                              : Image.file(
                                  File(user['photo_url'].toString()),
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => const Icon(Icons.person, color: Colors.white, size: 50),
                                ))
                          : const Icon(Icons.person, color: Colors.white, size: 50),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => Get.to(() => const EditProfileView()),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.accentGold, width: 1.5),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
                          ],
                        ),
                        child: const Icon(Icons.edit, color: AppTheme.primaryNavy, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              userName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textMain),
            ),
            const SizedBox(height: 6),

            // Nomor HP Pill Badge Utama di Header
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF059669).withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.phone_android_rounded, size: 16, color: Color(0xFF059669)),
                    const SizedBox(width: 6),
                    Text(
                      userPhone.isNotEmpty && userPhone != '-'
                          ? ContactHelper.formatDisplayPhone(userPhone)
                          : 'Nomor HP belum diatur',
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF065F46), letterSpacing: 0.3),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Terverifikasi', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                    ),
                  ],
                ),
              ),
            ),
            if (userEmail != null && userEmail.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                userEmail,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
              ),
            ],
            const SizedBox(height: 12),

            // Badge Koin Maijek
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.goldLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars_rounded, color: AppTheme.goldDark, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Koin Reward: $coins',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.goldDark),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Informasi Akun & Keamanan
            _buildSectionHeader('Informasi Akun'),
            _buildCardGroup([
              _buildInfoTile(
                icon: Icons.person_outline_rounded,
                iconColor: AppTheme.primaryNavy,
                label: 'Nama Lengkap Akun',
                value: userName,
                badgeText: canChangeName ? 'Bisa Diubah (1x)' : 'Nama Terkunci',
                badgeColor: canChangeName ? AppTheme.primaryBlue : Colors.orange.shade800,
                badgeBg: canChangeName ? AppTheme.primaryBlue.withValues(alpha: 0.1) : Colors.orange.shade50,
                subtitle: canChangeName
                    ? 'Nama akun hanya dapat diubah 1 kali saja'
                    : 'Nama telah diubah dan terkunci secara permanen',
              ),
              _buildDivider(),
              _buildInfoTile(
                icon: Icons.phone_android_rounded,
                iconColor: const Color(0xFF059669),
                label: 'Nomor Handphone Terdaftar',
                value: userPhone.isNotEmpty && userPhone != '-' ? ContactHelper.formatDisplayPhone(userPhone) : '-',
                badgeText: 'WhatsApp Aktif',
                badgeColor: const Color(0xFF059669),
                badgeBg: const Color(0xFFECFDF5),
                subtitle: 'Digunakan untuk login akun & komunikasi pesanan',
              ),
              if (userEmail != null && userEmail.trim().isNotEmpty) ...[
                _buildDivider(),
                _buildInfoTile(
                  icon: Icons.email_outlined,
                  iconColor: Colors.deepPurple,
                  label: 'Alamat Email',
                  value: userEmail,
                ),
              ],
            ]),
            const SizedBox(height: 20),

            // Kategori 1: Akun & Aktivitas
            _buildSectionHeader('Menu Profil'),
            _buildCardGroup([
              _buildMenuTile(
                icon: Icons.edit_note_rounded,
                iconColor: AppTheme.primaryBlue,
                title: 'Edit Data Profil',
                subtitle: canChangeName
                    ? 'Ubah Nama (1x), Foto Profil & Email'
                    : 'Ubah Foto Profil & Email (Nama Sudah Terkunci)',
                onTap: () => Get.to(() => const EditProfileView()),
              ),
              _buildDivider(),
              _buildMenuTile(
                icon: Icons.history,
                iconColor: Colors.teal,
                title: 'Riwayat Pesanan',
                subtitle: 'Daftar perjalanan & pesanan MaiFood Anda',
                onTap: () => Get.toNamed('/history'),
              ),
            ]),

            const SizedBox(height: 20),

            // Kategori 2: Pusat Bantuan & Dukungan
            _buildSectionHeader('Bantuan & Layanan Pelanggan'),
            _buildCardGroup([
              _buildMenuTile(
                icon: Icons.support_agent,
                iconColor: AppTheme.primaryBlue,
                title: 'Pusat Bantuan (Chat CS)',
                subtitle: 'Konsultasi keluhan langsung di aplikasi',
                onTap: () => Get.to(() => const CsChatView()),
              ),
              _buildDivider(),
              _buildMenuTile(
                icon: Icons.chat,
                iconColor: const Color(0xFF25D366),
                title: 'WhatsApp CS Resmi (24/7)',
                subtitle: 'Hubungi admin resmi Maijek (+62 851-1722-8559)',
                onTap: () {
                  ContactHelper.openWhatsApp(
                    phone: '085117228559',
                    name: 'CS Maijek',
                    customMessage: 'Halo Tim Layanan Maijek, saya $userName ($userPhone). Saya butuh bantuan terkait aplikasi Maijek.',
                  );
                },
              ),
            ]),

            const SizedBox(height: 20),

            // Kategori 3: Legal & Keamanan (Play Store Compliance)
            _buildSectionHeader('Ketentuan & Privasi (Legal)'),
            _buildCardGroup([
              _buildMenuTile(
                icon: Icons.gavel_rounded,
                iconColor: Colors.deepPurple,
                title: 'Syarat & Ketentuan Layanan',
                subtitle: 'Aturan & ketentuan penggunaan layanan Maijek',
                onTap: () => Get.to(() => const LegalView(type: LegalType.terms)),
              ),
              _buildDivider(),
              _buildMenuTile(
                icon: Icons.security_rounded,
                iconColor: Colors.indigo,
                title: 'Kebijakan Privasi (Privacy Policy)',
                subtitle: 'Perlindungan data pribadi & izin lokasi GPS',
                onTap: () => Get.to(() => const LegalView(type: LegalType.privacy)),
              ),
              _buildDivider(),
              _buildMenuTile(
                icon: Icons.delete_forever_rounded,
                iconColor: Colors.red.shade700,
                title: 'Hapus Akun Saya',
                subtitle: 'Penghapusan data akun (Sesuai Google Play)',
                textColor: Colors.red.shade700,
                onTap: () => _confirmDeleteAccount(context, authController),
              ),
            ]),

            const SizedBox(height: 28),

            // Tombol Keluar Akun
            OutlinedButton.icon(
              onPressed: () {
                Get.defaultDialog(
                  title: 'Keluar Akun',
                  titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMain),
                  middleText: 'Apakah Anda yakin ingin keluar dari akun ini?',
                  textConfirm: 'Ya, Keluar',
                  textCancel: 'Batal',
                  confirmTextColor: Colors.white,
                  buttonColor: Colors.red,
                  cancelTextColor: Colors.grey.shade700,
                  onConfirm: () {
                    Get.back();
                    authController.logout();
                  },
                );
              },
              icon: const Icon(Icons.logout, color: Colors.red, size: 20),
              label: const Text('Keluar dari Akun', style: TextStyle(color: Colors.red, fontSize: 15, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 24),

            // Footer Versi Aplikasi
            Center(
              child: Column(
                children: [
                  Text(
                    'Maijek Indonesia v1.0.13',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '© 2026 CV Mandarlink Group • Polewali Mandar',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      }),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    String? badgeText,
    Color? badgeColor,
    Color? badgeBg,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ],
            ),
          ),
          if (badgeText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeBg ?? Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: (badgeColor ?? Colors.grey).withValues(alpha: 0.3)),
              ),
              child: Text(
                badgeText,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor ?? Colors.grey.shade800),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppTheme.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: textColor ?? AppTheme.textMain,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            )
          : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 64, endIndent: 16, color: Colors.grey.shade200);
  }

  void _confirmDeleteAccount(BuildContext context, AuthController authController) {
    Get.defaultDialog(
      title: 'Hapus Akun Permanen?',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 18),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 40),
            ),
            const SizedBox(height: 14),
            const Text(
              'Tindakan ini bersifat permanen dan tidak dapat dibatalkan.\n\n'
              'Seluruh data pribadi, saldo koin, dan riwayat pesanan Anda akan dihapus dari server Maijek sesuai dengan Kebijakan Perlindungan Data (Google Play Data Safety).',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.5),
            ),
          ],
        ),
      ),
      textConfirm: 'Ya, Hapus Akun Saya',
      textCancel: 'Batal',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      cancelTextColor: Colors.grey.shade700,
      onConfirm: () {
        Get.back();
        authController.deleteAccount();
      },
    );
  }
}
