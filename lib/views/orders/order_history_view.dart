import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import '../../controllers/auth_controller.dart';
import '../../core/utils.dart';

class OrderHistoryView extends StatefulWidget {
  const OrderHistoryView({super.key});

  @override
  State<OrderHistoryView> createState() => _OrderHistoryViewState();
}

class _OrderHistoryViewState extends State<OrderHistoryView> {
  final AuthController _authController = Get.find<AuthController>();
  bool _isLoading = true;
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      final response = await ApiClient.get('/user/orders/history');
      if (response.statusCode == 200) {
        setState(() {
          var body = jsonDecode(response.body);
          _orders = body['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar('Error', 'Gagal mengambil data riwayat');
    }
  }

  Future<void> _downloadReceipt(String orderId, String orderType) async {
    final token = await _authController.getToken();
    if (token == null) return;
    
    // Gunakan URL API backend dengan token
    final String endpoint = orderType == 'food' ? '/user/food/receipt/$orderId' : '/user/orders/receipt/$orderId';
    final String url = '${ApiClient.baseUrl}$endpoint?token=$token';
    final Uri uri = Uri.parse(url);
    
    try {
      // Buka URL di browser bawaan OS yang akan mendownload PDF otomatis
      // ignore: deprecated_member_use
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar('Error', 'Tidak dapat membuka tautan struk');
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal mengunduh struk');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Riwayat Pesanan', style: TextStyle(color: AppTheme.textMain, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading 
        ? _buildSkeleton()
        : RefreshIndicator(
            onRefresh: _fetchOrders,
            color: AppTheme.primaryBlue,
            child: _orders.isEmpty
              ? Stack(children: [ListView(physics: const AlwaysScrollableScrollPhysics()), _buildEmptyState()])
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    return _buildOrderCard(_orders[index]);
                  },
                ),
          ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Belum ada riwayat pesanan', style: TextStyle(fontSize: 16, color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: 80, height: 16, color: Colors.white),
                    Container(width: 60, height: 20, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(width: 16, height: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Container(width: 200, height: 14, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(width: 16, height: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Container(width: 200, height: 14, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: 40, height: 12, color: Colors.white),
                    Container(width: 80, height: 16, color: Colors.white),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(dynamic order) {
    String status = order['status'] ?? 'pending';
    Color statusColor = status == 'completed' ? Colors.green : (status == 'cancelled' ? Colors.red : Colors.orange);
    bool isActive = status != 'completed' && status != 'cancelled';

    String dateStr = '';
    String timeRangeStr = '';
    String durationBadge = '';

    if (order['created_at'] != null) {
      try {
        DateTime createdAt = DateTime.parse(order['created_at']).toLocal();
        dateStr = "${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}";
        String startTime = "${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}";

        if (status == 'completed') {
          DateTime? completedAt;
          if (order['completed_at'] != null && order['completed_at'].toString().isNotEmpty) {
            completedAt = DateTime.tryParse(order['completed_at'])?.toLocal();
          }
          if (completedAt == null && order['updated_at'] != null && order['updated_at'].toString().isNotEmpty) {
            completedAt = DateTime.tryParse(order['updated_at'])?.toLocal();
          }

          if (completedAt != null) {
            String endTime = "${completedAt.hour.toString().padLeft(2, '0')}:${completedAt.minute.toString().padLeft(2, '0')}";
            Duration diff = completedAt.difference(createdAt);
            int minutes = diff.inMinutes;
            if (minutes < 1) minutes = 1;

            timeRangeStr = "$startTime - $endTime ($minutes mnt)";
            durationBadge = "$minutes mnt ($startTime-$endTime)";
          } else {
            timeRangeStr = startTime;
            durationBadge = "Selesai";
          }
        } else if (isActive) {
          double dist = double.tryParse(order['distance']?.toString() ?? '0') ?? 2.0;
          int estMinutes = (dist * 2.5 + 4).round();
          if (order['type'] == 'food' || (order['service_type']?.toString().contains('titip') ?? false)) {
            estMinutes += 12;
          }
          if (estMinutes < 5) estMinutes = 5;

          DateTime estArrival = createdAt.add(Duration(minutes: estMinutes));
          String estTime = "${estArrival.hour.toString().padLeft(2, '0')}:${estArrival.minute.toString().padLeft(2, '0')}";

          timeRangeStr = "$startTime • Est. ~$estTime (~$estMinutes mnt)";
          durationBadge = "Est. ~$estMinutes mnt";
        } else {
          timeRangeStr = "$startTime • Dibatalkan";
          durationBadge = "Dibatalkan";
        }
      } catch (_) {}
    }

    String typeLabel = 'Mai-Ride';
    IconData typeIcon = Icons.two_wheeler;
    Color typeColor = AppTheme.primaryBlue;
    
    if (order['type'] == 'food') {
      bool isMart = (order['order_type'] ?? '').toString().toLowerCase() == 'mart';
      typeLabel = isMart ? 'Mai-Mart' : 'Mai-Food';
      typeIcon = isMart ? Icons.shopping_basket_rounded : Icons.restaurant;
      typeColor = isMart ? const Color(0xFF059669) : Colors.orange;
    } else {
      String st = (order['service_type'] ?? '').toString().toLowerCase();
      if (st == 'mai_car' || st == 'car' || st == 'mobil' || st == 'car_premium') {
        typeLabel = 'Mai-Car';
        typeIcon = Icons.directions_car;
        typeColor = const Color(0xFF0066CC);
      } else if (st.startsWith('mai_send')) {
        typeLabel = 'Mai-Send';
        typeIcon = Icons.local_shipping;
        typeColor = Colors.teal;
      } else if (st.startsWith('mai_titip')) {
        typeLabel = st == 'mai_titip_mobil' ? 'Mai-Titip Mobil' : 'Mai-Titip Motor';
        typeIcon = st == 'mai_titip_mobil' ? Icons.directions_car : Icons.shopping_bag;
        typeColor = Colors.purpleAccent;
      }
    }

    return GestureDetector(
      onTap: (isActive || (status == 'cancelled' && order['type'] == 'food')) ? () {
        if (order['type'] == 'food') {
          Get.toNamed('/food/tracking', arguments: {'order_id': order['id']});
        } else {
          Get.toNamed('/order-tracking', arguments: {'order_id': order['id']});
        }
      } : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? typeColor.withOpacity(0.5) : Colors.white.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8)),
            const BoxShadow(color: Colors.white, blurRadius: 5, offset: Offset(-3, -3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: typeColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(typeIcon, color: typeColor, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(typeLabel, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: typeColor)),
                                  if (timeRangeStr.isNotEmpty)
                                    Row(
                                      children: [
                                        Icon(Icons.schedule, size: 11, color: Colors.grey.shade600),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            '$dateStr • $timeRangeStr',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: status == 'completed' ? FontWeight.w600 : FontWeight.normal,
                                              color: status == 'completed' ? Colors.green.shade800 : (isActive ? Colors.orange.shade900 : Colors.grey.shade600),
                                            ),
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
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [statusColor, statusColor.withOpacity(0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: statusColor.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
                        ),
                        child: Text(
                          status == 'cancelled' ? (order['type'] == 'food' ? 'DITOLAK' : 'DIBATALKAN') : status.toUpperCase(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                        ),
                      )
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Icon(order['type'] == 'food' ? Icons.storefront : Icons.my_location, color: Colors.blue, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(order['pickup_address'] ?? 'Lokasi Penjemputan', maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 7),
                    child: SizedBox(height: 12, child: VerticalDivider(color: Colors.grey, thickness: 1)),
                  ),
                  Row(
                    children: [
                      Icon(order['type'] == 'food' ? Icons.home : Icons.location_on, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(order['dropoff_address'] ?? 'Lokasi Tujuan', maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.route, size: 14, color: AppTheme.textMuted),
                            const SizedBox(width: 4),
                            Text('${order['distance']} KM', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                            if (durationBadge.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: status == 'completed'
                                        ? Colors.green.shade50
                                        : (isActive ? Colors.orange.shade50 : Colors.grey.shade100),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: status == 'completed'
                                          ? Colors.green.shade200
                                          : (isActive ? Colors.orange.shade200 : Colors.grey.shade300),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    durationBadge,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: status == 'completed'
                                          ? Colors.green.shade800
                                          : (isActive ? Colors.orange.shade900 : Colors.grey.shade700),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(Formatter.currency(order['price']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ],
                  ),
                  // ❌ Callout Alasan Penolakan / Pembatalan
                  if (status == 'cancelled') ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFECACA), width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.cancel_outlined, color: Color(0xFFDC2626), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                order['type'] == 'food'
                                    ? ((order['order_type'] ?? '') == 'mart' ? 'Ditolak Toko' : 'Ditolak Restoran')
                                    : 'Pesanan Dibatalkan',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF991B1B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Alasan: ${order['cancel_reason'] != null && order['cancel_reason'].toString().trim().isNotEmpty ? order['cancel_reason'] : (order['type'] == 'food' ? 'Stok barang/menu habis atau toko tutup' : 'Dibatalkan oleh sistem')}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFB91C1C),
                            ),
                          ),
                          if ((order['payment_method'] ?? '').toString().toLowerCase() == 'maipay') ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.check_circle, size: 13, color: Colors.green.shade700),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Dana telah dikembalikan ke saldo Mai-Pay',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  if (status == 'completed' && order['type'] != 'food' && !(order['service_type']?.toString().contains('mai_send') ?? false) && !(order['service_type']?.toString().contains('mai_titip') ?? false)) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _downloadReceipt(order['id'].toString(), order['type'] ?? 'ride'),
                        icon: const Icon(Icons.picture_as_pdf, color: AppTheme.primaryBlue, size: 18),
                        label: const Text('Unduh Struk PDF', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.primaryBlue),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 10)
                        ),
                      ),
                    ),
                  ],
                  if (status == 'completed' && (order['rating'] == null || order['rating'] == 0 || order['rating'] == '0')) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _rateOrder(order),
                        icon: const Icon(Icons.star, color: Colors.white, size: 18),
                        label: const Text('Berikan Penilaian', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 0
                        ),
                      ),
                    )
                  ],
                  // Chat CS Button for completed or cancelled orders
                  if (status == 'completed' || status == 'cancelled') ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () => Get.toNamed('/cs-chat'),
                        icon: const Icon(Icons.support_agent, color: AppTheme.primaryBlue, size: 18),
                        label: const Text('Bantuan CS (Barang tertinggal/Kendala)', style: TextStyle(color: AppTheme.primaryBlue)),
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    )
                  ]
                ],
              ),
            ),
            if (order['type'] == 'food')
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Text(
                    'Lihat Rincian ${(order['order_type'] ?? '').toString().toLowerCase() == 'mart' ? "Belanjaan" : "Pesanan"} & Biaya',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: typeColor),
                  ),
                  iconColor: typeColor,
                  collapsedIconColor: typeColor,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 20),
                  childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                  children: [
                    if (order['merchant_name'] != null)
                      _buildDetailRow((order['order_type'] ?? '').toString().toLowerCase() == 'mart' ? 'Toko' : 'Restoran', order['merchant_name'] ?? '-'),
                    if (order['driver_name'] != null && order['driver_name'].toString().isNotEmpty)
                      _buildDetailRow('Driver', '${order['driver_name']}${order['vehicle_plate'] != null ? " (${order['vehicle_plate']})" : ""}'),
                    if (order['payment_method'] != null)
                      _buildDetailRow('Pembayaran', order['payment_method'].toString().toLowerCase() == 'maipay' ? 'MaiPay (Non-Tunai)' : 'Tunai'),
                    const SizedBox(height: 10),
                    if (order['items'] != null && (order['items'] is List) && (order['items'] as List).isNotEmpty) ...[
                      Text(
                        (order['order_type'] ?? '').toString().toLowerCase() == 'mart' ? 'Daftar Barang Belanjaan:' : 'Daftar Menu:',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      ...((order['items'] as List).map((it) {
                        int q = int.tryParse(it['quantity']?.toString() ?? (it['qty']?.toString() ?? '1')) ?? 1;
                        if (q <= 0) q = 1;
                        String name = it['menu_name'] ?? (it['name'] ?? 'Item');
                        double itPrice = double.tryParse(it['price']?.toString() ?? '') ?? 0.0;
                        double itTotal = double.tryParse(it['total_price']?.toString() ?? '') ?? 0.0;
                        if (itTotal <= 0 && itPrice > 0) {
                          itTotal = itPrice * q;
                        }
                        if (itPrice <= 0 && itTotal > 0) {
                          itPrice = itTotal / q;
                        }
                        // Fallback to order food_total if items total is 0 and only 1 item
                        if (itTotal <= 0 && order['food_total'] != null) {
                          final fTot = double.tryParse(order['food_total'].toString()) ?? 0.0;
                          if (fTot > 0 && (order['items'] as List).length == 1) {
                            itTotal = fTot;
                            itPrice = itTotal / q;
                          }
                        }
                        String? itNotes = it['notes']?.toString();
                        String? unit = it['unit']?.toString();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${q}x $name${unit != null && unit.isNotEmpty ? " / $unit" : ""}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    Formatter.currency(itTotal),
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                                  ),
                                ],
                              ),
                              if (itNotes != null && itNotes.trim().isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text('Catatan: $itNotes', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.amber.shade900)),
                              ],
                            ],
                          ),
                        );
                      })),
                      const SizedBox(height: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: typeColor.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          if (order['food_total'] != null)
                            _buildCostRow((order['order_type'] ?? '').toString().toLowerCase() == 'mart' ? 'Subtotal Belanja:' : 'Subtotal Makanan:', Formatter.currency(order['food_total'])),
                          if (order['delivery_fee'] != null)
                            _buildCostRow('Ongkos Kirim Driver:', Formatter.currency(order['delivery_fee'])),
                          if (order['discount_amount'] != null && (double.tryParse(order['discount_amount'].toString()) ?? 0) > 0)
                            _buildCostRow('Diskon Promo:', '- ${Formatter.currency(order['discount_amount'])}', isDiscount: true),
                          const Divider(height: 14),
                          _buildCostRow('Total Pembayaran:', Formatter.currency(order['price']), isBold: true),
                        ],
                      ),
                    ),
                    if (status == 'completed') ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _downloadReceipt(order['id'].toString(), 'food'),
                          icon: Icon(Icons.picture_as_pdf, color: typeColor, size: 18),
                          label: Text('Unduh Struk PDF Resmi', style: TextStyle(color: typeColor, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: typeColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            if (status == 'completed' && (order['service_type']?.toString().startsWith('mai_') ?? false))
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: const Text('Lihat Detail & Bukti Foto', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                  iconColor: AppTheme.primaryBlue,
                  collapsedIconColor: AppTheme.primaryBlue,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 20),
                  childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                  children: [
                    if (order['service_type']?.toString().contains('mai_send') ?? false) ...[
                      _buildDetailRow('Penerima', order['recipient_name'] ?? '-'),
                      _buildDetailRow('No HP', order['recipient_phone'] ?? '-'),
                      _buildDetailRow('Barang', order['item_description'] ?? '-'),
                      const SizedBox(height: 12),
                      const Text('Bukti Penjemputan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      _buildNetworkImage(order['proof_of_pickup']),
                      const SizedBox(height: 12),
                      const Text('Bukti Pengiriman', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      _buildNetworkImage(order['proof_of_delivery']),
                    ],
                    if (order['service_type']?.toString().contains('mai_titip') ?? false) ...[
                      _buildDetailRow('Daftar Belanja', order['item_description'] ?? '-'),
                      _buildDetailRow('Est. Harga', Formatter.currency(order['titip_item_price'])),
                      _buildDetailRow('Total Struk', Formatter.currency(order['titip_total_cost'])),
                      const SizedBox(height: 12),
                      const Text('Bukti Struk Belanja & Barang', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      _buildNetworkImage(order['titip_receipt_img'] ?? order['proof_of_pickup']),
                      const SizedBox(height: 12),
                      const Text('Bukti Pengiriman', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      _buildNetworkImage(order['proof_of_delivery']),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _downloadReceipt(order['id'].toString(), order['type'] ?? 'ride'),
                        icon: const Icon(Icons.picture_as_pdf, color: AppTheme.primaryBlue, size: 18),
                        label: const Text('Unduh Struk PDF', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.primaryBlue),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 10)
                        ),
                      ),
                    )
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))),
          const Text(':', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildCostRow(String label, String value, {bool isDiscount = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDiscount ? Colors.green.shade800 : (isBold ? Colors.black87 : Colors.grey.shade700),
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 13 : 12,
              fontWeight: isBold ? FontWeight.w900 : (isDiscount ? FontWeight.bold : FontWeight.w600),
              color: isDiscount ? Colors.green.shade800 : (isBold ? Colors.black87 : Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkImage(String? path) {
    if (path == null || path.isEmpty) {
      return Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
        child: const Center(child: Text('Foto tidak tersedia', style: TextStyle(color: Colors.grey))),
      );
    }
    
    String url = ApiClient.getImageUrl(path);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
          child: const Center(child: Text('Gagal memuat foto', style: TextStyle(color: Colors.grey))),
        ),
      ),
    );
  }

  void _rateOrder(dynamic order) {
    if (order['type'] == 'food') {
      _showFoodRatingDialog(order);
    } else {
      Get.toNamed('/rating', arguments: {
        'order_id': order['id'].toString(),
        'driver_photo': order['driver_photo'],
        'name': order['driver_name'],
        'vehicle_plate': order['vehicle_plate'],
      })?.then((_) => _fetchOrders());
    }
  }

  void _showFoodRatingDialog(dynamic order) {
    bool isMart = (order['order_type'] ?? '').toString().toLowerCase() == 'mart';
    int merchantRating = 5;
    int driverRating = 5;
    final merchantReviewController = TextEditingController();
    final driverReviewController = TextEditingController();
    final tipController = TextEditingController();
    
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: StatefulBuilder(
          builder: (context, setStateDialog) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Beri Nilai Pesanan Anda', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Divider(height: 24),
                  
                  // Merchant Rating
                  Text('${isMart ? "Toko" : "Restoran"}: ${order['merchant_name'] ?? (isMart ? "Toko" : "Resto")}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  FittedBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(index < merchantRating ? Icons.star : Icons.star_border, color: Colors.orange, size: 36),
                          onPressed: () => setStateDialog(() => merchantRating = index + 1),
                        );
                      }),
                    ),
                  ),
                  TextField(
                    controller: merchantReviewController,
                    decoration: InputDecoration(hintText: 'Ulasan ${isMart ? "Toko" : "Restoran"} (Opsi)', isDense: true),
                  ),
                  const SizedBox(height: 24),
                  
                  // Driver Rating
                  if (order['driver_name'] != null) ...[
                    Text('Driver: ${order['driver_name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    FittedBox(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return IconButton(
                            icon: Icon(index < driverRating ? Icons.star : Icons.star_border, color: Colors.orange, size: 36),
                            onPressed: () => setStateDialog(() => driverRating = index + 1),
                          );
                        }),
                      ),
                    ),
                    TextField(
                      controller: driverReviewController,
                      decoration: const InputDecoration(hintText: 'Ulasan Driver (Opsi)', isDense: true),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: tipController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Beri Tip Driver (Rp, Opsi)', prefixIcon: Icon(Icons.attach_money), isDense: true),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        double tip = double.tryParse(tipController.text) ?? 0;
                        Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
                        try {
                          final response = await ApiClient.post('/user/food/rate', {
                            'order_id': order['id'].toString(),
                            'merchant_rating': merchantRating.toString(),
                            'driver_rating': driverRating.toString(),
                            'review_merchant': merchantReviewController.text,
                            'review_driver': driverReviewController.text,
                            'tip': tip.toString(),
                          });
                          Get.back(); // close loading
                          if (response.statusCode == 200) {
                            Get.back(); // close dialog
                            Get.snackbar('Terima Kasih', 'Ulasan Anda berhasil dikirim!', backgroundColor: Colors.green, colorText: Colors.white);
                            _fetchOrders();
                          } else {
                            var err = jsonDecode(response.body);
                            Get.snackbar('Gagal', err['message'] ?? 'Gagal mengirim ulasan', backgroundColor: Colors.red, colorText: Colors.white);
                          }
                        } catch (e) {
                          Get.back();
                          Get.snackbar('Error', 'Terjadi kesalahan jaringan');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Kirim Ulasan'),
                    ),
                  )
                ],
              ),
            );
          }
        ),
      ),
    );
  }
}
