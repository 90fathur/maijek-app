import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_update/in_app_update.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../home/home_view.dart';
import '../wallet/wallet_view.dart';
import '../orders/order_history_view.dart';
import '../inbox/inbox_view.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/notification_controller.dart';
import '../../controllers/auth_controller.dart';

class MainLayoutController extends GetxController {
  var currentIndex = 0.obs;

  void changePage(int index) {
    if (index != 0) {
      if (Get.isRegistered<AuthController>()) {
        final auth = Get.find<AuthController>();
        if (!auth.isLogged.value) {
          Get.toNamed('/login');
          Get.snackbar(
            'Akses Akun',
            'Silakan masuk atau daftar untuk mengakses fitur akun ini.',
            backgroundColor: AppTheme.primaryNavy,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
          );
          return;
        }
      }
    }
    currentIndex.value = index;
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().checkActiveOrder();
    }
    if (index == 3 && Get.isRegistered<NotificationController>()) {
      Get.find<NotificationController>().fetchNotifications();
    }
  }
}

class MainLayoutView extends StatefulWidget {
  const MainLayoutView({super.key});

  @override
  State<MainLayoutView> createState() => _MainLayoutViewState();
}

class _MainLayoutViewState extends State<MainLayoutView> {
  final MainLayoutController controller = Get.put(MainLayoutController());
  final HomeController homeController = Get.put(HomeController());
  final NotificationController notifController = Get.put(NotificationController());

  final List<Widget> pages = [
    HomeView(),
    const WalletView(),
    const OrderHistoryView(),
    const InboxView(),
  ];

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
    if (Get.isRegistered<AuthController>()) {
      Get.find<AuthController>().updateFcmToken();
    }
  }

  Future<void> _checkForUpdate() async {
    if (!GetPlatform.isAndroid) return;
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      // Ignore if not published or running in emulator without Play Store
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Obx(() => IndexedStack(
            index: controller.currentIndex.value,
            children: pages,
          )),

          // STICKY FLOATING ACTIVE ORDER BANNER (Melayang tepat di atas Bottom Nav Bar)
          Positioned(
            bottom: 12,
            left: 14,
            right: 14,
            child: Obx(() => _buildGlobalActiveOrderBanner()),
          ),
        ],
      ),
      bottomNavigationBar: Obx(() => Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: controller.currentIndex.value,
          onTap: controller.changePage,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primaryNavy,
          unselectedItemColor: Colors.grey.shade500,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: [
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.home_rounded, 0),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.account_balance_wallet_rounded, 1),
              label: 'Pembayaran',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.receipt_long_rounded, 2),
              label: 'Aktivitas',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.chat_bubble_rounded, 3),
              label: 'Kotak Masuk',
            ),
          ],
        ),
      )),
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    bool isActive = controller.currentIndex.value == index;

    Widget iconWidget = Icon(icon, size: 23, color: isActive ? AppTheme.primaryNavy : Colors.grey.shade500);

    if (index == 3) {
      iconWidget = Obx(() {
        int unread = notifController.unreadCount;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, size: 23, color: isActive ? AppTheme.primaryNavy : Colors.grey.shade500),
            if (unread > 0)
              Positioned(
                right: -4,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppTheme.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                ),
              ),
          ],
        );
      });
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconWidget,
        const SizedBox(height: 3),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isActive ? 5 : 0,
          height: isActive ? 5 : 0,
          decoration: const BoxDecoration(
            color: AppTheme.accentGold,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  Widget _buildGlobalActiveOrderBanner() {
    List<dynamic> allOrders = List<dynamic>.from(homeController.allActiveOrders);

    // Fallback jika allActiveOrders belum terisi tapi activeRideOrder / activeFoodOrder ada
    if (allOrders.isEmpty) {
      if (homeController.activeFoodOrder.value != null) {
        var fo = Map<String, dynamic>.from(homeController.activeFoodOrder.value);
        fo['order_family'] = 'food';
        allOrders.add(fo);
      }
      if (homeController.activeRideOrder.value != null) {
        var ro = Map<String, dynamic>.from(homeController.activeRideOrder.value);
        ro['order_family'] = 'ride';
        allOrders.add(ro);
      }
    }

    if (allOrders.isEmpty) {
      return const SizedBox.shrink();
    }

    // Jika hanya ada 1 pesanan aktif: Tampilkan kartu tunggal
    if (allOrders.length == 1) {
      return _buildSingleOrderCard(allOrders.first);
    }

    // Jika ada lebih dari 1 pesanan aktif (Multi-Order concurrent):
    // Tampilkan pill multi-order + kartu order teratas, dan ketukan membuka bottom sheet lengkap
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Pill Multi-Order Indicator
        GestureDetector(
          onTap: () => _showAllActiveOrdersSheet(context, allOrders),
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.6), width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 6),
                Text(
                  '${allOrders.length} Pesanan Berlangsung',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(width: 8),
                Container(width: 3.5, height: 3.5, decoration: const BoxDecoration(color: Colors.white60, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                const Text(
                  'Lihat Semua',
                  style: TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.keyboard_arrow_up_rounded, color: AppTheme.accentGold, size: 16),
              ],
            ),
          ),
        ),
        _buildSingleOrderCard(
          allOrders.first,
          isMultiOrder: true,
          totalCount: allOrders.length,
          onOpenList: () => _showAllActiveOrdersSheet(context, allOrders),
        ),
      ],
    );
  }

  Widget _buildSingleOrderCard(
    dynamic order, {
    bool isMultiOrder = false,
    int totalCount = 1,
    VoidCallback? onOpenList,
  }) {
    bool isFood = (order['order_family'] == 'food') || order.containsKey('merchant_name') || order.containsKey('food_total');

    final bool isUnpaidQris = (order['payment_method'] ?? '').toString().toLowerCase() == 'qris' &&
        (order['payment_status'] ?? '').toString().toLowerCase() != 'paid';

    String serviceType = (order['service_type'] ?? (isFood ? 'food' : 'motor')).toString().toLowerCase();
    String status = (order['status'] ?? 'pending').toString().toLowerCase();
    String dVehicle = (order['driver_vehicle_type'] ?? order['vehicle_type'] ?? '').toString().toLowerCase();
    bool isCarService = serviceType == 'mobil' || serviceType == 'car' || serviceType == 'car_premium' ||
                        dVehicle.contains('mobil') || dVehicle.contains('car');

    // 1. Tentukan Judul Layanan, Ikon, dan Warna
    String serviceTitle = 'Mai-Ride';
    IconData serviceIcon = Icons.two_wheeler;
    Color serviceColor = AppTheme.primaryNavy;

    bool isOrderMart = (order['order_type'] ?? '').toString().toLowerCase() == 'mart' || serviceType == 'mart';

    if (isOrderMart) {
      serviceTitle = 'Mai-Mart';
      serviceIcon = Icons.storefront;
      serviceColor = Colors.teal;
    } else if (isFood || serviceType == 'food') {
      serviceTitle = 'Mai-Food';
      serviceIcon = Icons.lunch_dining;
      serviceColor = Colors.deepOrange;
    } else if (serviceType == 'mai_send_motor' || serviceType == 'send') {
      serviceTitle = 'Mai-Send';
      serviceIcon = Icons.local_shipping;
      serviceColor = Colors.purple;
    } else if (serviceType == 'mai_titip' || serviceType == 'titip') {
      serviceTitle = 'Mai-Titip';
      serviceIcon = Icons.shopping_basket;
      serviceColor = Colors.green.shade700;
    } else if (isCarService) {
      serviceTitle = 'Mai-Car';
      serviceIcon = Icons.directions_car;
      serviceColor = const Color(0xFF0066CC);
    }

    // 2. Tentukan Teks Status & Subinfo
    String statusHeadline = 'Pesanan Sedang Berjalan';
    String subInfo = '';

    if (isFood) {
      String defaultMerchant = isOrderMart ? 'Toko' : 'Restoran';
      String merchantName = order['merchant_name'] ?? defaultMerchant;
      String driverName = order['driver_name'] ?? '';
      String plate = order['vehicle_plate'] ?? '';

      if (isUnpaidQris) {
        serviceTitle = 'QRIS';
        serviceIcon = Icons.qr_code_2_rounded;
        serviceColor = const Color(0xFFD97706);
        statusHeadline = 'Menunggu Pembayaran QRIS';
        double amt = double.tryParse((order['total_price'] ?? order['price'] ?? 0).toString()) ?? 0;
        subInfo = amt > 0 ? '${Formatter.currency(amt)} • Ketuk untuk bayar QR' : 'Ketuk untuk buka kode QR & bayar';
      } else if (status == 'pending') {
        statusHeadline = 'Menunggu konfirmasi $merchantName';
        subInfo = isOrderMart ? 'Pesanan telah terkirim ke toko' : 'Pesanan telah terkirim ke restoran';
      } else if (status == 'accepted_by_merchant' || status == 'processing') {
        statusHeadline = isOrderMart ? '$merchantName sedang menyiapkan pesanan' : '$merchantName sedang memasak';
        subInfo = isOrderMart ? 'Barang belanjaanmu sedang dikemas' : 'Makananmu sedang disiapkan di dapur resto';
      } else if (status == 'ready' || status == 'driver_assigned' || status == 'accepted') {
        statusHeadline = driverName.isNotEmpty 
            ? 'Driver $driverName menuju ${isOrderMart ? "toko" : "resto"}' 
            : 'Driver menuju ${isOrderMart ? "toko" : "restoran"}';
        subInfo = plate.isNotEmpty ? '$merchantName • $plate' : merchantName;
      } else if (status == 'driver_at_merchant') {
        statusHeadline = 'Driver telah tiba di ${isOrderMart ? "toko" : "resto"}';
        subInfo = isOrderMart ? 'Menunggu belanjaan diserahkan' : 'Menunggu pesanan selesai dibungkus';
      } else if (status == 'delivering' || status == 'in_progress') {
        statusHeadline = isOrderMart ? 'Belanjaan sedang diantar ke rumahmu!' : 'Makanan sedang diantar ke rumahmu!';
        subInfo = driverName.isNotEmpty ? '$driverName ($plate)' : 'Driver dalam perjalanan';
      } else {
        statusHeadline = isOrderMart ? 'Pesanan Mai-Mart Aktif' : 'Pesanan Mai-Food Aktif';
        subInfo = merchantName;
      }
    } else {
      String driverName = order['driver_name'] ?? '';
      String plate = order['vehicle_plate'] ?? '';

      if (isUnpaidQris) {
        serviceTitle = 'QRIS';
        serviceIcon = Icons.qr_code_2_rounded;
        serviceColor = const Color(0xFFD97706);
        statusHeadline = 'Menunggu Pembayaran QRIS';
        double amt = double.tryParse((order['price'] ?? 0).toString()) ?? 0;
        subInfo = amt > 0 ? '${Formatter.currency(amt)} • Ketuk untuk bayar QR' : 'Ketuk untuk buka kode QR & bayar';
      } else if (status == 'pending') {
        statusHeadline = isCarService ? 'Mencari driver Mai-Car terdekat...' : 'Mencari pengemudi terdekat...';
        subInfo = 'Jangan keluar dulu, mencari driver cocok (~1-2 mnt)';
      } else if (status == 'accepted') {
        if (serviceType == 'mai_send_motor') {
          statusHeadline = 'Kurir menuju lokasi paket';
        } else if (serviceType == 'mai_titip') {
          statusHeadline = 'Driver sedang membelikan titipan';
        } else {
          statusHeadline = 'Driver menuju titik jemput';
        }
        subInfo = driverName.isNotEmpty ? '$driverName ${plate.isNotEmpty ? "($plate)" : ""}' : 'Driver dalam perjalanan';
      } else if (status == 'arrived') {
        statusHeadline = 'Driver telah tiba di titik jemput! 📍';
        subInfo = driverName.isNotEmpty ? '$driverName sudah menunggu di lokasi' : 'Silakan temui driver Anda';
      } else if (status == 'in_progress') {
        if (serviceType == 'mai_send_motor') {
          statusHeadline = 'Paket sedang diantar ke penerima';
        } else if (serviceType == 'mai_titip') {
          statusHeadline = 'Titipan sedang diantar ke tujuan';
        } else {
          statusHeadline = 'Dalam perjalanan ke lokasi tujuan';
        }
        subInfo = driverName.isNotEmpty ? '$driverName • ${order['dropoff_address'] ?? ""}' : (order['dropoff_address'] ?? 'Menuju tujuan');
      } else {
        statusHeadline = '$serviceTitle Sedang Berjalan';
        subInfo = 'Ketuk untuk melihat posisi driver di peta';
      }
    }

    void onCardTap() {
      if (isFood) {
        Get.toNamed('/food/tracking', arguments: {'order_id': order['id']});
      } else {
        Get.toNamed('/order-tracking', arguments: {'order_id': order['id']});
      }
    }

    return Material(
      color: Colors.transparent,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onCardTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: serviceColor.withValues(alpha: 0.35), width: 1.5),
          ),
          child: Row(
            children: [
              // Ikon Layanan dengan badge live hijau
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: serviceColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(serviceIcon, color: serviceColor, size: 23),
                  ),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Detail Teks Status & Driver
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: serviceColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            serviceTitle,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            statusHeadline,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textMain),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subInfo,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Tombol Daftar (Jika Multi-Order)
              if (isMultiOrder && onOpenList != null) ...[
                InkWell(
                  onTap: onOpenList,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Icon(Icons.format_list_bulleted_rounded, size: 16, color: AppTheme.primaryNavy),
                  ),
                ),
              ],

              // Tombol Lacak Aksi
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: serviceColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isUnpaidQris ? 'Bayar QR' : 'Lacak',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isUnpaidQris ? const Color(0xFF92400E) : serviceColor,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      isUnpaidQris ? Icons.qr_code_rounded : Icons.arrow_forward_ios_rounded,
                      size: isUnpaidQris ? 13 : 11,
                      color: isUnpaidQris ? const Color(0xFF92400E) : serviceColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllActiveOrdersSheet(BuildContext context, List<dynamic> orders) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).padding.bottom + 16,
            top: 12,
            left: 18,
            right: 18,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNavy.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.layers_rounded, color: AppTheme.primaryNavy, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Pesanan Berlangsung',
                              style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Text(
                                '${orders.length} Aktif',
                                style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ketuk pesanan untuk membuka rute di peta',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // List of Orders
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.52,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: orders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, index) {
                    final item = orders[index];
                    return _buildOrderListItem(ctx, item, index + 1);
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Button "+ Pesan Layanan Lain"
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    controller.changePage(0);
                    Get.snackbar(
                      'Pesan Baru',
                      'Silakan pilih layanan di beranda untuk memesan lagi tanpa mengganggu pesanan yang sedang berjalan.',
                      backgroundColor: AppTheme.primaryNavy,
                      colorText: Colors.white,
                      duration: const Duration(seconds: 3),
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: const Text('Pesan Layanan Lainnya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderListItem(BuildContext ctx, dynamic order, int index) {
    bool isFood = (order['order_family'] == 'food') || order.containsKey('merchant_name') || order.containsKey('food_total');
    final bool isUnpaidQris = (order['payment_method'] ?? '').toString().toLowerCase() == 'qris' &&
        (order['payment_status'] ?? '').toString().toLowerCase() != 'paid';

    String serviceType = (order['service_type'] ?? (isFood ? 'food' : 'motor')).toString().toLowerCase();
    String status = (order['status'] ?? 'pending').toString().toLowerCase();
    String dVehicle = (order['driver_vehicle_type'] ?? order['vehicle_type'] ?? '').toString().toLowerCase();
    bool isCarService = serviceType == 'mobil' || serviceType == 'car' || serviceType == 'car_premium' ||
                        dVehicle.contains('mobil') || dVehicle.contains('car');

    String serviceTitle = 'Mai-Ride';
    IconData serviceIcon = Icons.two_wheeler;
    Color serviceColor = AppTheme.primaryNavy;

    bool isOrderMart = (order['order_type'] ?? '').toString().toLowerCase() == 'mart' || serviceType == 'mart';

    if (isOrderMart) {
      serviceTitle = 'Mai-Mart';
      serviceIcon = Icons.storefront;
      serviceColor = Colors.teal;
    } else if (isFood || serviceType == 'food') {
      serviceTitle = 'Mai-Food';
      serviceIcon = Icons.lunch_dining;
      serviceColor = Colors.deepOrange;
    } else if (serviceType == 'mai_send_motor' || serviceType == 'send') {
      serviceTitle = 'Mai-Send';
      serviceIcon = Icons.local_shipping;
      serviceColor = Colors.purple;
    } else if (serviceType == 'mai_titip' || serviceType == 'titip') {
      serviceTitle = 'Mai-Titip';
      serviceIcon = Icons.shopping_basket;
      serviceColor = Colors.green.shade700;
    } else if (isCarService) {
      serviceTitle = 'Mai-Car';
      serviceIcon = Icons.directions_car;
      serviceColor = const Color(0xFF0066CC);
    }

    String statusText = 'Sedang Berjalan';
    String subInfo = '';
    double priceVal = double.tryParse((order['total_price'] ?? order['price'] ?? 0).toString()) ?? 0;

    if (isFood) {
      String merchantName = order['merchant_name'] ?? (isOrderMart ? 'Toko' : 'Restoran');
      subInfo = merchantName;
      if (isUnpaidQris) {
        statusText = 'Menunggu Pembayaran QRIS';
      } else if (status == 'pending') {
        statusText = 'Menunggu Konfirmasi Resto';
      } else if (status == 'accepted_by_merchant' || status == 'processing') {
        statusText = isOrderMart ? 'Sedang Dikemas' : 'Sedang Dimasak';
      } else if (status == 'ready' || status == 'driver_assigned' || status == 'accepted') {
        statusText = 'Driver Menuju Resto';
      } else if (status == 'driver_at_merchant') {
        statusText = 'Driver di Lokasi Resto';
      } else if (status == 'delivering' || status == 'in_progress') {
        statusText = 'Pesanan Sedang Diantar';
      }
    } else {
      subInfo = order['dropoff_address'] ?? 'Menuju Lokasi Tujuan';
      if (isUnpaidQris) {
        statusText = 'Menunggu Pembayaran QRIS';
      } else if (status == 'pending') {
        statusText = 'Mencari Pengemudi';
      } else if (status == 'accepted') {
        statusText = 'Driver Menuju Penjemputan';
      } else if (status == 'arrived') {
        statusText = 'Driver Tiba di Titik Jemput';
      } else if (status == 'in_progress') {
        statusText = 'Dalam Perjalanan';
      }
    }

    return InkWell(
      onTap: () {
        Navigator.pop(ctx);
        if (isFood) {
          Get.toNamed('/food/tracking', arguments: {'order_id': order['id']});
        } else {
          Get.toNamed('/order-tracking', arguments: {'order_id': order['id']});
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: serviceColor.withValues(alpha: 0.25), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: serviceColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(serviceIcon, color: serviceColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: serviceColor,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          serviceTitle,
                          style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          statusText,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.textMain),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subInfo,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (priceVal > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      Formatter.currency(priceVal),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: serviceColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isUnpaidQris ? 'Bayar QR' : 'Lacak',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: isUnpaidQris ? const Color(0xFF92400E) : serviceColor,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    isUnpaidQris ? Icons.qr_code_rounded : Icons.arrow_forward_ios_rounded,
                    size: 10,
                    color: isUnpaidQris ? const Color(0xFF92400E) : serviceColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
