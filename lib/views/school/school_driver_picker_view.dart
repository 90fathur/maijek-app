import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/school_controller.dart';
import '../../core/theme.dart';
import 'school_chat_view.dart';

class SchoolDriverPickerView extends StatelessWidget {
  const SchoolDriverPickerView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SchoolController>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Pilih Mitra Driver Tetap',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoadingDrivers.value) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF059669)));
        }

        final drivers = controller.availableDrivers;

        if (drivers.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off_rounded, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum Ada Driver Tersedia',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Mitra driver di rute ini sedang penuh atau belum siap. Sistem dapat mencocokkannya secara otomatis saat Anda konfirmasi booking.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: drivers.length,
          itemBuilder: (context, index) {
            final d = drivers[index];
            final bool isCar = (d['vehicle_type'] ?? '').toString().toLowerCase() == 'mobil' || (d['vehicle_type'] ?? '').toString().toLowerCase() == 'car';
            final bool hasHelmet = d['has_kids_helmet'] == true;
            final double rating = (d['rating_school'] as num?)?.toDouble() ?? 5.0;
            final int trips = (d['total_school_trips'] as num?)?.toInt() ?? 0;
            final isFemale = d['gender'] == 'female';

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: isFemale ? const Color(0xFFFCE7F3) : const Color(0xFFE0F2FE),
                        backgroundImage: d['photo'] != null ? NetworkImage(d['photo']) : null,
                        child: d['photo'] == null
                            ? Icon(Icons.person, color: isFemale ? const Color(0xFFDB2777) : const Color(0xFF0284C7), size: 30)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d['name'] ?? 'Mitra Pengemudi',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textMain),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Plat: ${d['vehicle_plate']} • ${d['vehicle_brand'] ?? 'Motor'}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                                const SizedBox(width: 4),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '($trips Trip Antar)',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (isCar)
                        _buildBadge(Icons.directions_car_rounded, 'Mobil (AC & Sabuk Pengaman)', const Color(0xFF0284C7), const Color(0xFFF0F9FF))
                      else if (hasHelmet)
                        _buildBadge(Icons.health_and_safety_rounded, 'Helm Anak SNI', const Color(0xFF059669), const Color(0xFFECFDF5)),
                      if (isFemale)
                        _buildBadge(Icons.face_3_rounded, 'Mitra Perempuan (Ibu)', const Color(0xFFDB2777), const Color(0xFFFDF2F8)),
                      _buildBadge(Icons.verified_user_rounded, 'Driver Terverifikasi', const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      // Tombol Chat Dulu
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Get.to(() => SchoolChatView(
                                  driverId: d['driver_id'],
                                  driverName: d['name'],
                                  driverPlate: d['vehicle_plate'],
                                ));
                          },
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                          label: const Text('Diskusi / Chat Dulu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F766E),
                            side: const BorderSide(color: Color(0xFF0F766E)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Tombol Pilih Driver
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            controller.selectedDriver.value = d;
                            Get.back();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            elevation: 0,
                          ),
                          child: const Text('Pilih Driver Ini', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildBadge(IconData icon, String label, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
