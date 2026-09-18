import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../core/api_client.dart';
import 'order_controller.dart';

class PromoController extends GetxController {
  var promos = <dynamic>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPromos();
  }

  Future<void> fetchPromos() async {
    isLoading.value = true;
    try {
      final response = await ApiClient.get('/user/promos');
      if (response.statusCode == 200) {
        var body = jsonDecode(response.body);
        if (body['data'] != null) {
          promos.value = body['data'];
        }
      }
    } catch (e) {
      debugPrint('Error fetching promos: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> applyPromo(String code) async {
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    
    try {
      final response = await ApiClient.post('/user/promos/validate', {'code': code});
      var body = jsonDecode(response.body);
      
      Get.back(); // close loading dialog
      
      if (response.statusCode == 200 && body['data'] != null) {
        var promoData = body['data'];
        
        // Teruskan data promo ke OrderController
        final orderController = Get.find<OrderController>();
        orderController.appliedPromo.value = promoData['code'];
        orderController.promoAmount = int.tryParse(promoData['discount_amount'].toString()) ?? 0;
        orderController.promoType = promoData['discount_type'];
        
        // Recalculate harga (akan memanggil ulang calculateRoute() atau memotong langsung price)
        orderController.applyPromoDiscount();

        Get.back(); // tutup modal promo
        Get.snackbar('Berhasil', 'Promo ${promoData['code']} berhasil digunakan!', 
          backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar('Gagal', body['message'] ?? 'Promo tidak valid');
      }
    } catch (e) {
      Get.back(); // close loading dialog
      debugPrint('Error validating promo: $e');
      Get.snackbar('Error', 'Gagal memvalidasi promo');
    }
  }
}
