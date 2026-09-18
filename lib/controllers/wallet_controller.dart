import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../core/api_client.dart';
import 'auth_controller.dart';

class WalletController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();

  var transactions = <dynamic>[].obs;
  var withdrawHistory = <dynamic>[].obs;
  var isLoading = false.obs;
  var isTopUpLoading = false.obs;
  var isWithdrawLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchHistory();
    fetchWithdrawStatus();
  }

  Future<void> fetchHistory() async {
    isLoading.value = true;
    try {
      final response = await ApiClient.get('/user/wallet/history');
      if (response.statusCode == 200) {
        var body = jsonDecode(response.body);
        if (body['data'] != null) {
          transactions.value = body['data'];
        }
      }
    } catch (e) {
      debugPrint('Error fetching wallet history: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchWithdrawStatus() async {
    try {
      final response = await ApiClient.get('/user/wallet/withdraw-status');
      if (response.statusCode == 200) {
        var body = jsonDecode(response.body);
        if (body['data'] != null) {
          withdrawHistory.value = body['data'];
        }
      }
    } catch (e) {
      debugPrint('Error fetching withdraw status: $e');
    }
  }

  Future<void> topUp(double amount) async {
    isTopUpLoading.value = true;
    try {
      final response = await ApiClient.post('/user/wallet/topup', {
        'amount': amount.toString(),
      });
      
      var body = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        // Refresh saldo & history
        await _authController.fetchProfile();
        await fetchHistory();
        Get.back();
        Get.snackbar(
          'Berhasil', 
          'Top up berhasil ditambahkan ke saldo Anda', 
          backgroundColor: Colors.green, 
          colorText: Colors.white
        );
      } else {
        Get.snackbar('Gagal', body['message'] ?? 'Gagal melakukan top up');
      }
    } catch (e) {
      debugPrint('Error topup: $e');
      Get.snackbar('Error', 'Terjadi kesalahan jaringan');
    } finally {
      isTopUpLoading.value = false;
    }
  }

  Future<bool> requestWithdraw({
    required double amount,
    required String bankName,
    required String accountNumber,
    required String accountName,
  }) async {
    isWithdrawLoading.value = true;
    try {
      final response = await ApiClient.post('/user/wallet/withdraw', {
        'amount': amount.toString(),
        'bank_name': bankName,
        'account_number': accountNumber,
        'account_name': accountName,
      });

      var body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Refresh saldo & riwayat
        await _authController.fetchProfile();
        await fetchHistory();
        await fetchWithdrawStatus();
        Get.back();
        Get.snackbar(
          '🎉 Pengajuan Berhasil!',
          'Permintaan tarik tunai berhasil dikirim dan diproses dalam 1x24 jam kerja.',
          backgroundColor: Colors.green.shade700,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          icon: const Icon(Icons.check_circle, color: Colors.white),
        );
        return true;
      } else {
        Get.snackbar(
          'Gagal',
          body['message'] ?? 'Gagal mengajukan penarikan dana',
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          icon: const Icon(Icons.error_outline, color: Colors.white),
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error withdraw: $e');
      Get.snackbar('Error', 'Terjadi kesalahan jaringan');
      return false;
    } finally {
      isWithdrawLoading.value = false;
    }
  }
}
