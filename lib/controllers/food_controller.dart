import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/api_client.dart';
import 'package:geolocator/geolocator.dart';
import '../core/utils.dart';
import 'auth_controller.dart';
import 'home_controller.dart';
import '../views/wallet/insufficient_balance_sheet.dart';

class FoodController extends GetxController {
  var isLoading = false.obs;
  var merchants = [].obs;
  
  var paymentMethod = 'cash'.obs;
  
  var merchantDetail = {}.obs;
  var merchantMenus = [].obs;
  
  // Cart state
  var cart = [].obs;
  var currentMerchantId = ''.obs;
  var currentMerchantName = ''.obs;

  // Delivery state
  var deliveryAddress = ''.obs;
  var deliveryAddressDetail = ''.obs;
  var deliveryLat = 0.0.obs;
  var deliveryLng = 0.0.obs;
  var deliveryDistance = 0.0.obs;

  // Search state
  var searchQuery = ''.obs;
  var searchCategory = 'Semua'.obs;
  var searchMenus = <dynamic>[].obs;
  var searchMerchants = <dynamic>[].obs;
  var isSearching = false.obs;

  Future<void> searchFood({String? query, String? category}) async {
    if (query != null) searchQuery.value = query;
    if (category != null) searchCategory.value = category;

    String q = searchQuery.value.trim();
    String cat = searchCategory.value.trim();

    if (q.isEmpty && (cat.isEmpty || cat == 'Semua')) {
      searchMenus.clear();
      searchMerchants.clear();
      return;
    }

    isSearching.value = true;
    try {
      String queryParam = '?q=${Uri.encodeComponent(q)}&category=${Uri.encodeComponent(cat)}';
      try {
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        queryParam += '&lat=${position.latitude}&lng=${position.longitude}';
      } catch (_) {}

      final response = await ApiClient.get('/user/food/search$queryParam');
      if (response.statusCode == 200) {
        var res = json.decode(response.body);
        if (res['data'] != null) {
          searchMenus.value = res['data']['menus'] ?? [];
          searchMerchants.value = res['data']['merchants'] ?? [];
        }
      }
    } catch (e) {
      // Error handling
    } finally {
      isSearching.value = false;
    }
  }

  void clearSearch() {
    searchQuery.value = '';
    searchCategory.value = 'Semua';
    searchMenus.clear();
    searchMerchants.clear();
  }

  @override
  void onInit() {
    super.onInit();
    fetchSettings();
    fetchMerchants();
  }

  var foodBaseFare = 5000.obs;
  var foodPerKmFare = 2000.obs;
  var foodBaseDistance = 3.0.obs;

  var foodCarBaseFare = 12000.obs;
  var foodCarPerKmFare = 4000.obs;
  var foodCarBaseDistance = 3.0.obs;

  var selectedVehicleType = 'motor'.obs; // 'motor' or 'mobil'

  int calculateDeliveryFee(String vehicleType) {
    double distance = deliveryDistance.value;
    if (vehicleType == 'mobil') {
      if (distance <= foodCarBaseDistance.value) {
        return foodCarBaseFare.value;
      } else {
        double extraDistance = distance - foodCarBaseDistance.value;
        return foodCarBaseFare.value + (extraDistance * foodCarPerKmFare.value).ceil();
      }
    } else {
      if (distance <= foodBaseDistance.value) {
        return foodBaseFare.value;
      } else {
        double extraDistance = distance - foodBaseDistance.value;
        return foodBaseFare.value + (extraDistance * foodPerKmFare.value).ceil();
      }
    }
  }

  int get currentDeliveryFee => calculateDeliveryFee(selectedVehicleType.value);

  Future<void> fetchSettings() async {
    try {
      final response = await ApiClient.get('/settings');
      if (response.statusCode == 200) {
        var body = json.decode(response.body);
        if (body['data'] != null) {
          foodBaseFare.value = body['data']['food_base_fare'] ?? 5000;
          foodPerKmFare.value = body['data']['food_per_km_fare'] ?? 2000;
          foodBaseDistance.value = (body['data']['food_base_fare_distance'] ?? 3.0).toDouble();

          foodCarBaseFare.value = body['data']['food_car_base_fare'] ?? 12000;
          foodCarPerKmFare.value = body['data']['food_car_per_km_fare'] ?? 4000;
          foodCarBaseDistance.value = (body['data']['food_car_base_distance'] ?? 3.0).toDouble();
        }
      }
    } catch (e) {
      print('Gagal memuat pengaturan food: $e');
    }
  }

  var bestSellerMenus = [].obs;
  var newMenus = [].obs;

  Future<void> fetchNewMenus() async {
    try {
      final res = await ApiClient.get('/user/food/latest-menus?limit=15');
      if (res.statusCode == 200) {
        final data = (json.decode(res.body)['data'] ?? []) as List;
        newMenus.value = data;
      }
    } catch (_) {}
  }

  Future<void> fetchMerchants() async {
    isLoading.value = true;
    try {
      // Set default delivery address if empty (fallback to user's location)
      if (deliveryAddress.value.isEmpty) {
        deliveryAddress.value = "Pilih Lokasi Pengantaran...";
      }
      
      String query = '';
      try {
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        query = '?lat=${position.latitude}&lng=${position.longitude}';
      } catch (e) {
        print('Location not available for sorting: $e');
      }

      final response = await ApiClient.get('/user/food/merchants$query');
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        merchants.value = data['data'];
      }

      // Ambil Menu Terlaris untuk tampilan MaiFood (Khusus kuliner restoran)
      try {
        final bsRes = await ApiClient.get('/user/home/best-sellers?type=food');
        if (bsRes.statusCode == 200) {
          final data = (json.decode(bsRes.body)['data'] ?? []) as List;
          bestSellerMenus.value = data.where((m) => (m['merchant_type'] ?? 'food') != 'mart').toList();
        }
      } catch (_) {}

      // Ambil Menu Baru Terupload untuk tampilan MaiFood
      try {
        final newRes = await ApiClient.get('/user/food/latest-menus?limit=15');
        if (newRes.statusCode == 200) {
          final data = (json.decode(newRes.body)['data'] ?? []) as List;
          newMenus.value = data;
        }
      } catch (_) {}
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat daftar restoran');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMerchantDetail(int merchantId) async {
    isLoading.value = true;
    try {
      final response = await ApiClient.get('/user/food/merchant/$merchantId');
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        merchantDetail.value = data['data'];
        merchantMenus.value = data['data']['menus'] ?? [];
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat detail restoran');
    } finally {
      isLoading.value = false;
    }
  }

  int getMenuCartQuantity(dynamic menuId) {
    if (menuId == null) return 0;
    String idStr = menuId.toString();
    for (var item in cart) {
      if (item['menu_id'].toString() == idStr) {
        return (item['quantity'] as int?) ?? 0;
      }
    }
    return 0;
  }

  void addToCart(Map menu, int quantity, String notes) {
    String mId = (merchantDetail['id'] ?? menu['merchant_id'] ?? '').toString();
    String mName = (merchantDetail['name'] ?? menu['merchant_name'] ?? 'Restoran').toString();
    if (cart.isNotEmpty && currentMerchantId.value.isNotEmpty && currentMerchantId.value != mId) {
      Get.defaultDialog(
        title: 'Ganti Restoran?',
        titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        middleText: 'Keranjang Anda berisi pesanan dari restoran lain. Hapus dan ganti dengan pesanan dari $mName?',
        textConfirm: 'Ya, Ganti',
        textCancel: 'Batal',
        confirmTextColor: Colors.white,
        buttonColor: Colors.deepOrange,
        onConfirm: () {
          cart.clear();
          currentMerchantId.value = mId;
          currentMerchantName.value = mName;
          _addItemToCart(menu, quantity, notes);
          Get.back();
        }
      );
    } else {
      currentMerchantId.value = mId;
      currentMerchantName.value = mName;
      _addItemToCart(menu, quantity, notes);
    }
  }

  void addToCartFromSearch(Map menu, {int quantity = 1, String notes = '', VoidCallback? onSuccess}) {
    String mId = (menu['merchant_id'] ?? merchantDetail['id'] ?? '').toString();
    String mName = (menu['merchant_name'] ?? merchantDetail['name'] ?? 'Restoran').toString();

    if (cart.isNotEmpty && currentMerchantId.value.isNotEmpty && currentMerchantId.value != mId) {
      Get.defaultDialog(
        title: 'Ganti Restoran?',
        titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        middleText: 'Keranjangmu saat ini berisi pesanan dari ${currentMerchantName.value.isNotEmpty ? currentMerchantName.value : 'toko lain'}. Hapus dan buat pesanan baru dari $mName?',
        textConfirm: 'Ya, Ganti',
        textCancel: 'Batal',
        confirmTextColor: Colors.white,
        buttonColor: Colors.deepOrange,
        onConfirm: () {
          cart.clear();
          currentMerchantId.value = mId;
          currentMerchantName.value = mName;
          if (mId.isNotEmpty) fetchMerchantDetail(int.parse(mId));
          _addItemToCart(menu, quantity, notes);
          Get.back();
          onSuccess?.call();
        }
      );
    } else {
      currentMerchantId.value = mId;
      currentMerchantName.value = mName;
      if (mId.isNotEmpty && (merchantDetail.isEmpty || merchantDetail['id'].toString() != mId)) {
        fetchMerchantDetail(int.parse(mId));
      }
      _addItemToCart(menu, quantity, notes);
      onSuccess?.call();
    }
  }

  void updateCartQuantityByMenuId(dynamic menuId, int delta) {
    if (menuId == null) return;
    String idStr = menuId.toString();
    int idx = cart.indexWhere((item) => item['menu_id'].toString() == idStr);
    if (idx >= 0) {
      var item = Map<String, dynamic>.from(cart[idx]);
      int newQty = (item['quantity'] as int) + delta;
      if (newQty <= 0) {
        cart.removeAt(idx);
        if (cart.isEmpty) {
          currentMerchantId.value = '';
          currentMerchantName.value = '';
        }
      } else {
        item['quantity'] = newQty;
        cart[idx] = item;
      }
    }
  }

  void setCartItemQuantity(dynamic menuId, int quantity, {String? notes}) {
    if (menuId == null) return;
    String idStr = menuId.toString();
    int idx = cart.indexWhere((item) => item['menu_id'].toString() == idStr);
    if (idx >= 0) {
      if (quantity <= 0) {
        cart.removeAt(idx);
        if (cart.isEmpty) {
          currentMerchantId.value = '';
          currentMerchantName.value = '';
        }
      } else {
        var item = Map<String, dynamic>.from(cart[idx]);
        item['quantity'] = quantity;
        if (notes != null) item['notes'] = notes;
        cart[idx] = item;
      }
    }
  }

  void removeCartItemByMenuId(dynamic menuId) {
    if (menuId == null) return;
    String idStr = menuId.toString();
    int idx = cart.indexWhere((item) => item['menu_id'].toString() == idStr);
    if (idx >= 0) {
      cart.removeAt(idx);
      if (cart.isEmpty) {
        currentMerchantId.value = '';
        currentMerchantName.value = '';
      }
    }
  }

  int get totalCartQuantity {
    int total = 0;
    for (var item in cart) {
      total += (item['quantity'] as int?) ?? 0;
    }
    return total;
  }

  var appliedPromo = Rxn<Map<String, dynamic>>();

  void applyPromo(Map<String, dynamic> promo) {
    appliedPromo.value = promo;
    Get.snackbar(
      '🎉 Promo Berhasil Digunakan!',
      'Hemat hingga ${Formatter.currency(discountAmount)} untuk pesanan ini',
      backgroundColor: Colors.green.shade700,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  void removePromo() {
    appliedPromo.value = null;
    Get.snackbar('Promo Dibatalkan', 'Voucher potongan harga telah dilepas');
  }

  int get discountAmount {
    if (appliedPromo.value == null) return 0;
    var p = appliedPromo.value!;
    String code = (p['code'] ?? '').toString().toUpperCase();
    if (code == 'MAIPERTAMA') {
      return (cartTotal * 0.5).round().clamp(0, 15000);
    } else if (code == 'GRATISONGKIR') {
      return currentDeliveryFee.clamp(0, 8000);
    } else if (code == 'HEMAT30') {
      return (cartTotal * 0.3).round().clamp(0, 12000);
    } else if (p['discount_type'] == 'percent') {
      int pct = int.tryParse(p['discount_amount'].toString()) ?? 10;
      return (cartTotal * (pct / 100)).round();
    } else {
      return int.tryParse(p['discount_amount'].toString()) ?? 0;
    }
  }

  int get finalTotal {
    int total = (cartTotal + currentDeliveryFee) - discountAmount;
    return total < 0 ? 0 : total;
  }

  void _addItemToCart(Map menu, int quantity, String notes) {
    double activePrice = (menu['discount_price'] != null && double.tryParse(menu['discount_price'].toString()) != null && double.parse(menu['discount_price'].toString()) > 0)
        ? double.parse(menu['discount_price'].toString())
        : double.parse(menu['price'].toString());

    // Check if already in cart
    int index = cart.indexWhere((item) => item['menu_id'].toString() == menu['id'].toString());
    if (index >= 0) {
      var item = Map<String, dynamic>.from(cart[index]);
      item['quantity'] += quantity;
      item['price'] = activePrice;
      if (notes.isNotEmpty) item['notes'] = notes;
      cart[index] = item;
    } else {
      cart.add({
        'menu_id': menu['id'],
        'name': menu['name'],
        'price': activePrice,
        'original_price': double.parse(menu['price'].toString()),
        'quantity': quantity,
        'notes': notes,
        'photo': menu['photo'],
      });
    }
    Get.snackbar(
      '🛒 Keranjang',
      '${menu['name']} ditambahkan ke keranjang!',
      backgroundColor: Colors.green.shade800,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
    );
  }
  
  void removeFromCart(int index) {
    cart.removeAt(index);
    if (cart.isEmpty) currentMerchantId.value = '';
  }

  void setDeliveryLocation(String address, double lat, double lng) {
    deliveryAddress.value = address;
    deliveryLat.value = lat;
    deliveryLng.value = lng;
    
    // Calculate distance to merchant if we have merchant coords
    if (merchantDetail.isNotEmpty && merchantDetail['latitude'] != null) {
      double mLat = double.parse(merchantDetail['latitude'].toString());
      double mLng = double.parse(merchantDetail['longitude'].toString());
      
      // Calculate direct distance
      double distMeters = Geolocator.distanceBetween(lat, lng, mLat, mLng);
      deliveryDistance.value = distMeters / 1000.0;
      if (deliveryDistance.value < 0.1) deliveryDistance.value = 0.1;
    }
  }

  int get cartTotal {
    int total = 0;
    for (var item in cart) {
      total += double.parse(item['price'].toString()).toInt() * (item['quantity'] as int);
    }
    return total;
  }

  Future<bool> checkoutOrder(String address, double lat, double lng, double distance, String paymentMethod) async {
    final authController = Get.find<AuthController>();
    // Intercept jika user belum login
    if (!authController.isLogged.value) {
      Get.toNamed('/login');
      Get.snackbar(
        'Perlu Masuk',
        'Silakan masuk atau daftar terlebih dahulu untuk melanjutkan pesanan',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return false;
    }

    // Cek saldo jika menggunakan Mai-Pay
    if (paymentMethod == 'maipay') {
      final authController = Get.find<AuthController>();
      double currentBalance = double.tryParse(authController.userData['balance']?.toString() ?? '0') ?? 0;
      double totalAmount = finalTotal.toDouble();
      if (currentBalance < totalAmount) {
        InsufficientBalanceSheet.show(
          currentBalance: currentBalance,
          requiredAmount: totalAmount,
          onPayCash: () {
            this.paymentMethod.value = 'cash';
            checkoutOrder(address, lat, lng, distance, 'cash');
          },
        );
        return false;
      }
    }

    isLoading.value = true;
    try {
      final response = await ApiClient.post('/user/food/order', {
        'merchant_id': currentMerchantId.value,
        'delivery_address': address,
        'delivery_lat': lat.toString(),
        'delivery_lng': lng.toString(),
        'distance': distance.toString(),
        'payment_method': paymentMethod,
        'vehicle_type': selectedVehicleType.value,
        'promo_code': appliedPromo.value?['code'] ?? '',
        'items': json.encode(cart),
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        cart.clear();
        currentMerchantId.value = '';
        appliedPromo.value = null;
        var data = json.decode(response.body);
        if (Get.isRegistered<HomeController>()) {
          Get.find<HomeController>().checkActiveOrder();
        }
        Get.offNamedUntil(
          '/food/tracking',
          (route) => route.isFirst,
          arguments: {'order_id': data['data']['order_id']},
        );
        return true;
      } else {
        String msg = 'Gagal membuat pesanan (Kode: ${response.statusCode})';
        try {
          var err = json.decode(response.body);
          if (err is Map && err['message'] != null) {
            msg = err['message'];
          }
        } catch (_) {}

        if (msg.toLowerCase().contains('saldo') && msg.toLowerCase().contains('mencukupi')) {
          final authController = Get.find<AuthController>();
          double currentBalance = double.tryParse(authController.userData['balance']?.toString() ?? '0') ?? 0;
          InsufficientBalanceSheet.show(
            currentBalance: currentBalance,
            requiredAmount: finalTotal.toDouble(),
            onPayCash: () {
              this.paymentMethod.value = 'cash';
              checkoutOrder(address, lat, lng, distance, 'cash');
            },
          );
        } else {
          Get.snackbar('Error', msg);
        }
        return false;
      }
    } catch (e) {
      debugPrint("Checkout error: $e");
      Get.snackbar('Error Jaringan', 'Terjadi kesalahan: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
