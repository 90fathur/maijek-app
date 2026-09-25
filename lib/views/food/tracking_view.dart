import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../controllers/food_tracking_controller.dart';
import '../../controllers/home_controller.dart';
import '../../core/theme.dart';
import '../../core/map_style.dart';
import '../orders/chat_view.dart';
import '../../core/api_client.dart';
import '../../core/contact_helper.dart';
import 'merchants_view.dart';

class FoodTrackingView extends StatefulWidget {
  const FoodTrackingView({super.key});

  @override
  State<FoodTrackingView> createState() => _FoodTrackingViewState();
}

class _FoodTrackingViewState extends State<FoodTrackingView> with SingleTickerProviderStateMixin {
  late FoodTrackingController trackingController;
  late AnimationController _radarController;
  bool _isCardCollapsed = false;

  void _backToHome() {
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().checkActiveOrder();
    }
    Get.offAllNamed('/home');
  }

  @override
  void initState() {
    super.initState();
    trackingController = Get.put(FoodTrackingController());
    _radarController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  Widget _buildRadarCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primaryBlue.withOpacity(opacity),
      ),
    );
  }

  String _getStatusTitle(String status, [bool isMart = false]) {
    switch (status) {
      case 'pending': return isMart ? 'Menunggu Konfirmasi Toko' : 'Menunggu Konfirmasi Resto';
      case 'accepted_by_merchant': return isMart ? 'Toko Menerima Pesanan' : 'Restoran Menerima Pesanan';
      case 'processing': return isMart ? 'Sedang Disiapkan Toko' : 'Restoran Sedang Memasak';
      case 'ready': return isMart ? 'Pesanan Siap Diambil' : 'Makanan Siap Diambil';
      case 'accepted': return isMart ? 'Driver Menuju Toko' : 'Driver Menuju Restoran';
      case 'driver_assigned': return isMart ? 'Driver Menuju Toko' : 'Driver Menuju Restoran';
      case 'driver_at_merchant': return isMart ? 'Driver Sudah di Toko' : 'Driver Sudah di Restoran';
      case 'delivering': return 'Driver Mengantar Pesanan';
      case 'in_progress': return 'Driver Mengantar Pesanan';
      case 'delivered': return 'Pesanan Selesai';
      case 'completed': return 'Pesanan Selesai';
      case 'cancelled': return isMart ? 'Pesanan Ditolak Toko' : 'Pesanan Ditolak Restoran';
      default: return 'Memproses...';
    }
  }

  String _getStatusSubtitle(String status, [bool isMart = false, String? cancelReason]) {
    switch (status) {
      case 'pending':
        return isMart ? 'Pesanan telah terkirim ke toko, menunggu konfirmasi' : 'Pesanan telah terkirim ke resto, menunggu konfirmasi';
      case 'accepted_by_merchant':
        return isMart ? 'Toko telah menerima & mengonfirmasi pesanan Anda' : 'Restoran telah menerima & mengonfirmasi pesanan Anda';
      case 'processing':
        return isMart ? 'Toko sedang menyiapkan barang belanjaan Anda' : 'Restoran sedang menyiapkan & memasak pesanan Anda';
      case 'ready':
        return isMart ? 'Belanjaan siap diambil oleh Driver' : 'Makanan siap diambil oleh Driver';
      case 'accepted':
      case 'driver_assigned':
        return isMart ? 'Driver telah menerima dan menuju toko' : 'Driver telah menerima dan menuju restoran';
      case 'driver_at_merchant':
        return isMart ? 'Driver sudah di toko menunggu pesanan' : 'Driver sudah di restoran menunggu makanan';
      case 'delivering':
      case 'in_progress':
        return 'Driver sedang mengantar pesanan ke lokasi Anda';
      case 'delivered':
      case 'completed':
        return isMart ? 'Pesanan telah sampai. Terima kasih telah berbelanja!' : 'Pesanan telah sampai. Selamat menikmati!';
      case 'cancelled':
        if (cancelReason != null && cancelReason.trim().isNotEmpty) {
          return 'Alasan: $cancelReason';
        }
        return isMart ? 'Toko tidak dapat memproses pesanan ini' : 'Restoran tidak dapat memproses pesanan ini';
      default:
        return 'Sedang diproses...';
    }
  }

  Widget _buildCancellationCard(dynamic order, bool isMart) {
    String reason = (order['cancel_reason'] != null && order['cancel_reason'].toString().trim().isNotEmpty)
        ? order['cancel_reason'].toString().trim()
        : (isMart ? 'Stok produk habis / toko sedang tutup' : 'Stok menu habis / restoran sedang tutup');
    bool isMaiPay = (order['payment_method'] ?? '').toString().toLowerCase() == 'maipay';

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isMart ? 'Alasan Penolakan dari Toko' : 'Alasan Penolakan dari Restoran',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: Color(0xFF991B1B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.remove_shopping_cart_outlined, size: 18, color: Color(0xFFDC2626)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reason,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFFB91C1C),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                isMaiPay ? Icons.check_circle : Icons.info_outline,
                size: 15,
                color: isMaiPay ? Colors.green.shade700 : Colors.grey.shade700,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isMaiPay
                      ? 'Saldo Mai-Pay telah dikembalikan otomatis ke dompet Anda.'
                      : 'Pembayaran tunai dibatalkan. Anda tidak perlu membayar kurir.',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: isMaiPay ? Colors.green.shade800 : Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmartEtaCard(String status, [bool isMart = false]) {
    if (['completed', 'delivered', 'cancelled'].contains(status)) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      int eta = trackingController.etaMinutes.value;
      String clock = trackingController.etaArrivalClock.value;
      String range = trackingController.etaRangeText.value;
      int prepMin = trackingController.prepEstimatedMinutes.value;
      int tripMin = trackingController.deliveryEstimatedMinutes.value;

      int activeStep = 1;
      if (status == 'processing') activeStep = 2;
      if (['ready', 'accepted', 'driver_assigned', 'driver_at_merchant'].contains(status)) activeStep = 3;
      if (['delivering', 'in_progress'].contains(status)) activeStep = 4;

      return Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade50, Colors.amber.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.shade200, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header: Icon di kiri + Judul & Estimasi Tiba di kanan (Responsif tanpa batas lebar)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade700,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.timer_outlined, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estimasi Pesanan Tiba',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          clock.isNotEmpty ? '$clock • $range' : (eta > 0 ? '~$eta mnt' : 'Memuat estimasi...'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.orange.shade900,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: activeStep <= 2 ? Colors.orange.shade300 : Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isMart ? Icons.inventory_2_outlined : Icons.soup_kitchen_outlined, size: 15, color: activeStep <= 2 ? Colors.orange.shade700 : Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              activeStep >= 3 
                                  ? (isMart ? 'Siap: Selesai' : 'Masak: Selesai') 
                                  : (isMart ? 'Siap: ~$prepMin mnt' : 'Masak: ~$prepMin mnt'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: activeStep <= 2 ? Colors.orange.shade900 : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.arrow_forward, size: 12, color: Colors.orange.shade300),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: activeStep >= 3 ? AppTheme.primaryBlue.withValues(alpha: 0.5) : Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.two_wheeler, size: 15, color: activeStep >= 3 ? AppTheme.primaryBlue : Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Antar: ~$tripMin mnt',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: activeStep >= 3 ? AppTheme.primaryNavy : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStepDot(label: 'Diterima', stepNumber: 1, currentStep: activeStep),
                _buildStepConnector(isPassed: activeStep >= 2),
                _buildStepDot(label: isMart ? 'Disiapkan' : 'Dimasak', stepNumber: 2, currentStep: activeStep),
                _buildStepConnector(isPassed: activeStep >= 3),
                _buildStepDot(label: 'Driver', stepNumber: 3, currentStep: activeStep),
                _buildStepConnector(isPassed: activeStep >= 4),
                _buildStepDot(label: 'Diantar', stepNumber: 4, currentStep: activeStep),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStepDot({required String label, required int stepNumber, required int currentStep}) {
    bool isCompleted = currentStep > stepNumber;
    bool isActive = currentStep == stepNumber;

    Color bg = isCompleted ? Colors.green : (isActive ? Colors.orange.shade700 : Colors.grey.shade300);
    Color textColor = isActive ? Colors.orange.shade900 : (isCompleted ? Colors.green.shade800 : Colors.grey.shade600);

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : (isActive
                      ? const SizedBox(width: 6, height: 6, child: DecoratedBox(decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle)))
                      : null),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 9, fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: textColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector({required bool isPassed}) {
    return Container(
      width: 14,
      height: 2,
      margin: const EdgeInsets.only(bottom: 14),
      color: isPassed ? Colors.green : Colors.grey.shade300,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _backToHome();
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: Stack(
          children: [
            // Map / Radar Area (Full screen)
            Obx(() {
              var order = trackingController.orderData;
              bool isCancelled = order['status'] == 'cancelled';
              bool isMart = (order['order_type'] ?? '').toString().toLowerCase() == 'mart' || (order['service_type'] ?? '').toString().toLowerCase() == 'mart';

              if (isCancelled) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFCA5A5), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.12),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.close_rounded, color: Color(0xFFDC2626), size: 52),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isMart ? 'Pesanan Toko Ditolak' : 'Pesanan Restoran Ditolak',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 36),
                        child: Text(
                          order['cancel_reason'] != null && order['cancel_reason'].toString().isNotEmpty
                              ? 'Alasan: ${order['cancel_reason']}'
                              : 'Toko/restoran tidak dapat memproses pesanan Anda saat ini.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 140),
                    ],
                  ),
                );
              }

              bool isPending = order.isEmpty || ['pending', 'accepted_by_merchant', 'processing', 'ready'].contains(order['status']);
              
              if (isPending && trackingController.driverLocation.value == null) {
                return Center(
                  child: AnimatedBuilder(
                    animation: _radarController,
                    builder: (_, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          _buildRadarCircle(300, 0.1),
                          _buildRadarCircle(220, 0.2),
                          _buildRadarCircle(140, 0.3),
                          Container(
                            width: 80, height: 80,
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.orangeAccent, blurRadius: 20, spreadRadius: 5)],
                            ),
                            child: Icon(isMart ? Icons.store : Icons.restaurant, color: Colors.white, size: 40),
                          ),
                        ],
                      );
                    },
                  ),
                );
              } else {
                return GoogleMap(
                  style: MapStyle.cleanStyle,
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(-6.200000, 106.816666),
                    zoom: 15,
                  ),
                  zoomControlsEnabled: false,
                  myLocationEnabled: true,
                  markers: Set<Marker>.of(trackingController.markers.values),
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
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryBlue),
                          onPressed: _backToHome,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('MaiFood Status', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue))),
                        IconButton(
                          icon: const Icon(Icons.share_rounded, color: AppTheme.primaryBlue),
                          tooltip: 'Bagikan Status Pesanan',
                          onPressed: () => _shareFoodOrder(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          
          // Tombol Pusatkan Peta (Recenter Camera)
          Positioned(
            bottom: _isCardCollapsed ? 102 : (MediaQuery.of(context).size.height * 0.60 + 36).clamp(160.0, MediaQuery.of(context).size.height * 0.70),
            right: 20,
            child: FloatingActionButton.small(
              heroTag: 'mapFocusBtn',
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryBlue,
              elevation: 4,
              tooltip: 'Pusatkan Peta & Driver',
              onPressed: () {
                trackingController.fitMapCamera();
              },
              child: const Icon(Icons.my_location, size: 20),
            ),
          ),

          // Info Area (Floating Bottom - Collapsible / Minimizable)
          Positioned(
            bottom: 24, left: 16, right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.symmetric(
                    horizontal: _isCardCollapsed ? 16 : 20,
                    vertical: _isCardCollapsed ? 12 : 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 5))],
                  ),
                  child: Obx(() {
                    if (trackingController.orderData.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    var order = trackingController.orderData;
                    bool isMart = (order['order_type'] ?? '').toString().toLowerCase() == 'mart' || (order['service_type'] ?? '').toString().toLowerCase() == 'mart';
                    String status = order['status'] ?? 'pending';
                    bool isCancelled = status == 'cancelled';
                    String cancelReason = (order['cancel_reason'] != null && order['cancel_reason'].toString().trim().isNotEmpty)
                        ? order['cancel_reason'].toString()
                        : '';
                    String titleText = _getStatusTitle(status, isMart);
                    String subtitleText = _getStatusSubtitle(status, isMart, cancelReason);

                    if (_isCardCollapsed) {
                      return _buildCollapsedCard(order, isMart, isCancelled, titleText, subtitleText);
                    } else {
                      return _buildExpandedCard(order, isMart, isCancelled, titleText, subtitleText, context);
                    }
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  // 🔹 Tampilan Mini / Collapsed: Peta tampil penuh (85%+), info utama ringkas di bawah
  Widget _buildCollapsedCard(dynamic order, bool isMart, bool isCancelled, String titleText, String subtitleText) {
    String clock = trackingController.etaArrivalClock.value;
    String range = trackingController.etaRangeText.value;
    String etaSummary = clock.isNotEmpty ? '$clock • $range' : subtitleText;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _isCardCollapsed = false),
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity! < -100) {
          setState(() => _isCardCollapsed = false);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle Bar (Pill)
          Center(
            child: Container(
              width: 36,
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
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: isCancelled ? Colors.red.withOpacity(0.12) : Colors.orange.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCancelled ? Icons.cancel_outlined : (isMart ? Icons.shopping_basket : Icons.delivery_dining),
                  color: isCancelled ? const Color(0xFFDC2626) : Colors.orange.shade800,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            titleText,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isCancelled ? const Color(0xFF991B1B) : AppTheme.textMain,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (clock.isNotEmpty && !isCancelled) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Text(
                              clock,
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      etaSummary,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isCancelled ? FontWeight.w600 : FontWeight.w500,
                        color: isCancelled ? const Color(0xFFDC2626) : AppTheme.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Quick Chat Driver
              if (order['driver_phone'] != null && order['driver_phone'].toString().isNotEmpty) ...[
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.green, size: 20),
                  tooltip: 'Chat Driver',
                  onPressed: () {
                    Get.to(() => ChatView(
                      orderId: order['id'].toString(),
                      driverName: order['driver_name'] ?? 'Driver',
                      driverPhoto: order['driver_photo'],
                      driverPhone: order['driver_phone'],
                    ));
                  },
                ),
              ],
              // Expand Button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Buka',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.keyboard_arrow_up, size: 18, color: AppTheme.primaryBlue),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🔹 Tampilan Lengkap / Expanded: Detail resto, driver, timeline, dan tombol tindakan
  Widget _buildExpandedCard(dynamic order, bool isMart, bool isCancelled, String titleText, String subtitleText, BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity! > 160) {
          setState(() => _isCardCollapsed = true);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle pill & minimize button
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _isCardCollapsed = true),
            child: Container(
              padding: const EdgeInsets.only(bottom: 10),
              color: Colors.transparent,
              child: Row(
                children: [
                  const SizedBox(width: 80),
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 44,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Lihat Peta',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey.shade700),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.58,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status & ETA Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCancelled ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCancelled ? Icons.cancel_outlined : (isMart ? Icons.shopping_basket : Icons.delivery_dining),
                          color: isCancelled ? const Color(0xFFDC2626) : Colors.orange,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titleText,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isCancelled ? const Color(0xFF991B1B) : AppTheme.textMain,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitleText,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isCancelled ? FontWeight.w600 : FontWeight.normal,
                                color: isCancelled ? const Color(0xFFDC2626) : AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Smart ETA Card or Cancellation Card
                  if (isCancelled)
                    _buildCancellationCard(order, isMart)
                  else
                    _buildSmartEtaCard(order['status'] ?? 'pending', isMart),
                  const SizedBox(height: 16),

                  // Merchant Info
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                              backgroundImage: (order['merchant_photo'] != null && order['merchant_photo'].toString().isNotEmpty)
                                  ? NetworkImage(ApiClient.getImageUrl(order['merchant_photo']))
                                  : null,
                              child: (order['merchant_photo'] == null || order['merchant_photo'].toString().isEmpty)
                                  ? Icon(isMart ? Icons.store : Icons.restaurant, color: AppTheme.primaryBlue, size: 20)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order['merchant_name'] ?? (isMart ? 'Toko' : 'Restoran'),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textMain),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    isMart ? 'Mitra Toko MaiMart' : 'Mitra Restoran MaiFood',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.more_vert, color: Colors.grey),
                              tooltip: isMart ? 'Hubungi Toko' : 'Hubungi Restoran',
                              onPressed: () {
                                ContactHelper.showContactModal(
                                  context,
                                  name: order['merchant_name'] ?? (isMart ? 'Toko' : 'Restoran'),
                                  phone: order['merchant_phone'],
                                  role: isMart ? 'Toko' : 'Restoran',
                                  photoUrl: order['merchant_photo'],
                                  orderId: order['id']?.toString(),
                                  onChatApp: () {
                                    Get.to(() => ChatView(
                                      orderId: order['id'].toString(),
                                      driverName: order['merchant_name'] ?? (isMart ? 'Toko' : 'Restoran'),
                                      isFood: true,
                                      driverPhone: order['merchant_phone'],
                                    ));
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildContactButton(
                                icon: Icons.chat_bubble_outline,
                                label: isMart ? 'Chat Toko' : 'Chat Resto',
                                color: AppTheme.primaryBlue,
                                onTap: () {
                                  Get.to(() => ChatView(
                                    orderId: order['id'].toString(),
                                    driverName: order['merchant_name'] ?? (isMart ? 'Toko' : 'Restoran'),
                                    isFood: true,
                                    driverPhone: order['merchant_phone'],
                                  ));
                                },
                              ),
                            ),
                            if (order['merchant_phone'] != null && order['merchant_phone'].toString().trim().isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildContactButton(
                                  icon: Icons.chat,
                                  label: 'WhatsApp',
                                  color: const Color(0xFF25D366),
                                  onTap: () {
                                    ContactHelper.openWhatsApp(
                                      phone: order['merchant_phone'],
                                      name: order['merchant_name'] ?? (isMart ? 'Toko' : 'Restoran'),
                                      orderId: order['id']?.toString(),
                                      customMessage: 'Halo ${order['merchant_name'] ?? (isMart ? 'Toko' : 'Restoran')}, saya pemesan ${isMart ? 'MaiMart' : 'MaiFood'} order #${order['id']}. Mau konfirmasi pesanan saya ya, terima kasih.',
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildContactButton(
                                  icon: Icons.phone_in_talk,
                                  label: 'Telepon',
                                  color: Colors.blue.shade700,
                                  onTap: () {
                                    ContactHelper.makePhoneCall(order['merchant_phone']);
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Driver Info
                  if (order['driver_name'] != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ClipOval(
                                child: Image.network(
                                  ApiClient.getImageUrl(order['driver_photo']),
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 44, height: 44, color: Colors.grey.shade300,
                                    child: const Icon(Icons.person, color: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order['driver_name'] ?? 'Driver',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textMain),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${order['driver_plate'] ?? '-'} • Driver Pengantar',
                                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.more_vert, color: Colors.grey),
                                tooltip: 'Hubungi Driver',
                                onPressed: () {
                                  ContactHelper.showContactModal(
                                    context,
                                    name: order['driver_name'] ?? 'Driver',
                                    phone: order['driver_phone'],
                                    role: 'Driver Pengantar',
                                    photoUrl: order['driver_photo'],
                                    orderId: order['id']?.toString(),
                                    onChatApp: () {
                                      Get.to(() => ChatView(
                                        orderId: order['id'].toString(),
                                        driverName: order['driver_name'] ?? 'Driver',
                                        driverPhoto: order['driver_photo'],
                                        driverPhone: order['driver_phone'],
                                      ));
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              // 1. Chat Driver
                              Expanded(
                                child: _buildContactButton(
                                  icon: Icons.chat_bubble_outline,
                                  label: 'Chat Driver',
                                  color: Colors.green.shade700,
                                  onTap: () {
                                    Get.to(() => ChatView(
                                      orderId: order['id'].toString(),
                                      driverName: order['driver_name'] ?? 'Driver',
                                      driverPhoto: order['driver_photo'],
                                      driverPhone: order['driver_phone'],
                                    ));
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),

                              // 2. WhatsApp Driver
                              Expanded(
                                child: _buildContactButton(
                                  icon: Icons.chat,
                                  label: 'WhatsApp',
                                  color: const Color(0xFF25D366),
                                  onTap: () {
                                    ContactHelper.openWhatsApp(
                                      phone: order['driver_phone'],
                                      name: order['driver_name'],
                                      orderId: order['id']?.toString(),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),

                              // 3. Telepon Driver
                              Expanded(
                                child: _buildContactButton(
                                  icon: Icons.phone_in_talk,
                                  label: 'Telepon',
                                  color: Colors.blue.shade700,
                                  onTap: () {
                                    ContactHelper.makePhoneCall(order['driver_phone']);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: () => _shareFoodOrder(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.teal.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.shield_rounded, color: Colors.teal.shade700, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Bagikan status pesanan & driver ke keluarga',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal.shade900,
                                      ),
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios, size: 11, color: Colors.teal.shade700),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // 🚫 Tombol Batalkan Pesanan Mai-Food
                  if (['pending', 'accepted_by_merchant', 'processing', 'ready'].contains(order['status'])) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
                        label: const Text(
                          'Batalkan Pesanan',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.red.shade300, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          backgroundColor: Colors.red.shade50.withOpacity(0.5),
                        ),
                        onPressed: () => _showCancelModal(context, order),
                      ),
                    ),
                  ],

                  // 🏠 Tombol Tindakan jika pesanan telah ditolak / dibatalkan
                  if (order['status'] == 'cancelled') ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.home, size: 18),
                            label: const Text('Beranda', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade800,
                              side: BorderSide(color: Colors.grey.shade400),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () {
                              if (Get.isRegistered<HomeController>()) {
                                Get.find<HomeController>().activeFoodOrder.value = null;
                                Get.find<HomeController>().checkActiveOrder();
                              }
                              Get.offAllNamed('/home');
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            icon: Icon(isMart ? Icons.storefront : Icons.restaurant_menu, color: Colors.white, size: 18),
                            label: Text(
                              isMart ? 'Cari Toko Lain' : 'Cari Menu Lain',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isMart ? const Color(0xFF059669) : Colors.orange.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              if (Get.isRegistered<HomeController>()) {
                                Get.find<HomeController>().activeFoodOrder.value = null;
                                Get.find<HomeController>().checkActiveOrder();
                              }
                              if (isMart) {
                                Get.offNamed('/mart');
                              } else {
                                Get.off(() => MerchantsView());
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelModal(BuildContext context, dynamic order) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Batalkan Pesanan MaiFood?',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Pilih alasan pembatalan. Jika membayar dengan saldo Mai-Pay, saldo Anda akan otomatis dikembalikan 100%.',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.3),
            ),
            const SizedBox(height: 16),
            ...[
              'Menunggu terlalu lama / tidak ada respon',
              'Driver tidak kunjung ditemukan',
              'Ingin mengganti menu / salah alamat',
              'Berubah pikiran',
              'Lainnya'
            ].map((reason) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
              title: Text(
                reason,
                style: const TextStyle(fontSize: 14, color: AppTheme.textMain, fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Get.back(); // tutup modal
                trackingController.cancelOrder(reason);
              },
            )),
            const SizedBox(height: 10),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.09),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 17),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareFoodOrder(BuildContext context) {
    var order = trackingController.orderData;
    if (order.isEmpty) return;
    bool isMart = (order['order_type'] ?? '').toString().toLowerCase() == 'mart' || (order['service_type'] ?? '').toString().toLowerCase() == 'mart';

    String statusText;
    switch (order['status']) {
      case 'pending':
        statusText = isMart ? 'Menunggu Konfirmasi Toko' : 'Menunggu Konfirmasi Resto';
        break;
      case 'accepted_by_merchant':
        statusText = isMart ? 'Dikonfirmasi Toko' : 'Dikonfirmasi Resto';
        break;
      case 'processing':
        statusText = isMart ? 'Sedang Disiapkan di Toko' : 'Sedang Dimasak di Resto';
        break;
      case 'ready':
        statusText = isMart ? 'Belanjaan Siap / Menunggu Driver' : 'Makanan Siap / Menunggu Driver';
        break;
      case 'driver_assigned':
        statusText = isMart ? 'Driver Menuju Toko' : 'Driver Menuju Restoran';
        break;
      case 'driver_at_merchant':
        statusText = isMart ? 'Driver Tiba di Toko' : 'Driver Tiba di Restoran';
        break;
      case 'delivering':
        statusText = isMart ? 'Belanjaan Sedang Diantar Driver ke Lokasi' : 'Makanan Sedang Diantar Driver ke Lokasi';
        break;
      case 'completed':
        statusText = isMart ? 'Belanjaan Telah Tiba' : 'Makanan Telah Tiba';
        break;
      default:
        statusText = 'Sedang Diproses';
    }

    String eta = trackingController.etaArrivalClock.value.isNotEmpty
        ? '${trackingController.etaArrivalClock.value} (${trackingController.etaRangeText.value})'
        : trackingController.etaRangeText.value;

    ContactHelper.shareTripViaWhatsApp(
      context: context,
      serviceName: isMart ? 'MaiMart' : 'MaiFood',
      orderId: order['id']?.toString(),
      driverName: order['driver_name'],
      vehiclePlate: order['driver_vehicle_plate'] ?? order['vehicle_plate'],
      vehicleType: 'Motor',
      pickupAddress: order['merchant_name'] != null ? '${order['merchant_name']} (${order['merchant_address'] ?? ''})' : null,
      dropoffAddress: order['delivery_address'],
      statusText: statusText,
      etaText: eta,
    );
  }
}
