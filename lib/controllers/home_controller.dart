import 'package:get/get.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import 'auth_controller.dart';

class HomeController extends GetxController {
  var banners = [].obs;
  var promos = [].obs;
  var flashSaleMenus = [].obs;
  var bestSellerMenus = [].obs;
  var bestSellerFoodMenus = [].obs;
  var bestSellerMartMenus = [].obs;
  var newMerchants = [].obs;
  var latestMenus = [].obs;
  var isLoading = false.obs;

  var currentBannerPage = 0.obs;
  PageController bannerPageController = PageController();
  Timer? _bannerTimer;
  Timer? _activeOrderTimer;

  var activeRideOrder = Rxn<dynamic>();
  var activeFoodOrder = Rxn<dynamic>();

  @override
  void onInit() {
    super.onInit();
    fetchHomeData();
    checkDailyReward();
    startActiveOrderPolling();
  }

  @override
  void onClose() {
    _bannerTimer?.cancel();
    _activeOrderTimer?.cancel();
    bannerPageController.dispose();
    super.onClose();
  }

  void _startBannerAutoScroll() {
    _bannerTimer?.cancel();
    if (banners.length <= 1) return;

    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!bannerPageController.hasClients) return;
      int nextPage = currentBannerPage.value + 1;
      if (nextPage >= banners.length) {
        nextPage = 0;
      }
      bannerPageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
      currentBannerPage.value = nextPage;
    });
  }

  Future<void> fetchHomeData() async {
    isLoading.value = true;
    try {
      // 1. Ambil Banner dari CMS Admin Panel (/admin/banners)
      final bannerRes = await ApiClient.get('/user/home/banners');
      if (bannerRes.statusCode == 200) {
        banners.value = json.decode(bannerRes.body)['data'] ?? [];
      } else {
        banners.clear();
      }

      _startBannerAutoScroll();

      // 2. Ambil Kupon Promo dari Admin Panel (/admin/promos)
      final promoRes = await ApiClient.get('/user/home/promos');
      if (promoRes.statusCode == 200) {
        promos.value = json.decode(promoRes.body)['data'] ?? [];
      } else {
        promos.clear();
      }

      // 3. Ambil Menu Flash Sale / Diskon yang diatur oleh Mitra/Resto
      try {
        final fsRes = await ApiClient.get('/user/home/flash-sales');
        if (fsRes.statusCode == 200) {
          flashSaleMenus.value = json.decode(fsRes.body)['data'] ?? [];
        } else {
          flashSaleMenus.clear();
        }
      } catch (e) {
        flashSaleMenus.clear();
      }

      // 4. Ambil Menu & Produk Paling Laris (Terpisah antara Food dan Mart)
      try {
        final results = await Future.wait([
          ApiClient.get('/user/home/best-sellers?type=food'),
          ApiClient.get('/user/home/best-sellers?type=mart'),
        ]);

        final foodRes = results[0];
        final martRes = results[1];

        if (foodRes.statusCode == 200) {
          final foodData = json.decode(foodRes.body)['data'] ?? [];
          bestSellerFoodMenus.value = (foodData as List)
              .where((m) => (m['merchant_type'] ?? 'food') != 'mart')
              .toList();
        } else {
          bestSellerFoodMenus.clear();
        }

        if (martRes.statusCode == 200) {
          final martData = json.decode(martRes.body)['data'] ?? [];
          bestSellerMartMenus.value = (martData as List)
              .where((m) => (m['merchant_type'] ?? '') == 'mart' || (m['unit'] != null && m['unit'] != ''))
              .toList();
        } else {
          bestSellerMartMenus.clear();
        }

        // Backward compatibility jika ada widget yang membaca bestSellerMenus
        bestSellerMenus.value = [...bestSellerFoodMenus, ...bestSellerMartMenus];
      } catch (e) {
        // Fallback bila ada kendala koneksi spesifik
        try {
          final bsRes = await ApiClient.get('/user/home/best-sellers');
          if (bsRes.statusCode == 200) {
            final allItems = (json.decode(bsRes.body)['data'] ?? []) as List;
            bestSellerMenus.value = allItems;
            bestSellerFoodMenus.value = allItems.where((m) => (m['merchant_type'] ?? 'food') != 'mart').toList();
            bestSellerMartMenus.value = allItems.where((m) => (m['merchant_type'] ?? '') == 'mart').toList();
          } else {
            bestSellerFoodMenus.clear();
            bestSellerMartMenus.clear();
            bestSellerMenus.clear();
          }
        } catch (_) {
          bestSellerFoodMenus.clear();
          bestSellerMartMenus.clear();
          bestSellerMenus.clear();
        }
      }

      // 5. Ambil Menu Baru Terupload
      try {
        final lmRes = await ApiClient.get('/user/food/latest-menus?limit=10');
        if (lmRes.statusCode == 200) {
          latestMenus.value = json.decode(lmRes.body)['data'] ?? [];
        } else {
          latestMenus.clear();
        }
      } catch (e) {
        latestMenus.clear();
      }

      // 6. Ambil Mitra/Merchant yang Baru Bergabung
      try {
        final nmRes = await ApiClient.get('/user/home/new-merchants?limit=10');
        if (nmRes.statusCode == 200) {
          newMerchants.value = json.decode(nmRes.body)['data'] ?? [];
        } else {
          newMerchants.clear();
        }
      } catch (e) {
        newMerchants.clear();
      }
    } catch (e) {
      // Handle error
    } finally {
      isLoading.value = false;
    }
    
    // Cek pesanan aktif di background setelah data home dimuat
    checkActiveOrder();
  }

  void startActiveOrderPolling() {
    _activeOrderTimer?.cancel();
    checkActiveOrder();
    _activeOrderTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      checkActiveOrder();
    });
  }

  Future<void> checkActiveOrder() async {
    // Jangan lakukan pengecekan pesanan aktif jika user tidak dalam kondisi logged in
    if (Get.isRegistered<AuthController>() && !Get.find<AuthController>().isLogged.value) {
      _activeOrderTimer?.cancel();
      return;
    }
    try {
      final results = await Future.wait([
        ApiClient.get('/user/orders/active'),
        ApiClient.get('/user/food/active'),
      ]);

      final rideRes = results[0];
      final foodRes = results[1];

      // 1. Cek Pesanan Ride / Mobil / Send / Titip
      if (rideRes.statusCode == 200) {
        var body = jsonDecode(rideRes.body);
        activeRideOrder.value = body['data'];
      } else if (rideRes.statusCode == 404) {
        activeRideOrder.value = null;
      }

      // 2. Cek Pesanan Food (Makanan)
      if (foodRes.statusCode == 200) {
        var body = jsonDecode(foodRes.body);
        activeFoodOrder.value = body['data'];
      } else if (foodRes.statusCode == 404) {
        activeFoodOrder.value = null;
      }
    } catch (e) {
      // Sinyal tersendat/timeout: Jangan reset state, pertahankan kartu agar tidak hilang tiba-tiba
      debugPrint('checkActiveOrder network glitch: $e');
    }
  }

  Future<void> checkDailyReward({bool isManual = false}) async {
    if (Get.isRegistered<AuthController>() && !Get.find<AuthController>().isLogged.value) {
      if (isManual) {
        Get.toNamed('/login');
        Get.snackbar(
          'Perlu Masuk',
          'Silakan masuk atau daftar terlebih dahulu untuk mengklaim koin',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black87,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
      }
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final lastPromptedDate = prefs.getString('daily_reward_prompted_date');

      // Jika auto-check saat buka aplikasi dan sudah pernah dicek/dimunculkan hari ini, jangan ganggu pengguna
      if (!isManual && lastPromptedDate == todayStr) {
        return;
      }

      final response = await ApiClient.get('/user/daily-reward');
      if (response.statusCode == 200) {
        var body = jsonDecode(response.body);

        // Hanya tampilkan popup hadiah jika benar-benar berhasil mengklaim koin baru hari ini
        if (body['status'] == 200 || body['koin_added'] != null) {
          await prefs.setString('daily_reward_prompted_date', todayStr);
          Get.defaultDialog(
            title: '🎉 Hadiah Harian! 🎉',
            middleText: body['message'] ?? 'Selamat! Anda mendapatkan 10 koin gratis hari ini!',
            confirm: ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Klaim Koin'),
            ),
            barrierDismissible: false,
          );
          final authController = Get.find<AuthController>();
          authController.fetchProfile();
        } else {
          // Sudah pernah klaim hari ini
          await prefs.setString('daily_reward_prompted_date', todayStr);
          if (isManual) {
            Get.snackbar(
              'Info Koin Harian',
              body['message'] ?? 'Anda sudah mengklaim hadiah harian hari ini. Kembali lagi besok ya!',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.amber.shade800,
              colorText: Colors.white,
              duration: const Duration(seconds: 3),
            );
          }
        }
      } else {
        // Status code != 200 (misal 400 'Sudah klaim hari ini')
        await prefs.setString('daily_reward_prompted_date', todayStr);
        if (isManual) {
          try {
            var body = jsonDecode(response.body);
            Get.snackbar(
              'Info Koin Harian',
              body['message'] ?? 'Anda sudah mengklaim hadiah harian hari ini. Kembali lagi besok ya!',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.amber.shade800,
              colorText: Colors.white,
              duration: const Duration(seconds: 3),
            );
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('Gagal cek hadiah harian: $e');
    }
  }
}
