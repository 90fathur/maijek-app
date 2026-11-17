import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/school_controller.dart';
import '../../core/theme.dart';
import 'school_booking_view.dart';
import 'school_tracking_view.dart';
import 'school_subscriptions_view.dart';

class SchoolHomeView extends StatelessWidget {
  const SchoolHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SchoolController());

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Mai School',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryNavy,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '🎓 Antar Jemput Sekolah Aman',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Ketenangan Hati untuk\nAyah & Bunda Setiap Hari',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mitra driver tetap, pelacakan live GPS, dan foto bukti sampai di sekolah dengan selamat.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Banner Teaser jika Status "Coming Soon"
              if (controller.isComingSoon.value)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.access_time_filled_rounded, color: Color(0xFFD97706), size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Segera Hadir di Wilayah Anda!',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF92400E)),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Kami sedang menyiapkan armada terbaik untuk anak Anda. Nantikan peluncuran resminya!',
                              style: TextStyle(fontSize: 12, color: Color(0xFFB45309), height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Tombol Menu Cepat (Tracking & Riwayat)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: Icons.calendar_today_rounded,
                        title: 'Jadwal Hari Ini',
                        subtitle: 'Pantau antar-jemput',
                        color: const Color(0xFF0284C7),
                        bgColor: const Color(0xFFF0F9FF),
                        onTap: () => Get.to(() => const SchoolTrackingView()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: Icons.assignment_rounded,
                        title: 'Langganan Saya',
                        subtitle: 'Daftar paket aktif',
                        color: const Color(0xFF059669),
                        bgColor: const Color(0xFFECFDF5),
                        onTap: () => Get.to(() => const SchoolSubscriptionsView()),
                      ),
                    ),
                  ],
                ),
              ),

              // Keunggulan Layanan Mai School
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mengapa Memilih Mai School?',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureBenefitItem(
                      icon: Icons.person_pin_rounded,
                      title: '1 Driver Tetap (Dedicated Driver)',
                      desc: 'Anak diantar oleh driver yang sama setiap hari agar anak merasa nyaman dan akrab.',
                      color: const Color(0xFF2563EB),
                    ),
                    _buildFeatureBenefitItem(
                      icon: Icons.security_rounded,
                      title: 'Standar Keamanan Anak & Helm SNI',
                      desc: 'Driver dibekali helm anak ber-SNI dan diverifikasi rekam jejak berkendara yang aman.',
                      color: const Color(0xFF059669),
                    ),
                    _buildFeatureBenefitItem(
                      icon: Icons.camera_alt_rounded,
                      title: 'Foto Bukti Serah Terima Gerbang',
                      desc: 'Driver mengirimkan foto anak saat tiba di depan gerbang sekolah / guru piket.',
                      color: const Color(0xFFD97706),
                    ),
                    _buildFeatureBenefitItem(
                      icon: Icons.sick_rounded,
                      title: 'Fitur Izin Sakit (Jadwal Tidak Hangus)',
                      desc: 'Jika anak sakit mendadak, ajukan izin di aplikasi dan kuota trip otomatis dialihkan.',
                      color: const Color(0xFF7C3AED),
                    ),
                    _buildFeatureBenefitItem(
                      icon: Icons.discount_rounded,
                      title: 'Paket Fleksibel & Diskon Mingguan',
                      desc: 'Tersedia paket Harian, 3 Hari, hingga Mingguan dengan diskon hemat s/d 10%.',
                      color: const Color(0xFFE11D48),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        );
      }),
      bottomSheet: Obx(() {
        if (controller.isComingSoon.value) {
          return const SizedBox.shrink();
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => Get.to(() => const SchoolBookingView()),
                icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
                label: const Text(
                  'Pesan Langganan Sekolah',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureBenefitItem({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textMain)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
