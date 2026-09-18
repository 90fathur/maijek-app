import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import '../../core/contact_helper.dart';
import '../../core/utils.dart';
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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          
          // Info Area (Floating Bottom)
          Positioned(
            bottom: 24, left: 16, right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 5))],
                  ),
              child: Obx(() {
                if (trackingController.status.value == 'pending') {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        (trackingController.serviceType.value.contains('car') || trackingController.serviceType.value.contains('mobil'))
                            ? 'Mencari Driver MaiCar...'
                            : 'Mencari Driver MaiRide...',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        (trackingController.serviceType.value.contains('car') || trackingController.serviceType.value.contains('mobil'))
                            ? 'Mohon tunggu, kami sedang mencarikan\ndriver mobil terbaik di sekitar Anda.'
                            : 'Mohon tunggu, kami sedang mencarikan\ndriver motor terbaik di sekitar Anda.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: AppTheme.textMuted),
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
                } else {
                  var driver = trackingController.driverData.value;
                  final rawV = (driver?['vehicle_type'] ?? trackingController.serviceType.value).toString().toLowerCase();
                  final bool isCar = rawV.contains('car') || rawV.contains('mobil');
                  final String vehicleType = isCar ? 'Mobil' : 'Motor';
                  final String serviceLabel = isCar ? 'MaiCar' : 'MaiRide';
                  final Color vehicleThemeColor = isCar ? const Color(0xFF0066CC) : AppTheme.primaryNavy;
                  String dName = driver?['name'] ?? 'Driver $serviceLabel';
                  String? dPhone = driver?['phone'];

                  return Column(
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
                          IconButton(
                            icon: const Icon(Icons.more_vert, color: Colors.grey),
                            tooltip: 'Opsi Kontak',
                            padding: const EdgeInsets.all(6),
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

                      // KARTU KHUSUS KENDARAAN (Plat Nomor Jelas & Menonjol + Merk Kendaraan + Kapasitas)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isCar ? const Color(0xFFF0F7FF) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isCar ? const Color(0xFFBAE6FD) : const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            // 1. BADGE PLAT NOMOR (Desain Plat Otentik & Sangat Kontras)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A), // Dark slate solid
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(color: const Color(0xFF334155), width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1.5),
                                  ),
                                ],
                              ),
                              child: Text(
                                (driver?['vehicle_plate'] != null && driver!['vehicle_plate'].toString().trim().isNotEmpty)
                                    ? driver['vehicle_plate'].toString().trim()
                                    : (isCar ? 'PLAT MOBIL' : 'PLAT MOTOR'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  letterSpacing: 1.1,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // 2. MERK KENDARAAN & KAPASITAS
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
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Divider(),
                      ),
                      Container(
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
                      ),
                      const SizedBox(height: 12),
                      // BADGE PEMBAYARAN & RINCIAN TARIF
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          color: trackingController.paymentMethod.value == 'maipay' ? AppTheme.primaryNavy : Colors.green.shade600,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  trackingController.paymentMethod.value == 'maipay' ? Icons.verified_user : Icons.money, 
                                  color: Colors.white, size: 18
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      trackingController.paymentMethod.value == 'maipay' ? 'LUNAS VIA MAI-PAY' : 'PEMBAYARAN TUNAI',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (trackingController.orderPrice.value > 0) ...[
                              const SizedBox(height: 6),
                              Text(
                                trackingController.paymentMethod.value == 'maipay'
                                    ? 'Total: ${Formatter.currency(trackingController.orderPrice.value)}'
                                    : 'Siapkan Tunai: ${Formatter.currency(trackingController.orderPrice.value)}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              if (trackingController.discountAmount.value > 0) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Hemat ${Formatter.currency(trackingController.discountAmount.value)} dengan Promo (${trackingController.promoCode.value.isNotEmpty ? trackingController.promoCode.value : "Maijek"})',
                                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                      if (trackingController.paymentMethod.value != 'maipay' &&
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
                    onTap: () => trackingController.showOverview(),
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
