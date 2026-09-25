import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/api_client.dart';
import 'package:geolocator/geolocator.dart';
import '../core/utils.dart';
import 'auth_controller.dart';
import 'home_controller.dart';
import '../views/wallet/insufficient_balance_sheet.dart';

class MartCategoryItem {
  final String id;
  final String name;
  final IconData icon;
  final String emoji;
  final Color color;
  final Color bgColor;
  final String description;

  const MartCategoryItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.emoji,
    required this.color,
    required this.bgColor,
    required this.description,
  });
}

class MartController extends GetxController {
  var isLoading = false.obs;
  var merchants = [].obs;
  var selectedCategory = 'Semua'.obs;

  var paymentMethod = 'cash'.obs;
  var deliveryNotes = ''.obs;

  var merchantDetail = {}.obs;
  var merchantProducts = [].obs;

  // Cart state
  var cart = [].obs;
  var currentMerchantId = ''.obs;
  var currentMerchantName = ''.obs;
  var currentMerchantAddress = ''.obs;

  // Delivery state
  var deliveryAddress = ''.obs;
  var deliveryAddressDetail = ''.obs;
  var deliveryLat = 0.0.obs;
  var deliveryLng = 0.0.obs;
  var deliveryDistance = 0.0.obs;

  // Search state
  var searchQuery = ''.obs;
  var searchCategory = 'Semua'.obs;
  var searchProducts = <dynamic>[].obs;
  var searchMerchants = <dynamic>[].obs;
  var isSearching = false.obs;

  // 8 Kategori Utama MaiMart
  static const List<MartCategoryItem> mainCategories = [
    MartCategoryItem(
      id: 'apotek',
      name: 'Apotek & Kesehatan',
      icon: Icons.medical_services_rounded,
      emoji: '💊',
      color: Color(0xFFEF4444),
      bgColor: Color(0xFFFEE2E2),
      description: 'Obat, vitamin & P3K',
    ),
    MartCategoryItem(
      id: 'sayur_buah',
      name: 'Sayur & Buah',
      icon: Icons.eco_rounded,
      emoji: '🥬',
      color: Color(0xFF10B981),
      bgColor: Color(0xFFD1FAE5),
      description: 'Sayur segar & buah',
    ),
    MartCategoryItem(
      id: 'daging_ayam',
      name: 'Daging & Ayam',
      icon: Icons.kebab_dining_rounded,
      emoji: '🍗',
      color: Color(0xFFF59E0B),
      bgColor: Color(0xFFFEF3C7),
      description: 'Daging sapi, ayam & ikan',
    ),
    MartCategoryItem(
      id: 'sembako',
      name: 'Sembako',
      icon: Icons.inventory_2_rounded,
      emoji: '🥚',
      color: Color(0xFFD97706),
      bgColor: Color(0xFFFDE68A),
      description: 'Beras, minyak, telur & mie',
    ),
    MartCategoryItem(
      id: 'bayi',
      name: 'Kebutuhan Bayi',
      icon: Icons.child_care_rounded,
      emoji: '🍼',
      color: Color(0xFF3B82F6),
      bgColor: Color(0xFFDBEAFE),
      description: 'Popok, susu & bubur',
    ),
    MartCategoryItem(
      id: 'pet_shop',
      name: 'Pet Shop',
      icon: Icons.pets_rounded,
      emoji: '🐾',
      color: Color(0xFF8B5CF6),
      bgColor: Color(0xFFEDE9FE),
      description: 'Pakan kucing & anjing',
    ),
    MartCategoryItem(
      id: 'rumah_tangga',
      name: 'Rumah Tangga',
      icon: Icons.cleaning_services_rounded,
      emoji: '🧴',
      color: Color(0xFF06B6D4),
      bgColor: Color(0xFFCFFAFE),
      description: 'Sabun, deterjen & pewangi',
    ),
    MartCategoryItem(
      id: 'lainnya',
      name: 'Lainnya',
      icon: Icons.shopping_basket_rounded,
      emoji: '🛒',
      color: Color(0xFF6B7280),
      bgColor: Color(0xFFF3F4F6),
      description: 'Kebutuhan harian umum',
    ),
  ];

  // Pricing & Settings
  var martBaseFare = 7000.obs;
  var martPerKmFare = 2000.obs;
  var martBaseDistance = 3.0.obs;

  var martCarBaseFare = 12000.obs;
  var martCarPerKmFare = 4000.obs;
  var martCarBaseDistance = 3.0.obs;

  var selectedVehicleType = 'motor'.obs; // 'motor' or 'mobil'

  @override
  void onInit() {
    super.onInit();
    fetchSettings();
    fetchMerchants();
  }

  Future<void> fetchSettings() async {
    try {
      final response = await ApiClient.get('/settings');
      if (response.statusCode == 200) {
        var body = json.decode(response.body);
        if (body['data'] != null) {
          martBaseFare.value = body['data']['food_base_fare'] ?? 7000;
          martPerKmFare.value = body['data']['food_per_km_fare'] ?? 2000;
          martBaseDistance.value = (body['data']['food_base_fare_distance'] ?? 3.0).toDouble();

          martCarBaseFare.value = body['data']['food_car_base_fare'] ?? 12000;
          martCarPerKmFare.value = body['data']['food_car_per_km_fare'] ?? 4000;
          martCarBaseDistance.value = (body['data']['food_car_base_distance'] ?? 3.0).toDouble();
        }
      }
    } catch (e) {
      debugPrint('Gagal memuat pengaturan mart: $e');
    }
  }

  Future<void> fetchMerchants({String? category}) async {
    isLoading.value = true;
    if (category != null) {
      selectedCategory.value = category;
    }
    try {
      if (deliveryAddress.value.isEmpty) {
        deliveryAddress.value = "Lokasi Pengantaran...";
      }

      String query = '?category=${Uri.encodeComponent(selectedCategory.value)}';
      try {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        query += '&lat=${position.latitude}&lng=${position.longitude}';
      } catch (e) {
        debugPrint('Location not available: $e');
      }

      final response = await ApiClient.get('/user/mart/merchants$query');
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        merchants.value = data['data'] ?? [];
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat toko MaiMart');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMerchantDetail(int merchantId) async {
    isLoading.value = true;
    try {
      final response = await ApiClient.get('/user/mart/merchant/$merchantId');
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        merchantDetail.value = data['data'] ?? {};
        merchantProducts.value = data['data']['products'] ?? [];
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat detail toko MaiMart');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> searchMart({String? query, String? category}) async {
    if (query != null) searchQuery.value = query;
    if (category != null) searchCategory.value = category;

    String q = searchQuery.value.trim();
    String cat = searchCategory.value.trim();

    if (q.isEmpty && (cat.isEmpty || cat == 'Semua')) {
      searchProducts.clear();
      searchMerchants.clear();
      return;
    }

    isSearching.value = true;
    try {
      String queryParam = '?q=${Uri.encodeComponent(q)}&category=${Uri.encodeComponent(cat)}';
      try {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        queryParam += '&lat=${position.latitude}&lng=${position.longitude}';
      } catch (_) {}

      final response = await ApiClient.get('/user/mart/search$queryParam');
      if (response.statusCode == 200) {
        var res = json.decode(response.body);
        if (res['data'] != null) {
          searchProducts.value = res['data']['products'] ?? [];
          searchMerchants.value = res['data']['merchants'] ?? [];
        }
      }
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      isSearching.value = false;
    }
  }

  void clearSearch() {
    searchQuery.value = '';
    searchCategory.value = 'Semua';
    searchProducts.clear();
    searchMerchants.clear();
  }

  int calculateDeliveryFee(String vehicleType) {
    double distance = deliveryDistance.value;
    if (vehicleType == 'mobil') {
      if (distance <= martCarBaseDistance.value) {
        return martCarBaseFare.value;
      } else {
        double extraDistance = distance - martCarBaseDistance.value;
        return martCarBaseFare.value + (extraDistance * martCarPerKmFare.value).ceil();
      }
    } else {
      if (distance <= martBaseDistance.value) {
        return martBaseFare.value;
      } else {
        double extraDistance = distance - martBaseDistance.value;
        return martBaseFare.value + (extraDistance * martPerKmFare.value).ceil();
      }
    }
  }

  int get currentDeliveryFee => calculateDeliveryFee(selectedVehicleType.value);

  int getCartQuantity(dynamic productId) {
    if (productId == null) return 0;
    String idStr = productId.toString();
    for (var item in cart) {
      if (item['menu_id'].toString() == idStr) {
        return (item['quantity'] as int?) ?? 0;
      }
    }
    return 0;
  }

  void addToCart(Map product, int quantity, String notes) {
    String mId = (merchantDetail['id'] ?? product['merchant_id'] ?? '').toString();
    String mName = (merchantDetail['name'] ?? product['merchant_name'] ?? 'Toko MaiMart').toString();
    String mAddress = (merchantDetail['address'] ?? product['merchant_address'] ?? '').toString();

    if (cart.isNotEmpty && currentMerchantId.value.isNotEmpty && currentMerchantId.value != mId) {
      Get.defaultDialog(
        title: 'Ganti Toko MaiMart?',
        titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        middleText: 'Keranjang Anda berisi pesanan dari toko lain. Hapus dan belanja dari $mName?',
        textConfirm: 'Ya, Ganti',
        textCancel: 'Batal',
        confirmTextColor: Colors.white,
        buttonColor: const Color(0xFF059669),
        onConfirm: () {
          cart.clear();
          currentMerchantId.value = mId;
          currentMerchantName.value = mName;
          currentMerchantAddress.value = mAddress;
          _addItemToCart(product, quantity, notes);
          Get.back();
        },
      );
    } else {
      currentMerchantId.value = mId;
      currentMerchantName.value = mName;
      currentMerchantAddress.value = mAddress;
      _addItemToCart(product, quantity, notes);
    }
  }

  void _addItemToCart(Map product, int quantity, String notes) {
    double activePrice = (product['discount_price'] != null &&
            double.tryParse(product['discount_price'].toString()) != null &&
            double.parse(product['discount_price'].toString()) > 0)
        ? double.parse(product['discount_price'].toString())
        : double.parse(product['price'].toString());

    int index = cart.indexWhere((item) => item['menu_id'].toString() == product['id'].toString());
    if (index >= 0) {
      var item = Map<String, dynamic>.from(cart[index]);
      item['quantity'] += quantity;
      item['price'] = activePrice;
      if (notes.isNotEmpty) item['notes'] = notes;
      cart[index] = item;
    } else {
      cart.add({
        'menu_id': product['id'],
        'name': product['name'],
        'price': activePrice,
        'original_price': double.parse(product['price'].toString()),
        'quantity': quantity,
        'unit': product['unit'] ?? 'pcs',
        'category': product['category'] ?? 'Lainnya',
        'notes': notes,
        'photo': product['photo'],
      });
    }

    Get.snackbar(
      '🛒 Keranjang MaiMart',
      '${product['name']} berhasil ditambahkan!',
      backgroundColor: const Color(0xFF065F46),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      icon: const Icon(Icons.shopping_basket_rounded, color: Colors.white),
    );
  }

  void updateCartQuantityByProductId(dynamic productId, int delta) {
    if (productId == null) return;
    String idStr = productId.toString();
    int idx = cart.indexWhere((item) => item['menu_id'].toString() == idStr);
    if (idx >= 0) {
      var item = Map<String, dynamic>.from(cart[idx]);
      int newQty = (item['quantity'] as int) + delta;
      if (newQty <= 0) {
        cart.removeAt(idx);
        if (cart.isEmpty) {
          currentMerchantId.value = '';
          currentMerchantName.value = '';
          currentMerchantAddress.value = '';
        }
      } else {
        item['quantity'] = newQty;
        cart[idx] = item;
      }
    }
  }

  void removeFromCart(int index) {
    cart.removeAt(index);
    if (cart.isEmpty) {
      currentMerchantId.value = '';
      currentMerchantName.value = '';
      currentMerchantAddress.value = '';
    }
  }

  void setDeliveryLocation(String address, double lat, double lng) {
    deliveryAddress.value = address;
    deliveryLat.value = lat;
    deliveryLng.value = lng;

    if (merchantDetail.isNotEmpty && merchantDetail['latitude'] != null) {
      double mLat = double.parse(merchantDetail['latitude'].toString());
      double mLng = double.parse(merchantDetail['longitude'].toString());

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

  var appliedPromo = Rxn<Map<String, dynamic>>();

  void applyPromo(Map<String, dynamic> promo) {
    appliedPromo.value = promo;
    Get.snackbar(
      '🎉 Voucher Digunakan!',
      'Hemat ${Formatter.currency(discountAmount)} untuk belanjaan MaiMart ini',
      backgroundColor: const Color(0xFF059669),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  void removePromo() {
    appliedPromo.value = null;
    Get.snackbar('Voucher Dilepas', 'Potongan harga dibatalkan');
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

    if (cart.isEmpty) {
      Get.snackbar('Keranjang Kosong', 'Pilih minimal 1 produk belanjaan');
      return false;
    }

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
      final response = await ApiClient.post('/user/mart/order', {
        'merchant_id': currentMerchantId.value,
        'delivery_address': address,
        'delivery_lat': lat.toString(),
        'delivery_lng': lng.toString(),
        'distance': distance.toString(),
        'payment_method': paymentMethod,
        'vehicle_type': selectedVehicleType.value,
        'promo_code': appliedPromo.value?['code'] ?? '',
        'delivery_notes': deliveryNotes.value,
        'items': json.encode(cart),
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        cart.clear();
        currentMerchantId.value = '';
        currentMerchantName.value = '';
        currentMerchantAddress.value = '';
        appliedPromo.value = null;
        deliveryNotes.value = '';
        var data = json.decode(response.body);
        if (Get.isRegistered<HomeController>()) {
          Get.find<HomeController>().checkActiveOrder();
        }
        Get.offNamedUntil(
          '/food/tracking',
          (route) => route.isFirst,
          arguments: {
            'order_id': data['data']['order_id'],
            'orderId': data['data']['order_id'],
            'order_type': 'mart',
          },
        );
        return true;
      } else {
        String msg = 'Gagal membuat pesanan MaiMart (${response.statusCode})';
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
          Get.snackbar('Pesanan Gagal', msg);
        }
        return false;
      }
    } catch (e) {
      debugPrint("MaiMart checkout error: $e");
      Get.snackbar('Koneksi Bermasalah', 'Terjadi kesalahan: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
