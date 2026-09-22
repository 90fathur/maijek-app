import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_update/in_app_update.dart';
import '../../core/theme.dart';
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
    final rideOrder = homeController.activeRideOrder.value;
    final foodOrder = homeController.activeFoodOrder.value;

    if (rideOrder == null && foodOrder == null) {
      return const SizedBox.shrink();
    }

    bool isFood = foodOrder != null;
    dynamic order = isFood ? foodOrder : rideOrder;

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

      if (status == 'pending') {
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

      if (status == 'pending') {
        statusHeadline = isCarService ? 'Mencari driver Mai-Car terdekat...' : 'Mencari pengemudi terdekat...';
        subInfo = isCarService
            ? 'Menghubungkan ke armada mobil di sekitar Anda'
            : (serviceType == 'mai_send_motor'
                ? 'Menghubungkan ke armada kurir paket'
                : (serviceType == 'mai_titip' ? 'Menghubungkan ke driver jastip' : 'Menghubungkan ke driver di sekitar Anda'));
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
                      'Lacak',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: serviceColor,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: serviceColor,
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
}
