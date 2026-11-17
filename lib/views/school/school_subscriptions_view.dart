import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/school_controller.dart';
import '../../core/theme.dart';
import 'school_tracking_view.dart';
import 'school_booking_view.dart';
import 'package:intl/intl.dart';

class SchoolSubscriptionsView extends StatefulWidget {
  const SchoolSubscriptionsView({super.key});

  @override
  State<SchoolSubscriptionsView> createState() => _SchoolSubscriptionsViewState();
}

class _SchoolSubscriptionsViewState extends State<SchoolSubscriptionsView> {
  final SchoolController controller = Get.find<SchoolController>();
  final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    controller.fetchSubscriptions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Langganan Sekolah Saya',
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
        final subs = controller.subscriptions;

        if (subs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.backpack_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum Ada Paket Langganan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Anda belum memiliki paket antar jemput anak sekolah yang aktif.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Get.to(() => const SchoolBookingView()),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669)),
                    child: const Text('Pesan Langganan Baru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: subs.length,
          itemBuilder: (context, index) {
            final s = subs[index];
            final status = s['status'] ?? 'active';
            final fare = (s['final_fare'] as num?)?.toInt() ?? 0;

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
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        s['subscription_code'] ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF059669)),
                      ),
                      _buildStatusPill(status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s['student_name'] ?? 'Siswa',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textMain),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s['student_school'] ?? 'Sekolah Tujuan',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Divider(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Biaya Paket', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          Text(
                            currencyFormat.format(fare),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textMain),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () => Get.to(() => const SchoolTrackingView()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        child: const Text('Jadwal Hari Ini', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
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

  Widget _buildStatusPill(String status) {
    Color bg = const Color(0xFFF1F5F9);
    Color fg = const Color(0xFF64748B);
    String label = status;

    if (status == 'active') {
      bg = const Color(0xFFECFDF5);
      fg = const Color(0xFF059669);
      label = 'Aktif';
    } else if (status == 'waiting_driver') {
      bg = const Color(0xFFFFFBEB);
      fg = const Color(0xFFD97706);
      label = 'Menunggu Driver';
    } else if (status == 'completed') {
      bg = const Color(0xFFEFF6FF);
      fg = const Color(0xFF2563EB);
      label = 'Selesai';
    } else if (status == 'cancelled') {
      bg = const Color(0xFFFEF2F2);
      fg = const Color(0xFFDC2626);
      label = 'Batal';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}
