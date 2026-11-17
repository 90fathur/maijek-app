import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/school_controller.dart';
import '../../core/theme.dart';
import 'school_driver_picker_view.dart';
import '../home/location_search_view.dart';
import 'package:intl/intl.dart';

class SchoolBookingView extends StatefulWidget {
  const SchoolBookingView({super.key});

  @override
  State<SchoolBookingView> createState() => _SchoolBookingViewState();
}

class _SchoolBookingViewState extends State<SchoolBookingView> {
  final SchoolController controller = Get.find<SchoolController>();
  final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    controller.fetchAvailableDrivers();
  }

  Future<void> _selectTime(BuildContext context, bool isMorning) async {
    final currentStr = isMorning ? controller.morningPickupTime.value : controller.afternoonPickupTime.value;
    final parts = currentStr.split(':');
    final initialTime = TimeOfDay(hour: int.tryParse(parts[0]) ?? 6, minute: int.tryParse(parts[1]) ?? 30);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF059669),
              onPrimary: Colors.white,
              onSurface: AppTheme.textMain,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      if (isMorning) {
        controller.morningPickupTime.value = formatted;
      } else {
        controller.afternoonPickupTime.value = formatted;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Pemesanan Mai School',
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
        final estimate = controller.estimateData.value;
        final finalFare = estimate != null ? (estimate['final_fare'] as num?)?.toInt() ?? 0 : 0;
        final grossFare = estimate != null ? (estimate['gross_fare'] as num?)?.toInt() ?? 0 : 0;
        final discount = estimate != null ? (estimate['discount_amount'] as num?)?.toInt() ?? 0 : 0;
        final avgDaily = estimate != null ? (estimate['average_daily_cost'] as num?)?.toInt() ?? 0 : 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Data Siswa
              _buildSectionCard(
                title: 'Data Siswa & Sekolah',
                icon: Icons.school_rounded,
                child: Column(
                  children: [
                    _buildTextField(
                      controller: controller.studentNameController,
                      label: 'Nama Lengkap Anak',
                      hint: 'Contoh: Rizky Pratama',
                      icon: Icons.person_rounded,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildTextField(
                            controller: controller.studentSchoolController,
                            label: 'Sekolah Tujuan',
                            hint: 'SDN 1 Polewali',
                            icon: Icons.location_city_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: _buildTextField(
                            controller: controller.studentGradeController,
                            label: 'Kelas',
                            hint: 'Kelas 2 SD',
                            icon: Icons.grade_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: controller.emergencyContactController,
                      label: 'Kontak Darurat Tambahan (Wali/Ayah)',
                      hint: '0812xxxxxxxx',
                      icon: Icons.phone_callback_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),

                    // Opsi Bawa Saudara
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Bawa Kakak/Adik Sekaligus', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text('Hemat +Rp 3.000/trip (bukan 2x lipat)', style: TextStyle(fontSize: 11, color: Color(0xFF059669))),
                                ],
                              ),
                              Switch(
                                value: controller.hasSibling.value,
                                activeThumbColor: const Color(0xFF059669),
                                onChanged: (val) {
                                  controller.hasSibling.value = val;
                                  controller.calculateEstimate();
                                },
                              ),
                            ],
                          ),
                          if (controller.hasSibling.value) ...[
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: controller.siblingNameController,
                              label: 'Nama Kakak/Adik',
                              hint: 'Contoh: Anisa Putri',
                              icon: Icons.people_outline_rounded,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Rute Antar Jemput
              _buildSectionCard(
                title: 'Rute Perjalanan',
                icon: Icons.alt_route_rounded,
                child: Column(
                  children: [
                    _buildLocationPickerTile(
                      isPickup: true,
                      title: 'Titip Jemput (Rumah)',
                      address: controller.pickupAddress.value.isEmpty ? 'Pilih Alamat Rumah' : controller.pickupAddress.value,
                      iconColor: const Color(0xFF10B981),
                      onTap: () async {
                        final result = await Get.to(() => const LocationSearchView(), arguments: 'pickup');
                        if (result != null && result is Map) {
                          controller.pickupAddress.value = result['address'] ?? '';
                          if (result['latLng'] != null) {
                            controller.pickupLat.value = (result['latLng'].latitude as num).toDouble();
                            controller.pickupLng.value = (result['latLng'].longitude as num).toDouble();
                          }
                          controller.calculateEstimate();
                        }
                      },
                    ),
                    const Divider(height: 20),
                    _buildLocationPickerTile(
                      isPickup: false,
                      title: 'Titik Antar (Gerbang Sekolah)',
                      address: controller.schoolAddress.value.isEmpty ? 'Pilih Lokasi Sekolah' : controller.schoolAddress.value,
                      iconColor: const Color(0xFFEF4444),
                      onTap: () async {
                        final result = await Get.to(() => const LocationSearchView(), arguments: 'dropoff');
                        if (result != null && result is Map) {
                          controller.schoolAddress.value = result['address'] ?? '';
                          if (result['latLng'] != null) {
                            controller.schoolLat.value = (result['latLng'].latitude as num).toDouble();
                            controller.schoolLng.value = (result['latLng'].longitude as num).toDouble();
                          }
                          controller.calculateEstimate();
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Durasi Paket & Jam Jemput
              _buildSectionCard(
                title: 'Paket & Jam Penjemputan',
                icon: Icons.calendar_month_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pilih Durasi Paket:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildPackageTypeChip('1 Hari', 'daily'),
                        const SizedBox(width: 8),
                        _buildPackageTypeChip('3 Hari', '3_days'),
                        const SizedBox(width: 8),
                        _buildPackageTypeChip('4 Hari', '4_days'),
                        const SizedBox(width: 8),
                        _buildPackageTypeChip('1 Minggu', 'weekly', badge: 'DISKON 10%'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Tipe Antar-Jemput:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildTripTypeChip('Pulang-Pergi (PP)', 'round_trip'),
                        const SizedBox(width: 8),
                        _buildTripTypeChip('Berangkat', 'departure_only'),
                        const SizedBox(width: 8),
                        _buildTripTypeChip('Pulang', 'return_only'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (controller.tripType.value != 'return_only')
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectTime(context, true),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Jam Berangkat', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.wb_sunny_rounded, color: Color(0xFFF59E0B), size: 18),
                                        const SizedBox(width: 6),
                                        Text('${controller.morningPickupTime.value} WITA', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (controller.tripType.value == 'round_trip') const SizedBox(width: 12),
                        if (controller.tripType.value != 'departure_only')
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectTime(context, false),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Jam Pulang', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.wb_twilight_rounded, color: Color(0xFFD97706), size: 18),
                                        const SizedBox(width: 6),
                                        Text('${controller.afternoonPickupTime.value} WITA', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Pilih Mitra Driver
              _buildSectionCard(
                title: 'Mitra Driver Pengantar',
                icon: Icons.person_pin_rounded,
                child: Column(
                  children: [
                    if (controller.selectedDriver.value != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: const Color(0xFF059669),
                              child: const Icon(Icons.person, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    controller.selectedDriver.value['name'] ?? 'Driver',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Plat: ${controller.selectedDriver.value['vehicle_plate']}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => Get.to(() => const SchoolDriverPickerView()),
                              child: const Text('Ganti', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_awesome, color: Color(0xFF2563EB)),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Pilihkan Driver Terbaik', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text('Sistem akan mencocokkan mitra terdekat & verified', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () => Get.to(() => const SchoolDriverPickerView()),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF059669)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Pilih Sendiri', style: TextStyle(color: Color(0xFF059669), fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 5. Ringkasan Tarif & Pembayaran
              _buildSectionCard(
                title: 'Rincian Pembayaran',
                icon: Icons.receipt_long_rounded,
                child: Column(
                  children: [
                    if (estimate != null) ...[
                      _buildReceiptRow('Jarak Rute (KM)', '${estimate['distance_km']} KM'),
                      _buildReceiptRow('Total Trip (${estimate['total_days']} Hari)', '${estimate['total_trips']} Kali Perjalanan'),
                      _buildReceiptRow('Tarif Normal', currencyFormat.format(grossFare)),
                      if (discount > 0)
                        _buildReceiptRow('Diskon Paket (${estimate['discount_percent']}%)', '- ${currencyFormat.format(discount)}', color: const Color(0xFF059669)),
                      const Divider(height: 18),
                      _buildReceiptRow('Total Bayar', currencyFormat.format(finalFare), isBold: true, fontSize: 16),
                      if (avgDaily > 0)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text('Rata-rata: ${currencyFormat.format(avgDaily)} / hari', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ),
                    ] else ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Pilih alamat rumah dan sekolah untuk melihat kalkulasi harga resmi.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        );
      }),
      bottomSheet: Obx(() {
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
              child: ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () async {
                        final success = await controller.submitSubscription();
                        if (success) {
                          Get.back();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: controller.isLoading.value
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'Konfirmasi & Pesan Paket',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF059669)),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textMain)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
        labelStyle: const TextStyle(fontSize: 12, color: Colors.grey),
        prefixIcon: Icon(icon, size: 18, color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF059669))),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
      ),
    );
  }

  Widget _buildLocationPickerTile({
    required bool isPickup,
    required String title,
    required String address,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(isPickup ? Icons.my_location_rounded : Icons.location_on_rounded, color: iconColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    address,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textMain),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageTypeChip(String label, String value, {String? badge}) {
    final isSelected = controller.packageType.value == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          controller.packageType.value = value;
          controller.calculateEstimate();
        },
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isSelected ? const Color(0xFF059669) : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? const Color(0xFF059669) : Colors.grey.shade700,
                ),
              ),
            ),
            if (badge != null)
              Positioned(
                top: -6,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(color: const Color(0xFFE11D48), borderRadius: BorderRadius.circular(4)),
                  child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripTypeChip(String label, String value) {
    final isSelected = controller.tripType.value == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          controller.tripType.value = value;
          controller.calculateEstimate();
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false, double fontSize = 13, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: fontSize, color: isBold ? AppTheme.textMain : Colors.grey.shade700, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color ?? AppTheme.textMain)),
        ],
      ),
    );
  }
}
