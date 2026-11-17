import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/api_client.dart';
import 'auth_controller.dart';

class SchoolController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();

  // Status Fitur (disabled, coming_soon, active)
  var featureStatus = 'disabled'.obs;
  var isFeatureActive = false.obs;
  var isComingSoon = false.obs;
  var isLoading = false.obs;
  var isCalculating = false.obs;

  // Konfigurasi Tarif
  var motorBaseFare = 8000.obs;
  var motorBaseDistance = 3.0.obs;
  var motorPerKm = 2500.obs;
  var siblingExtraFare = 3000.obs;
  var discountWeeklyPercent = 10.0.obs;

  // Form Booking Data Siswa & Rute
  final studentNameController = TextEditingController();
  final studentSchoolController = TextEditingController();
  final studentGradeController = TextEditingController();
  final emergencyContactController = TextEditingController();
  final siblingNameController = TextEditingController();
  final notesController = TextEditingController();

  var pickupAddress = ''.obs;
  var pickupLat = 0.0.obs;
  var pickupLng = 0.0.obs;
  var schoolAddress = ''.obs;
  var schoolLat = 0.0.obs;
  var schoolLng = 0.0.obs;

  var vehicleType = 'motor'.obs; // 'motor' / 'mobil'
  var tripType = 'round_trip'.obs; // 'round_trip', 'departure_only', 'return_only'
  var packageType = 'weekly'.obs; // 'daily', '3_days', '4_days', 'weekly'
  var hasSibling = false.obs;
  var morningPickupTime = '06:30'.obs;
  var afternoonPickupTime = '14:00'.obs;
  var paymentMethod = 'wallet'.obs; // 'wallet' (MaiPay) atau 'cash'

  // Estimasi Harga Terkini
  var estimateData = Rxn<Map<String, dynamic>>();

  // Mitra Driver Sekolah
  var availableDrivers = <dynamic>[].obs;
  var selectedDriver = Rxn<dynamic>();
  var isLoadingDrivers = false.obs;

  // Langganan & Jadwal Hari Ini
  var subscriptions = <dynamic>[].obs;
  var todaySchedules = <dynamic>[].obs;
  var isLoadingSchedules = false.obs;

  // Diskusi Pra-Booking Chat
  var chatMessages = <dynamic>[].obs;
  final chatTextController = TextEditingController();
  var isSendingChat = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkFeatureStatus();
  }

  @override
  void onClose() {
    studentNameController.dispose();
    studentSchoolController.dispose();
    studentGradeController.dispose();
    emergencyContactController.dispose();
    siblingNameController.dispose();
    notesController.dispose();
    chatTextController.dispose();
    super.onClose();
  }

  /// Cek Status Saklar Layanan dari Server
  Future<void> checkFeatureStatus() async {
    try {
      final res = await ApiClient.get('/user/school/status');
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['data'] != null) {
          final data = body['data'];
          featureStatus.value = data['feature_status'] ?? 'disabled';
          isFeatureActive.value = (featureStatus.value == 'active');
          isComingSoon.value = (featureStatus.value == 'coming_soon');

          motorBaseFare.value = data['motor_base_fare'] ?? 8000;
          motorBaseDistance.value = (data['motor_base_distance'] as num?)?.toDouble() ?? 3.0;
          motorPerKm.value = data['motor_per_km'] ?? 2500;
          siblingExtraFare.value = data['sibling_extra_fare'] ?? 3000;
          discountWeeklyPercent.value = (data['discount_weekly_percent'] as num?)?.toDouble() ?? 10.0;
        }
      }
    } catch (_) {}
  }

  /// Hitung Estimasi Tarif Dinamis
  Future<void> calculateEstimate() async {
    if (pickupLat.value == 0.0 || schoolLat.value == 0.0) return;

    isCalculating.value = true;
    try {
      final res = await ApiClient.post('/user/school/estimate', {
        'pickup_lat': pickupLat.value,
        'pickup_lng': pickupLng.value,
        'school_lat': schoolLat.value,
        'school_lng': schoolLng.value,
        'vehicle_type': vehicleType.value,
        'trip_type': tripType.value,
        'package_type': packageType.value,
        'has_sibling': hasSibling.value ? 1 : 0,
      });

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['data'] != null) {
          estimateData.value = Map<String, dynamic>.from(body['data']);
        }
      }
    } catch (_) {
    } finally {
      isCalculating.value = false;
    }
  }

  /// Ambil Daftar Driver Khusus Sekolah
  Future<void> fetchAvailableDrivers() async {
    isLoadingDrivers.value = true;
    try {
      final res = await ApiClient.get('/user/school/drivers?vehicle_type=${vehicleType.value}');
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['data'] != null) {
          availableDrivers.assignAll(body['data']);
        }
      }
    } catch (_) {
    } finally {
      isLoadingDrivers.value = false;
    }
  }

  /// Kirim Pemesanan Langganan Sekolah
  Future<bool> submitSubscription() async {
    if (studentNameController.text.trim().isEmpty) {
      Get.snackbar('Data Belum Lengkap', 'Silakan masukkan nama siswa terlebih dahulu.',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    }

    if (studentSchoolController.text.trim().isEmpty) {
      Get.snackbar('Data Belum Lengkap', 'Silakan masukkan nama sekolah tujuan.',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    }

    if (pickupAddress.value.isEmpty || schoolAddress.value.isEmpty) {
      Get.snackbar('Rute Belum Ditentukan', 'Silakan tentukan titik jemput dan titik sekolah.',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    }

    isLoading.value = true;
    try {
      final payload = {
        'student_name': studentNameController.text.trim(),
        'student_school': studentSchoolController.text.trim(),
        'student_grade': studentGradeController.text.trim(),
        'parent_phone': _authController.userData['phone'] ?? '',
        'emergency_contact': emergencyContactController.text.trim(),
        'pickup_address': pickupAddress.value,
        'pickup_lat': pickupLat.value,
        'pickup_lng': pickupLng.value,
        'school_address': schoolAddress.value,
        'school_lat': schoolLat.value,
        'school_lng': schoolLng.value,
        'vehicle_type': vehicleType.value,
        'trip_type': tripType.value,
        'package_type': packageType.value,
        'has_sibling': hasSibling.value ? 1 : 0,
        'sibling_name': hasSibling.value ? siblingNameController.text.trim() : null,
        'morning_pickup_time': '${morningPickupTime.value}:00',
        'afternoon_pickup_time': '${afternoonPickupTime.value}:00',
        'driver_id': selectedDriver.value != null ? selectedDriver.value['driver_id'] : null,
        'notes': notesController.text.trim(),
        'payment_method': paymentMethod.value,
      };

      final res = await ApiClient.post('/user/school/subscribe', payload);
      final body = jsonDecode(res.body);

      if (res.statusCode == 201 || res.statusCode == 200) {
        Get.snackbar(
          'Berhasil Dipesan! 🎉',
          body['message'] ?? 'Paket langganan Mai School berhasil dibuat.',
          backgroundColor: const Color(0xFF059669),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        fetchSubscriptions();
        fetchTodaySchedules();
        return true;
      } else {
        Get.snackbar('Gagal Memesan', body['message'] ?? 'Terjadi kesalahan saat memproses booking.',
            backgroundColor: Colors.redAccent, colorText: Colors.white);
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Koneksi gagal: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Ambil Riwayat Langganan Saya
  Future<void> fetchSubscriptions() async {
    try {
      final res = await ApiClient.get('/user/school/subscriptions');
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['data'] != null) {
          subscriptions.assignAll(body['data']);
        }
      }
    } catch (_) {}
  }

  /// Ambil Jadwal Penjemputan Hari Ini
  Future<void> fetchTodaySchedules() async {
    isLoadingSchedules.value = true;
    try {
      final res = await ApiClient.get('/user/school/today');
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['data'] != null) {
          todaySchedules.assignAll(body['data']);
        }
      }
    } catch (_) {
    } finally {
      isLoadingSchedules.value = false;
    }
  }

  /// Ajukan Izin Sakit / Libur
  Future<bool> requestSickLeave(int scheduleId, String reason) async {
    try {
      final res = await ApiClient.post('/user/school/sick-leave/$scheduleId', {
        'notes': reason,
      });
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        Get.snackbar('Izin Berhasil Diajukan', body['message'] ?? 'Driver telah diberitahu.',
            backgroundColor: const Color(0xFF059669), colorText: Colors.white);
        fetchTodaySchedules();
        return true;
      } else {
        Get.snackbar('Gagal', body['message'] ?? 'Tidak dapat mengajukan izin.',
            backgroundColor: Colors.redAccent, colorText: Colors.white);
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal memproses izin: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    }
  }

  /// Ambil Percakapan Pra-Booking dengan Driver
  Future<void> fetchInquiries(int driverId) async {
    try {
      final res = await ApiClient.get('/user/school/inquiries/$driverId');
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['data'] != null) {
          chatMessages.assignAll(body['data']);
        }
      }
    } catch (_) {}
  }

  /// Kirim Pesan Pra-Booking ke Driver
  Future<void> sendInquiry(int driverId, {int? subscriptionId}) async {
    final text = chatTextController.text.trim();
    if (text.isEmpty) return;

    isSendingChat.value = true;
    try {
      final res = await ApiClient.post('/user/school/inquiry', {
        'driver_id': driverId,
        'subscription_id': subscriptionId,
        'message': text,
      });

      if (res.statusCode == 201 || res.statusCode == 200) {
        chatTextController.clear();
        fetchInquiries(driverId);
      }
    } catch (_) {
    } finally {
      isSendingChat.value = false;
    }
  }
}
