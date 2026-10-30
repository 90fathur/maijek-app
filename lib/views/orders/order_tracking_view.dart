import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import '../../core/contact_helper.dart';
import '../../core/utils.dart';
import '../../core/map_style.dart';
import '../../controllers/order_tracking_controller.dart';
import 'chat_view.dart';

class OrderTrackingView extends StatefulWidget {
  const OrderTrackingView({super.key});

  @override
  State<OrderTrackingView> createState() => _OrderTrackingViewState();
}

class _OrderTrackingViewState extends State<OrderTrackingView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late OrderTrackingController trackingController;
  bool _isCardCollapsed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    // Get order ID from arguments
    String orderId = Get.arguments['order_id'].toString();
    trackingController = Get.put(OrderTrackingController(orderId));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (trackingController.paymentMethod.value == 'qris' &&
          trackingController.paymentStatus.value == 'unpaid') {
        trackingController.showQrisModal(context);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: trackingController.status.value != 'pending',
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Get.dialog(
          AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Sedang Mencari Driver', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            content: const Text(
              'Jangan keluar dulu ya! Mungkin butuh waktu 1-2 menit untuk mencari driver yang cocok. Jika Anda kembali ke Beranda, pesanan tetap berjalan di latar belakang.',
              style: TextStyle(fontSize: 13.5, color: Colors.black87, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back();
                  Get.offAllNamed('/home');
                },
                child: const Text('Ke Beranda', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
              ),
              ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Tetap Tunggu'),
              ),
            ],
          ),
        );
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: Stack(
        children: [
          // Map / Radar Area (Full screen)
          Obx(() {
            if (trackingController.status.value == 'pending') {
              return Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (_, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        _buildRadarCircle(300, 0.1),
                        _buildRadarCircle(220, 0.2),
                        _buildRadarCircle(140, 0.3),
                        Obx(() {
                          final rawV = (trackingController.driverData.value?['vehicle_type'] ?? trackingController.serviceType.value).toString().toLowerCase();
                          final isCar = rawV.contains('car') || rawV.contains('mobil');
                          return Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              color: isCar ? const Color(0xFF0066CC) : AppTheme.primaryBlue,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: isCar ? const Color(0xFF0066CC) : AppTheme.primaryBlue, blurRadius: 20, spreadRadius: 5)],
                            ),
                            child: Icon(isCar ? Icons.directions_car_rounded : Icons.two_wheeler_rounded, color: Colors.white, size: 40),
                          );
                        }),
                      ],
                    );
                  },
                ),
              );
            } else {
              return GoogleMap(
                style: MapStyle.cleanStyle,
                initialCameraPosition: CameraPosition(
                  target: trackingController.driverLocation.value ?? trackingController.pickupLocation ?? const LatLng(-6.200000, 106.816666),
                  zoom: 16,
                ),
                zoomControlsEnabled: false,
                myLocationEnabled: true,
                markers: Set<Marker>.of(trackingController.markers.values),
                polylines: Set<Polyline>.of(trackingController.polylines.values),
                onCameraMoveStarted: () => trackingController.onUserDragMap(),
                onMapCreated: (controller) => trackingController.setMapController(controller),
              );
            }
          }),
          
          // Header (Floating Top)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16, right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        height: 28,
                        errorBuilder: (context, error, stackTrace) => const Row(
                          children: [
                            Icon(Icons.two_wheeler, color: AppTheme.primaryNavy, size: 26),
                            SizedBox(width: 8),
                            Text('Maijek', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy)),
                          ],
                        ),
                      ),
                      Obx(() {
                        final rawV = (trackingController.driverData.value?['vehicle_type'] ?? trackingController.serviceType.value).toString().toLowerCase();
                        final isCar = rawV.contains('car') || rawV.contains('mobil');
                        final isSend = rawV.contains('send');
                        final isTitip = rawV.contains('titip');

                        String label = 'MaiRide';
                        IconData icon = Icons.two_wheeler_rounded;
                        Color color = AppTheme.primaryNavy;

                        if (isCar) {
                          label = 'MaiCar';
                          icon = Icons.directions_car_rounded;
                          color = const Color(0xFF0066CC);
                        } else if (isSend) {
                          label = 'MaiSend';
                          icon = Icons.local_shipping_rounded;
                          color = const Color(0xFF0F766E);
                        } else if (isTitip) {
                          label = 'MaiTitip';
                          icon = Icons.shopping_basket_rounded;
                          color = Colors.green.shade700;
                        }

                        return Container(
                          margin: const EdgeInsets.only(left: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: color.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 16, color: color),
                              const SizedBox(width: 4),
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.share_rounded, color: AppTheme.primaryNavy),
                        tooltip: 'Bagikan Perjalanan',
                        onPressed: () => _shareTrip(context),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Floating Pill "Mode Peta Penuh" ketika kartu diminimalkan
          Obx(() {
            if (trackingController.status.value == 'pending' || !_isCardCollapsed) {
              return const SizedBox.shrink();
            }
            return Positioned(
              bottom: 108,
              left: 16,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _isCardCollapsed = false),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNavy,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryNavy.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.expand_less_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Peta Penuh • Ketuk untuk Detail Driver',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          // Info Area (Floating Bottom - Collapsible / Minimizable)
          Positioned(
            bottom: 24, left: 16, right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: _isCardCollapsed ? 14 : 16,
                    vertical: _isCardCollapsed ? 10 : 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.5),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 5))],
                  ),
                  child: Obx(() {
                    if (trackingController.status.value == 'pending') {
                      return _buildPendingCard(context);
                    } else {
                      var driver = trackingController.driverData.value;
                      final rawV = (driver?['vehicle_type'] ?? trackingController.serviceType.value).toString().toLowerCase();
                      final bool isCar = rawV.contains('car') || rawV.contains('mobil');
                      final String vehicleType = isCar ? 'Mobil' : 'Motor';
                      final String serviceLabel = isCar ? 'MaiCar' : 'MaiRide';
                      final Color vehicleThemeColor = isCar ? const Color(0xFF0066CC) : AppTheme.primaryNavy;
                      String dName = driver?['name'] ?? 'Driver $serviceLabel';
                      String? dPhone = driver?['phone'];

                      if (_isCardCollapsed) {
                        return _buildCollapsedCard(
                          driver,
                          isCar,
                          vehicleType,
                          serviceLabel,
                          vehicleThemeColor,
                          dName,
                          dPhone,
                        );
                      } else {
                        return _buildExpandedCard(
                          driver,
                          isCar,
                          vehicleType,
                          serviceLabel,
                          vehicleThemeColor,
                          dName,
                          dPhone,
                          context,
                        );
                      }
                    }
                  }),
                ),
              ),
            ),
          ),
          // Tombol Kontrol Navigasi & Perspektif Jalan (Floating Controls di kanan atas)
          Obx(() {
            if (trackingController.status.value == 'pending') {
              return const SizedBox.shrink();
            }
            return Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Tombol Fokus / Ikuti Driver
                  _buildMapFloatingButton(
                    icon: trackingController.isAutoFollow.value
                        ? Icons.navigation_rounded
                        : Icons.my_location_rounded,
                    tooltip: trackingController.isAutoFollow.value
                        ? 'Kamera sedang mengikuti arah driver'
                        : 'Pusatkan kamera ke driver',
                    isActive: trackingController.isAutoFollow.value,
                    onTap: () => trackingController.focusOnDriver(),
                  ),
                  const SizedBox(height: 8),

                  // 2. Tombol Toggle Perspektif 3D ("Kayak Jalan") / 2D (Peta Biasa)
                  _buildMapFloatingButton(
                    icon: trackingController.isNavigationPerspective.value
                        ? Icons.view_in_ar_rounded
                        : Icons.map_outlined,
                    label: trackingController.isNavigationPerspective.value ? '3D' : '2D',
                    tooltip: trackingController.isNavigationPerspective.value
                        ? 'Mode 3D Navigasi Jalan (Aktif)'
                        : 'Mode 2D Peta Datar',
                    isActive: trackingController.isNavigationPerspective.value,
                    onTap: () => trackingController.togglePerspective(),
                  ),
                  const SizedBox(height: 8),

                  // 3. Tombol Tinjau Keseluruhan Rute (Overview)
                  _buildMapFloatingButton(
                    icon: Icons.alt_route_rounded,
                    tooltip: 'Lihat Semua Rute Perjalanan',
                    isActive: false,
                    onTap: () {
                      setState(() => _isCardCollapsed = true);
                      trackingController.showOverview();
                    },
                  ),
                ],
              ),
            );
          }),

          // Floating Pill "Pusatkan ke Driver" ketika pengguna menggeser peta secara manual
          Obx(() {
            if (trackingController.status.value == 'pending' || trackingController.isAutoFollow.value) {
              return const SizedBox.shrink();
            }
            return Positioned(
              top: MediaQuery.of(context).padding.top + 84,
              left: 16,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => trackingController.focusOnDriver(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNavy,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryNavy.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.navigation_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Pusatkan ke Driver (3D Jalan)',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    ),
  );
}

  Widget _buildMapFloatingButton({
    required IconData icon,
    required VoidCallback onTap,
    String? label,
    String? tooltip,
    bool isActive = false,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isActive ? AppTheme.primaryNavy : Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isActive ? AppTheme.primaryNavy : Colors.white.withValues(alpha: 0.6),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: label != null ? 18 : 22,
                  color: isActive ? Colors.white : AppTheme.primaryNavy,
                ),
                if (label != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: isActive ? Colors.white : AppTheme.primaryNavy,
                      height: 1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingCard(BuildContext context) {
    final rawService = trackingController.serviceType.value.toLowerCase();
    final isCar = rawService.contains('car') || rawService.contains('mobil');
    final isSend = rawService.contains('send');
    final isTitip = rawService.contains('titip');

    String searchingTitle = 'Mencari Driver MaiRide...';
    String searchingSubtitle = 'Mohon tunggu, kami sedang mencarikan\ndriver motor terbaik di sekitar Anda.';
    if (isCar) {
      searchingTitle = 'Mencari Driver MaiCar...';
      searchingSubtitle = 'Mohon tunggu, kami sedang mencarikan\ndriver mobil terbaik di sekitar Anda.';
    } else if (isSend) {
      searchingTitle = 'Mencari Kurir MaiSend...';
      searchingSubtitle = 'Mohon tunggu, kami sedang mencarikan\nkurir terbaik untuk mengantar paket Anda.';
    } else if (isTitip) {
      searchingTitle = 'Mencari Driver MaiTitip...';
      searchingSubtitle = 'Mohon tunggu, kami sedang mencarikan\ndriver jastip terbaik untuk belanjaan Anda.';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          searchingTitle,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textMain),
        ),
        const SizedBox(height: 8),
        Text(
          searchingSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 16),
        // Kartu Edukasi / Peringatan Cerdas: Jangan Keluar Dulu
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD97706).withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 1),
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  size: 18,
                  color: Color(0xFFB45309),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jangan keluar dulu ya!',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF92400E),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Mungkin butuh waktu 1-2 menit untuk mencari driver yang cocok di sekitar Anda.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF78350F),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (trackingController.etaRangeText.value.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryNavy.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryNavy.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, size: 18, color: AppTheme.primaryNavy),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Estimasi Perjalanan: ${trackingController.etaRangeText.value} (${trackingController.etaArrivalClock.value})',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              Get.bottomSheet(
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Alasan Pembatalan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                      const SizedBox(height: 16),
                      ...['Menunggu terlalu lama', 'Titik jemput/tujuan salah', 'Berubah pikiran', 'Lainnya'].map((reason) => 
                        ListTile(
                          title: Text(reason, style: const TextStyle(color: AppTheme.textMuted)),
                          leading: const Icon(Icons.cancel_outlined, color: Colors.red),
                          onTap: () {
                            Get.back();
                            trackingController.cancelOrder(reason);
                          },
                        )
                      ),
                    ],
                  ),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Batalkan Pesanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsedCard(
    dynamic driver,
    bool isCar,
    String vehicleType,
    String serviceLabel,
    Color vehicleThemeColor,
    String dName,
    String? dPhone,
  ) {
    int unreadChat = int.tryParse(driver?['unread_count']?.toString() ?? '0') ?? 0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragEnd: (details) {
        // Swipe ke atas (velocity negatif) untuk memperluas kartu
        if (details.primaryVelocity != null && details.primaryVelocity! < -80) {
          setState(() => _isCardCollapsed = false);
        }
      },
      onTap: () => setState(() => _isCardCollapsed = false),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle pill
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              // Avatar driver dengan rating
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(1.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.accentGold, width: 1.5),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        ApiClient.getImageUrl(driver?['driver_photo']),
                        width: 38,
                        height: 38,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 38,
                          height: 38,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.person, color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade500,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.white, size: 8),
                          const SizedBox(width: 1),
                          Text(
                            driver?['driver_rating']?.toString() ?? '5.0',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 8.5, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              // Nama & Plat Kendaraan / Estimasi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMain,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (driver?['vehicle_plate'] != null && driver!['vehicle_plate'].toString().trim().isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              driver['vehicle_plate'].toString().toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 9.5,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            trackingController.isTitipOrder && trackingController.titipStatusTitle.value.isNotEmpty
                                ? trackingController.titipStatusTitle.value
                                : (trackingController.etaArrivalClock.value.isNotEmpty
                                    ? 'Tiba ~${trackingController.etaArrivalClock.value}'
                                    : (trackingController.etaRangeText.value.isNotEmpty
                                        ? trackingController.etaRangeText.value
                                        : serviceLabel)),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: trackingController.isTitipOrder ? Colors.teal.shade800 : AppTheme.primaryNavy,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Quick action: WhatsApp button
              Material(
                color: const Color(0xFF25D366).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () {
                    ContactHelper.openWhatsApp(
                      phone: dPhone,
                      name: dName,
                      orderId: trackingController.orderId,
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding: EdgeInsets.all(7),
                    child: Icon(Icons.chat, color: Color(0xFF25D366), size: 17),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Quick action: In-app Chat button with unread count
              Material(
                color: AppTheme.primaryNavy.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () {
                    Get.to(() => ChatView(
                      orderId: trackingController.orderId,
                      driverName: dName,
                      driverPhoto: driver?['driver_photo'],
                      driverPhone: dPhone,
                    ));
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: Badge(
                      isLabelVisible: unreadChat > 0,
                      label: Text('$unreadChat'),
                      child: const Icon(Icons.chat_bubble_outline, color: AppTheme.primaryNavy, size: 17),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Tombol Buka / Expand
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryNavy,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Buka',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.keyboard_arrow_up_rounded, size: 15, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedCard(
    dynamic driver,
    bool isCar,
    String vehicleType,
    String serviceLabel,
    Color vehicleThemeColor,
    String dName,
    String? dPhone,
    BuildContext context,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragEnd: (details) {
        // Swipe ke bawah untuk mengecilkan kartu
        if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
          setState(() => _isCardCollapsed = true);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle pill di bagian paling atas dengan teks petunjuk geser
          GestureDetector(
            onTap: () => setState(() => _isCardCollapsed = true),
            child: Container(
              padding: const EdgeInsets.only(top: 0, bottom: 8),
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.keyboard_arrow_down_rounded, size: 15, color: Colors.grey.shade600),
                      const SizedBox(width: 3),
                      Text(
                        'Geser ke bawah untuk melihat rute penuh',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.65,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Baris Profil Driver
                  Row(
                    children: [
              GestureDetector(
                onTap: () {
                  ContactHelper.showContactModal(
                    context,
                    name: dName,
                    phone: dPhone,
                    role: 'Driver $serviceLabel ($vehicleType)',
                    photoUrl: driver?['driver_photo'],
                    orderId: trackingController.orderId,
                    onChatApp: () {
                      Get.to(() => ChatView(
                        orderId: trackingController.orderId,
                        driverName: dName,
                        driverPhoto: driver?['driver_photo'],
                        driverPhone: dPhone,
                      ));
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.accentGold, width: 2),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      ApiClient.getImageUrl(driver?['driver_photo']),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 48,
                          height: 48,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.person, color: Colors.white, size: 28),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            dName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 14),
                              const SizedBox(width: 3),
                              Text(
                                driver?['driver_rating']?.toString() ?? '5.0',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber.shade900),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.phone_iphone_rounded, size: 13, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          (dPhone != null && dPhone.isNotEmpty) ? ContactHelper.formatDisplayPhone(dPhone) : '-',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Tombol Minimize Cepat
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey, size: 24),
                tooltip: 'Kecilkan Kartu',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => setState(() => _isCardCollapsed = true),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                tooltip: 'Opsi Kontak',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () {
                  ContactHelper.showContactModal(
                    context,
                    name: dName,
                    phone: dPhone,
                    role: 'Driver $vehicleType',
                    photoUrl: driver?['driver_photo'],
                    orderId: trackingController.orderId,
                    onChatApp: () {
                      Get.to(() => ChatView(
                        orderId: trackingController.orderId,
                        driverName: dName,
                        driverPhoto: driver?['driver_photo'],
                        driverPhone: dPhone,
                      ));
                    },
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Baris Plat Nomor & Tipe Kendaraan
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                // Plat Nomor
                if (driver?['vehicle_plate'] != null && driver!['vehicle_plate'].toString().trim().isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 1.5),
                        ),
                      ],
                    ),
                    child: Text(
                      driver['vehicle_plate'].toString().toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                // Merk & Tipe Kendaraan
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isCar ? Icons.directions_car_rounded : Icons.two_wheeler_rounded,
                            size: 15,
                            color: vehicleThemeColor,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              (driver?['vehicle_brand'] != null && driver!['vehicle_brand'].toString().trim().isNotEmpty)
                                  ? driver['vehicle_brand'].toString().trim()
                                  : (isCar ? 'Toyota Avanza' : 'Honda Beat'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textMain,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: vehicleThemeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              serviceLabel,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: vehicleThemeColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            isCar ? Icons.airline_seat_recline_normal_rounded : Icons.person_outline_rounded,
                            size: 13,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              isCar
                                  ? 'Kapasitas: ${driver?['vehicle_capacity'] ?? 4} Kursi'
                                  : 'Kapasitas: 1 Helm',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Baris 3 Tombol Hubungi Driver (Chat App, WhatsApp, Telepon GSM)
          Row(
            children: [
              // 1. Chat di Aplikasi (dengan unread badge)
              Expanded(
                child: _buildContactButton(
                  icon: Icons.chat_bubble_outline,
                  label: 'Chat',
                  color: AppTheme.primaryNavy,
                  badgeCount: driver?['unread_count'],
                  onTap: () {
                    Get.to(() => ChatView(
                      orderId: trackingController.orderId,
                      driverName: dName,
                      driverPhoto: driver?['driver_photo'],
                      driverPhone: dPhone,
                    ));
                  },
                ),
              ),
              const SizedBox(width: 8),

              // 2. Chat WhatsApp Langsung
              Expanded(
                child: _buildContactButton(
                  icon: Icons.chat,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () {
                    ContactHelper.openWhatsApp(
                      phone: dPhone,
                      name: dName,
                      orderId: trackingController.orderId,
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),

              // 3. Panggilan Telepon (GSM)
              Expanded(
                child: _buildContactButton(
                  icon: Icons.phone_in_talk,
                  label: 'Telepon',
                  color: Colors.blue.shade700,
                  onTap: () {
                    ContactHelper.makePhoneCall(dPhone);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tombol Keamanan: Bagikan Perjalanan via WhatsApp
          InkWell(
            onTap: () => _shareTrip(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_rounded, color: Colors.teal.shade700, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bagikan Perjalanan (Safety Share)',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade900,
                          ),
                        ),
                        Text(
                          'Kirim detail driver & rute ke keluarga via WhatsApp',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.teal.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 12, color: Colors.teal.shade700),
                ],
              ),
            ),
          ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(),
                  ),

                  // Status ETA Card
                  _buildStatusEtaCard(),
                  const SizedBox(height: 12),

                  // JIKA MAI-TITIP: Tampilkan Stepper Tahapan, Rincian Belanjaan, Foto Struk, & Tagihan Cerdas
                  if (trackingController.isTitipOrder) ...[
                    _buildTitipStepTracker(),
                    _buildTitipShoppingDetailsCard(),
                    _buildTitipReceiptCard(context),
                    _buildTitipPaymentCard(),
                  ] else ...[
                    _buildDefaultPaymentCard(driver, context),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // KOMPONEN STATUS & ETA
  // =========================================================================
  Widget _buildStatusEtaCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryNavy.withValues(alpha: 0.08),
            Colors.blue.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryNavy.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: AppTheme.primaryNavy, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  trackingController.etaTitle.value.isNotEmpty
                      ? trackingController.etaTitle.value
                      : (trackingController.status.value == 'accepted'
                          ? 'Driver Menuju Lokasi Anda'
                          : 'Dalam Perjalanan Menuju Tujuan'),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                ),
              ),
              if (trackingController.etaArrivalClock.value.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryNavy,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trackingController.etaArrivalClock.value,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          if (trackingController.etaSubtitle.value.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              trackingController.etaSubtitle.value,
              style: TextStyle(fontSize: 12, color: Colors.blue.shade900, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================================
  // STEPPER TAHAPAN JASTIP (1. Cari -> 2. Ke Toko -> 3. Belanja -> 4. Antar)
  // =========================================================================
  Widget _buildTitipStepTracker() {
    final int currentStep = trackingController.titipStep.value;
    final steps = [
      {'step': 1, 'title': 'Cari Kurir', 'icon': Icons.search_rounded},
      {'step': 2, 'title': 'Ke Toko', 'icon': Icons.storefront_rounded},
      {'step': 3, 'title': 'Di Toko', 'icon': Icons.shopping_bag_rounded},
      {'step': 4, 'title': 'Antar Belanja', 'icon': Icons.moped_rounded},
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PROSES BELANJA MAI-TITIP',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal.shade900, letterSpacing: 0.5),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.teal.shade700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Tahap $currentStep dari 4',
                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: steps.map((s) {
              final int sNum = s['step'] as int;
              final bool isDone = currentStep > sNum;
              final bool isCurrent = currentStep == sNum;
              final Color stepColor = isDone
                  ? Colors.green.shade700
                  : (isCurrent ? Colors.teal.shade800 : Colors.grey.shade400);

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isCurrent ? Colors.teal.shade700 : (isDone ? Colors.green.shade100 : Colors.white),
                              shape: BoxShape.circle,
                              border: Border.all(color: stepColor, width: 2),
                            ),
                            child: Icon(
                              isDone ? Icons.check : (s['icon'] as IconData),
                              size: 16,
                              color: isCurrent ? Colors.white : (isDone ? Colors.green.shade800 : Colors.grey.shade500),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s['title'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                              color: stepColor,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (sNum < 4)
                      Container(
                        width: 12,
                        height: 2,
                        color: isDone ? Colors.green.shade700 : Colors.grey.shade300,
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // KARTU DETAIL DAFTAR BELANJAAN JASTIP
  // =========================================================================
  Widget _buildTitipShoppingDetailsCard() {
    final items = trackingController.parsedShoppingItems;
    final double estBudget = trackingController.titipItemPrice.value;
    final String rawNotes = trackingController.notes.value.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_bag_outlined, color: Colors.teal.shade800, size: 18),
              const SizedBox(width: 8),
              Text(
                'Daftar Barang Titipan (${items.length} Item)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal.shade900),
              ),
            ],
          ),
          const Divider(height: 14),
          if (items.isNotEmpty) ...[
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold, fontSize: 13)),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                )),
          ] else ...[
            Text(
              trackingController.itemDescription.value.isNotEmpty
                  ? trackingController.itemDescription.value
                  : 'Tidak ada daftar belanja tertulis.',
              style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
            ),
          ],
          if (rawNotes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note_alt_outlined, size: 14, color: Colors.amber.shade900),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Catatan Anda: $rawNotes',
                      style: TextStyle(fontSize: 11, color: Colors.amber.shade900, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.storefront, size: 15, color: Colors.teal.shade700),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Toko: ${trackingController.pickupAddress.value}',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.home, size: 15, color: Colors.red.shade700),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Antar ke: ${trackingController.dropoffAddress.value}',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (estBudget > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Perkiraan Biaya Belanja:', style: TextStyle(fontSize: 11.5, color: Colors.black87)),
                  Text(
                    Formatter.currency(estBudget),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================================
  // KARTU BUKTI STRUK KASIR RESMI (JIKA SUDAH DIUNGGAH DRIVER)
  // =========================================================================
  Widget _buildTitipReceiptCard(BuildContext context) {
    final String receiptImg = trackingController.titipReceiptImgUrl.value;
    final double totalCost = trackingController.titipTotalCost.value;

    if (receiptImg.isEmpty && totalCost <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade300, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_rounded, color: Colors.green.shade800, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'STRUK KASIR RESMI DARI TOKO',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.green.shade900),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Sudah Dibeli ✓', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Uang Belanja Asli:', style: TextStyle(fontSize: 12.5, color: Colors.black87)),
              Text(
                Formatter.currency(totalCost > 0 ? totalCost : trackingController.titipItemPrice.value),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green.shade900),
              ),
            ],
          ),
          if (receiptImg.isNotEmpty) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => Dialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                           padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Foto Struk Kasir Asli', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              IconButton(
                                icon: const Icon(Icons.close),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                            ],
                          ),
                        ),
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                          child: Image.network(
                            receiptImg,
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) => const Padding(
                              padding: EdgeInsets.all(24),
                              child: Text('Gagal memuat gambar struk'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        receiptImg,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          width: 44,
                          height: 44,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.receipt, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Lihat Foto Struk Kasir', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                          Text('Ketuk untuk memperbesar foto struk toko', style: TextStyle(fontSize: 10.5, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const Icon(Icons.zoom_in, color: Colors.green, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================================
  // RINCIAN TAGIHAN KHUSUS MAI-TITIP (ONGKIR + BELANJA TALANGAN)
  // =========================================================================
  Widget _buildTitipPaymentCard() {
    final bool isMaipay = trackingController.paymentMethod.value == 'maipay';
    final double fare = trackingController.orderPrice.value;
    final double belanja = trackingController.titipTotalCost.value > 0
        ? trackingController.titipTotalCost.value
        : trackingController.titipItemPrice.value;
    final double totalCash = isMaipay ? belanja : (fare + belanja);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isMaipay ? Colors.amber.shade50 : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isMaipay ? Colors.amber.shade400 : Colors.green.shade300, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMaipay ? 'TAGIHAN UANG BELANJA TUNAI' : 'TOTAL PEMBAYARAN TUNAI',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        color: isMaipay ? Colors.amber.shade900 : Colors.green.shade800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isMaipay
                          ? 'Ongkir Lunas. Siapkan uang belanjaan tunai ke driver'
                          : 'Siapkan uang tunai pas saat pesanan belanja tiba',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              Text(
                Formatter.currency(totalCash),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isMaipay ? Colors.amber.shade900 : Colors.green.shade800,
                ),
              ),
            ],
          ),
          const Divider(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ongkir Layanan Jastip', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700)),
              Text(
                isMaipay ? 'Lunas (Mai-Pay)' : Formatter.currency(fare),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: isMaipay ? Colors.blue.shade800 : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Uang Belanja Struk', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700)),
              Text(
                Formatter.currency(belanja),
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // RINCIAN PEMBAYARAN DEFAULT (MAIRIDE / MAICAR / MAISEND)
  // =========================================================================
  Widget _buildDefaultPaymentCard(dynamic driver, BuildContext context) {
    final pm = trackingController.paymentMethod.value;
    final bool isMaipay = pm == 'maipay';
    final bool isQris = pm == 'qris';
    final bool isPaid = trackingController.paymentStatus.value == 'paid';

    Color cardColor = isQris
        ? (isPaid ? Colors.indigo.shade800 : Colors.deepOrange.shade700)
        : (isMaipay ? AppTheme.primaryNavy : Colors.green.shade600);

    String badgeTitle = isQris
        ? (isPaid ? 'LUNAS VIA QRIS' : 'MENUNGGU PEMBAYARAN QRIS')
        : (isMaipay ? 'LUNAS VIA MAI-PAY' : 'PEMBAYARAN TUNAI');

    IconData badgeIcon = isQris
        ? (isPaid ? Icons.qr_code_2 : Icons.pending_actions)
        : (isMaipay ? Icons.verified_user : Icons.money);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(badgeIcon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        badgeTitle,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
              if (trackingController.orderPrice.value > 0) ...[
                const SizedBox(height: 6),
                Text(
                  (isMaipay || isQris)
                      ? 'Total: ${Formatter.currency(trackingController.orderPrice.value)}'
                      : 'Siapkan Tunai: ${Formatter.currency(trackingController.orderPrice.value)}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                if (trackingController.discountAmount.value > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Hemat ${Formatter.currency(trackingController.discountAmount.value)} dengan Promo (${trackingController.promoCode.value.isNotEmpty ? trackingController.promoCode.value : "Maijek"})',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ],
          ),
        ),
        if (isQris && !isPaid) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => trackingController.showQrisModal(context),
              icon: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 18),
              label: const Text(
                'BAYAR QRIS SEKARANG (NOTIVGO)',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 1,
              ),
            ),
          ),
        ],
        if (!isMaipay && !isQris &&
            (driver != null &&
                (driver['driver_qris_is_active'] == 1 || driver['driver_qris_is_active'] == true) &&
                driver['driver_qris_image'] != null &&
                driver['driver_qris_image'].toString().isNotEmpty)) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showPassengerQrisDialog(context, driver),
              icon: const Icon(Icons.qr_code_2, color: Colors.teal),
              label: const Text('Bayar Pakai QRIS Driver', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.teal),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRadarCircle(double size, double opacity) {
    double scale = 1.0 + (_controller.value * 0.5);
    double currentOpacity = opacity * (1.0 - _controller.value);
    
    return Transform.scale(
      scale: scale,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: AppTheme.primaryNavy.withValues(alpha: currentOpacity),
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.primaryNavy.withValues(alpha: opacity), width: 1),
        ),
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    dynamic badgeCount,
  }) {
    int count = int.tryParse(badgeCount?.toString() ?? '0') ?? 0;
    return Material(
      color: color.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Badge(
                isLabelVisible: count > 0,
                label: Text('$count'),
                child: Icon(icon, color: color, size: 15),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _showPassengerQrisDialog(BuildContext context, Map? driver) {
    if (driver == null) return;
    String? rawImage = driver['driver_qris_image_url'] ?? driver['driver_qris_image'];
    if (rawImage == null || rawImage.toString().trim().isEmpty) return;
    String fullUrl = rawImage.toString().startsWith('http')
        ? rawImage.toString()
        : ApiClient.getImageUrl(rawImage.toString());
    String merchantName = driver['driver_qris_merchant_name'] ?? 'Driver MaiJek';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.qr_code_2, color: Colors.teal),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'QRIS Driver',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Scan QRIS ini untuk membayar langsung ke $merchantName:',
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.network(
                fullUrl,
                width: 220,
                height: 220,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Text('Gagal memuat gambar QRIS', style: TextStyle(color: Colors.red)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              merchantName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Tunjukkan bukti transfer ke Driver sebelum turun.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _shareTrip(BuildContext context) {
    var driver = trackingController.driverData.value;
    String rawService = (trackingController.serviceType.value.isEmpty 
        ? (driver?['vehicle_type'] ?? '') 
        : trackingController.serviceType.value).toString().toLowerCase().trim();
    String service;
    if (rawService.contains('car') || rawService.contains('mobil')) {
      service = 'MaiCar (Mobil)';
    } else if (rawService.contains('send')) {
      service = 'MaiSend (Kirim Barang)';
    } else if (rawService.contains('titip')) {
      service = 'MaiTitip (Titip Belanja)';
    } else {
      service = 'MaiRide (Motor)';
    }

    ContactHelper.shareTripViaWhatsApp(
      context: context,
      serviceName: service,
      orderId: trackingController.orderId.toString(),
      driverName: driver?['name'],
      vehiclePlate: driver?['vehicle_plate'],
      vehicleType: driver?['vehicle_type'],
      vehicleBrand: driver?['vehicle_brand'],
      vehicleCapacity: driver?['vehicle_capacity'],
      pickupAddress: trackingController.pickupAddress.value,
      dropoffAddress: trackingController.dropoffAddress.value,
      statusText: trackingController.etaTitle.value.isNotEmpty
          ? trackingController.etaTitle.value
          : (trackingController.status.value == 'accepted'
              ? 'Driver Menuju Lokasi Anda'
              : 'Dalam Perjalanan Menuju Tujuan'),
      etaText: trackingController.etaArrivalClock.value.isNotEmpty
          ? '${trackingController.etaArrivalClock.value} (${trackingController.etaRangeText.value})'
          : trackingController.etaRangeText.value,
    );
  }
}
