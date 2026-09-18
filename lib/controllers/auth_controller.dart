import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import '../core/api_client.dart';
import '../core/notification_service.dart';
import 'home_controller.dart';

class AuthController extends GetxController {
  var isLoading = false.obs;
  var isUpdatingProfile = false.obs;
  var isLogged = false.obs;
  var userData = {}.obs;
  var resendCountdown = 0.obs;
  Timer? _countdownTimer;

  void startResendTimer([int seconds = 60]) {
    _countdownTimer?.cancel();
    resendCountdown.value = seconds;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendCountdown.value > 0) {
        resendCountdown.value--;
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      isLogged.value = true;
      String? userStr = prefs.getString('user');
      if (userStr != null) {
        userData.value = jsonDecode(userStr);
      }
      fetchProfile(); // Sync balance & profile from server
      updateFcmToken(); // Refresh FCM token
      Get.offAllNamed('/home');
    }
  }

  Future<void> updateFcmToken() async {
    try {
      String? token = await NotificationService.getToken();
      if (token != null && token.isNotEmpty) {
        final res = await ApiClient.post('/user/fcm-token', {'fcm_token': token});
        debugPrint('[FCM] Token updated to server: ${res.statusCode}');
      } else {
        debugPrint('[FCM] Token was empty or null');
      }
    } catch (e) {
      debugPrint('[FCM] updateFcmToken error: $e');
    }
  }

  Future<String> _getDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? cachedId = prefs.getString('unique_app_device_id');
      if (cachedId != null && cachedId.isNotEmpty && cachedId != 'unknown_device_id') {
        return cachedId;
      }

      String newId = '';
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        String brand = androidInfo.brand.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
        String model = androidInfo.model.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
        int now = DateTime.now().millisecondsSinceEpoch;
        int rand = Random().nextInt(999999);
        newId = '${brand}_${model}_${now}_$rand';
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        newId = iosInfo.identifierForVendor ?? 'ios_${DateTime.now().millisecondsSinceEpoch}';
      } else {
        newId = 'dev_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}';
      }

      await prefs.setString('unique_app_device_id', newId);
      return newId;
    } catch (e) {
      print('Error getting device ID: $e');
    }

    String fallback = 'dev_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('unique_app_device_id', fallback);
    } catch (_) {}
    return fallback;
  }

  static String normalizePhone(String input) {
    String clean = input.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.startsWith('62')) {
      return '0${clean.substring(2)}';
    } else if (clean.startsWith('8')) {
      return '0$clean';
    }
    return clean;
  }

  Future<void> login(String phone) async {
    isLoading.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user');
      isLogged.value = false;
      if (Get.isRegistered<HomeController>()) {
        Get.delete<HomeController>(force: true);
      }

      final cleanPhone = normalizePhone(phone);
      String deviceId = await _getDeviceId();
      final response = await ApiClient.post('/user/login', {
        'phone': cleanPhone,
        'device_id': deviceId,
      });

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await prefs.setString('token', body['data']['token']);
        await prefs.setString('user', jsonEncode(body['data']['user']));
        
        userData.value = {
          'id': body['data']['user']['id'].toString(),
          'name': body['data']['user']['name'] ?? '',
          'phone': body['data']['user']['phone'] ?? '',
          'balance': double.tryParse(body['data']['user']['balance']?.toString() ?? '0') ?? 0,
          'coins': int.tryParse(body['data']['user']['coins']?.toString() ?? '0') ?? 0,
          'photo_url': body['data']['user']['photo_url'] ?? '',
        };
        isLogged.value = true;
        
        updateFcmToken();
        Get.offAllNamed('/home');
      } else if (response.statusCode == 403 && body['data'] != null && body['data']['requires_otp'] == true) {
        Get.snackbar('Perhatian', body['message'], backgroundColor: Colors.orange, colorText: Colors.white);
        Get.toNamed('/verify-otp', arguments: cleanPhone);
      } else if (response.statusCode == 404) {
        Get.snackbar('Perhatian', 'Nomor HP belum terdaftar. Silakan daftar.', backgroundColor: Colors.orange, colorText: Colors.white);
        Get.toNamed('/register', arguments: cleanPhone);
      } else {
        Get.snackbar('Gagal', body['message'] ?? 'Login gagal', backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal terhubung ke server', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> register(String name, String phone, {String? email, File? photoFile}) async {
    isLoading.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user');
      isLogged.value = false;
      if (Get.isRegistered<HomeController>()) {
        Get.delete<HomeController>(force: true);
      }

      final cleanPhone = normalizePhone(phone);
      String deviceId = await _getDeviceId();
      http.Response response;

      if (photoFile != null) {
        final streamed = await ApiClient.multipartPost(
          '/user/register',
          {
            'name': name.trim(),
            'phone': cleanPhone,
            'email': (email != null && email.trim().isNotEmpty) ? email.trim() : '',
            'device_id': deviceId,
          },
          fileKey: 'photo',
          filePath: photoFile.path,
        );
        response = await http.Response.fromStream(streamed);
      } else {
        response = await ApiClient.post('/user/register', {
          'name': name.trim(),
          'phone': cleanPhone,
          'email': (email != null && email.trim().isNotEmpty) ? email.trim() : '',
          'device_id': deviceId,
        });
      }

      final body = jsonDecode(response.body);

      if (response.statusCode == 201) {
        startResendTimer(60);
        Get.snackbar(
          'Kode OTP Terkirim',
          'Pendaftaran berhasil! Kode 6 digit telah dikirim ke WhatsApp $cleanPhone',
          backgroundColor: Colors.green.shade700,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        Get.toNamed('/verify-otp', arguments: {
          'phone': cleanPhone,
          'name': name.trim(),
          'email': email?.trim() ?? '',
        });
        return true;
      } else {
        Get.snackbar(
          'Pendaftaran Gagal',
          body['message'] ?? 'Validasi gagal',
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal terhubung ke server', backgroundColor: Colors.red.shade700, colorText: Colors.white);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOtp(String phone, String otpCode) async {
    isLoading.value = true;
    try {
      final cleanPhone = normalizePhone(phone);
      final response = await ApiClient.post('/user/verify-otp', {
        'phone': cleanPhone,
        'otp_code': otpCode
      });
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', body['data']['token']);
        await prefs.setString('user', jsonEncode(body['data']['user']));
        
        final u = body['data']['user'] ?? {};
        userData.value = {
          'id': (u['id'] ?? '').toString(),
          'name': u['name'] ?? '',
          'phone': u['phone'] ?? '',
          'email': u['email'] ?? '',
          'balance': double.tryParse(u['balance']?.toString() ?? '0') ?? 0,
          'coins': int.tryParse(u['coins']?.toString() ?? '0') ?? 0,
          'photo_url': u['photo_url'] ?? '',
        };
        isLogged.value = true;
        
        updateFcmToken();
        Get.snackbar(
          '🎉 Selamat Datang!',
          'Pendaftaran & Verifikasi berhasil! Selamat menikmati layanan Maijek.',
          backgroundColor: Colors.green.shade700,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        Get.offAllNamed('/home');
      } else {
        Get.snackbar('Gagal', body['message'] ?? 'OTP Salah', backgroundColor: Colors.red.shade700, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal terhubung ke server', backgroundColor: Colors.red.shade700, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendOtp(String phone) async {
    if (resendCountdown.value > 0) return;
    try {
      final cleanPhone = normalizePhone(phone);
      final response = await ApiClient.post('/user/resend-otp', {'phone': cleanPhone});
      final body = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        startResendTimer(60);
        Get.snackbar('OTP Terkirim', body['message'] ?? 'Kode OTP baru telah dikirim ke WhatsApp Anda', backgroundColor: Colors.green.shade700, colorText: Colors.white);
      } else {
        Get.snackbar('Gagal', body['message'] ?? 'Gagal mengirim ulang OTP', backgroundColor: Colors.red.shade700, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal terhubung ke server', backgroundColor: Colors.red.shade700, colorText: Colors.white);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    isLogged.value = false;
    userData.value = {};
    if (Get.isRegistered<HomeController>()) {
      Get.delete<HomeController>(force: true);
    }
    Get.offAllNamed('/login');
  }

  Future<bool> deleteAccount() async {
    isLoading.value = true;
    try {
      final response = await ApiClient.post('/user/account/delete', {});
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        await prefs.remove('user');
        isLogged.value = false;
        userData.value = {};
        Get.offAllNamed('/login');
        Get.snackbar(
          'Akun Berhasil Dihapus',
          'Seluruh data pribadi Anda telah dihapus dari sistem Maijek.',
          backgroundColor: Colors.black87,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 4),
        );
        return true;
      } else {
        var body = jsonDecode(response.body);
        Get.snackbar(
          'Gagal Menghapus Akun',
          body['message'] ?? 'Terjadi kesalahan saat menghapus akun',
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal terhubung ke server: $e',
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateProfile(String name, String phone, {String? email, File? imageFile}) async {
    isUpdatingProfile.value = true;
    try {
      final fields = {
        'name': name.trim(),
        'phone': phone.trim(),
      };
      if (email != null) {
        fields['email'] = email.trim();
      }

      final streamedResponse = await ApiClient.multipartPost(
        '/user/profile/update',
        fields,
        fileKey: imageFile != null ? 'photo' : null,
        filePath: imageFile?.path,
      );

      final response = await http.Response.fromStream(streamedResponse);
      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['data'] != null) {
        var currentData = Map<String, dynamic>.from(userData);
        currentData.addAll(Map<String, dynamic>.from(body['data']));
        userData.value = currentData;
        userData.refresh();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(userData));

        return true;
      } else {
        Get.snackbar(
          'Gagal',
          body['message'] ?? 'Gagal memperbarui profil',
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Terjadi kesalahan saat memperbarui profil: $e',
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isUpdatingProfile.value = false;
    }
  }

  Future<void> fetchProfile() async {
    try {
      final response = await ApiClient.get('/user/profile');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['data'] != null) {
          var currentData = Map<String, dynamic>.from(userData);
          currentData.addAll(Map<String, dynamic>.from(body['data']));
          if (currentData['coins'] != null) {
            currentData['coins'] = int.tryParse(currentData['coins'].toString()) ?? 0;
          }
          if (currentData['balance'] != null) {
            currentData['balance'] = double.tryParse(currentData['balance'].toString()) ?? 0;
          }
          userData.value = currentData;
          userData.refresh();
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user', jsonEncode(userData));
        }
      }
    } catch (e) {
      // Silent catch
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}
