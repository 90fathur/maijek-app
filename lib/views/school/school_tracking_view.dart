import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/school_controller.dart';
import '../../core/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class SchoolTrackingView extends StatefulWidget {
  const SchoolTrackingView({super.key});

  @override
  State<SchoolTrackingView> createState() => _SchoolTrackingViewState();
}

class _SchoolTrackingViewState extends State<SchoolTrackingView> {
  final SchoolController controller = Get.find<SchoolController>();

  @override
  void initState() {
    super.initState();
    controller.fetchTodaySchedules();
  }

  void _showSickLeaveDialog(int scheduleId, String studentName) {
    final reasonCtrl = TextEditingController(text: 'Sakit / Kurang Enak Badan');

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.sick_rounded, color: Color(0xFF7C3AED), size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Izin Tidak Masuk: $studentName',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Dengan mengajukan izin, driver tidak akan datang menjemput dan kuota perjalanan ini tidak akan hangus.',
                style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: reasonCtrl,
                decoration: InputDecoration(
                  labelText: 'Alasan Izin',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Get.back();
                        await controller.requestSickLeave(scheduleId, reasonCtrl.text);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
                      child: const Text('Kirim Izin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Jadwal & Pelacakan Hari Ini',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => controller.fetchTodaySchedules(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoadingSchedules.value) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF059669)));
        }

        final schedules = controller.todaySchedules;

        if (schedules.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_available_rounded, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'Tidak Ada Jadwal Hari Ini',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tidak ada trip penjemputan anak sekolah yang terjadwal untuk hari ini.',
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
          itemCount: schedules.length,
          itemBuilder: (context, index) {
            final s = schedules[index];
            final status = s['status'] ?? 'scheduled';
            final isDeparture = s['trip_type'] == 'departure';
            final scheduledTime = s['scheduled_time'] != null ? s['scheduled_time'].toString().substring(0, 5) : '-';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sesi & Status Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDeparture ? const Color(0xFFEFF6FF) : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isDeparture ? Icons.wb_sunny_rounded : Icons.wb_twilight_rounded,
                              size: 15,
                              color: isDeparture ? const Color(0xFF2563EB) : const Color(0xFFD97706),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isDeparture ? 'Antar Pagi • $scheduledTime WITA' : 'Jemput Pulang • $scheduledTime WITA',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDeparture ? const Color(0xFF2563EB) : const Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusPill(status),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Info Siswa & Sekolah
                  Text(
                    s['student_name'] ?? 'Siswa',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textMain),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${s['student_school']} (${s['student_grade'] ?? ''})',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                  // Driver Info Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFF059669),
                          child: const Icon(Icons.person, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s['driver_name'] ?? 'Mitra Driver',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                'Plat: ${s['vehicle_plate'] ?? '-'}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        if (s['driver_phone'] != null)
                          IconButton(
                            icon: const Icon(Icons.call_rounded, color: Color(0xFF059669), size: 20),
                            onPressed: () => launchUrl(Uri.parse('tel:${s['driver_phone']}')),
                          ),
                        if (s['driver_phone'] != null)
                          IconButton(
                            icon: const Icon(Icons.chat_rounded, color: Color(0xFF2563EB), size: 20),
                            onPressed: () {
                              final phone = s['driver_phone'].toString().replaceAll(RegExp(r'[^0-9]'), '');
                              launchUrl(Uri.parse('https://wa.me/$phone'), mode: LaunchMode.externalApplication);
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Alur Perjalanan (Timeline)
                  _buildTimelineStatus(status),

                  // Tombol Izin Sakit jika Belum Jalan
                  if (status == 'scheduled' || status == 'otw') ...[
                    const Divider(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _showSickLeaveDialog((s['id'] as num).toInt(), s['student_name'] ?? 'Anak'),
                        icon: const Icon(Icons.sick_rounded, color: Color(0xFF7C3AED), size: 16),
                        label: const Text(
                          'Ajukan Izin Sakit / Libur Hari Ini',
                          style: TextStyle(color: Color(0xFF7C3AED), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
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

    if (status == 'completed') {
      bg = const Color(0xFFECFDF5);
      fg = const Color(0xFF059669);
      label = 'Sampai Tujuan';
    } else if (status == 'in_trip') {
      bg = const Color(0xFFEFF6FF);
      fg = const Color(0xFF2563EB);
      label = 'Di Jalan';
    } else if (status == 'arrived_pickup') {
      bg = const Color(0xFFFFFBEB);
      fg = const Color(0xFFD97706);
      label = 'Tiba di Rumah';
    } else if (status == 'otw') {
      bg = const Color(0xFFEFF6FF);
      fg = const Color(0xFF2563EB);
      label = 'OTW Jemput';
    } else if (status == 'skipped_sick') {
      bg = const Color(0xFFFAF5FF);
      fg = const Color(0xFF7C3AED);
      label = 'Izin Sakit';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  Widget _buildTimelineStatus(String status) {
    final steps = [
      {'key': 'otw', 'label': 'OTW Jemput'},
      {'key': 'arrived_pickup', 'label': 'Sampai di Titik'},
      {'key': 'in_trip', 'label': 'Mengantar'},
      {'key': 'completed', 'label': 'Tiba Aman'},
    ];

    int currentStepIndex = -1;
    if (status == 'otw') {
      currentStepIndex = 0;
    } else if (status == 'arrived_pickup') {
      currentStepIndex = 1;
    } else if (status == 'in_trip') {
      currentStepIndex = 2;
    } else if (status == 'completed') {
      currentStepIndex = 3;
    }

    return Row(
      children: List.generate(steps.length, (idx) {
        final isDone = idx <= currentStepIndex;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 3,
                      color: idx == 0 ? Colors.transparent : (isDone ? const Color(0xFF059669) : Colors.grey.shade300),
                    ),
                  ),
                  CircleAvatar(
                    radius: 7,
                    backgroundColor: isDone ? const Color(0xFF059669) : Colors.grey.shade300,
                  ),
                  Expanded(
                    child: Container(
                      height: 3,
                      color: idx == steps.length - 1 ? Colors.transparent : (idx < currentStepIndex ? const Color(0xFF059669) : Colors.grey.shade300),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                steps[idx]['label']!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                  color: isDone ? const Color(0xFF059669) : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }),
    );
  }
}
