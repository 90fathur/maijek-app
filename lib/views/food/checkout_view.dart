import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../views/home/map_picker_view.dart';
import '../../controllers/food_controller.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme.dart';
import '../wallet/topup_view.dart';
import '../wallet/insufficient_balance_sheet.dart';

class CheckoutView extends StatelessWidget {
  final FoodController controller = Get.find<FoodController>();
  final HomeController homeController = Get.isRegistered<HomeController>() ? Get.find<HomeController>() : Get.put(HomeController());
  final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
  final TextEditingController detailController = TextEditingController();

  String _getFoodEstimateRange(String vehicleType, double distance) {
    int cookingMins = 15;
    int travelMins = vehicleType == 'mobil' 
        ? (distance * 3.2 + 6).round() 
        : (distance * 2.5 + 4).round();
    
    int totalBase = cookingMins + travelMins;
    if (totalBase < 15) totalBase = 15;
    
    int minMins = totalBase;
    int maxMins = totalBase + 10;
    
    final now = DateTime.now();
    final arrival = now.add(Duration(minutes: (minMins + maxMins) ~/ 2));
    final arrivalTimeStr = "${arrival.hour.toString().padLeft(2, '0')}:${arrival.minute.toString().padLeft(2, '0')}";
    
    return "$minMins-$maxMins mnt (Tiba ~$arrivalTimeStr)";
  }

  Widget _buildVehicleCard({
    required String type,
    required String title,
    required String badgeText,
    required Color badgeBg,
    required Color badgeTextColor,
    required String subtitle,
    required int fee,
    required IconData icon,
    required Color activeColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Ikon Kendaraan
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? activeColor.withValues(alpha: 0.15) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? activeColor : Colors.grey.shade600, size: 22),
            ),
            const SizedBox(width: 10),

            // Teks Nama & Deskripsi (Fleksibel & Anti-Overflow)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 2,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: badgeTextColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Harga & Radio Icon
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatter.format(fee),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isSelected ? activeColor : Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected ? activeColor : Colors.grey.shade400,
                  size: 18,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.cart.isEmpty) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Checkout MaiFood', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: AppTheme.primaryBlue,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.remove_shopping_cart_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('Keranjang Belanja Kosong', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Semua item pesanan telah dihapus.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    label: const Text('Kembali ke Restoran', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      double distance = controller.deliveryDistance.value;
      int deliveryFee = controller.currentDeliveryFee;
      int motorFee = controller.calculateDeliveryFee('motor');
      int mobilFee = controller.calculateDeliveryFee('mobil');

      return Scaffold(
        appBar: AppBar(
          title: const Text('Checkout MaiFood', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: AppTheme.primaryBlue,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 1. Alamat Pengantaran
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.location_on, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Alamat Pengantaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(controller.deliveryAddress.value, style: TextStyle(color: Colors.grey[800], fontSize: 13)),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              style: TextButton.styleFrom(padding: EdgeInsets.zero),
                              onPressed: () async {
                                var result = await Get.to(() => const MapPickerView());
                                if (result != null) {
                                  controller.setDeliveryLocation(result['address'], result['latLng'].latitude, result['latLng'].longitude);
                                }
                              },
                              icon: const Icon(Icons.edit_location_alt, size: 16, color: AppTheme.primaryBlue),
                              label: const Text('Ubah Titik Lokasi Peta', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: detailController,
                            decoration: InputDecoration(
                              hintText: 'Keterangan detail (cth: Blok A No. 12, Pagar hitam)',
                              hintStyle: const TextStyle(fontSize: 12),
                              isDense: true,
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                            ),
                            maxLines: 2,
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. PILIHAN ARMADA PENGANTAR (MOTOR / MOBIL)
                  const Text('Pilihan Armada Pengantar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  
                  // Banner Estimasi Waktu Tiba Makanan
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade300, width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_filled, color: Colors.orange, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Estimasi Pesanan Tiba: ${_getFoodEstimateRange(controller.selectedVehicleType.value, distance)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Waktu penyiapan resto (~15 mnt) + Perjalanan kurir (${distance.toStringAsFixed(1)} KM)',
                                style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          // Opsi 1: Motor
                          _buildVehicleCard(
                            type: 'motor',
                            title: 'Kurir Motor',
                            badgeText: 'Reguler',
                            badgeBg: Colors.green.shade100,
                            badgeTextColor: Colors.green.shade800,
                            subtitle: '1 - 4 porsi • Est. ${_getFoodEstimateRange('motor', distance)}',
                            fee: motorFee,
                            icon: Icons.two_wheeler,
                            activeColor: Colors.orange.shade800,
                            isSelected: controller.selectedVehicleType.value == 'motor',
                            onTap: () {
                              controller.selectedVehicleType.value = 'motor';
                            },
                          ),
                          const SizedBox(height: 8),

                          // Opsi 2: Mobil
                          _buildVehicleCard(
                            type: 'mobil',
                            title: 'Kurir Mobil',
                            badgeText: 'Katering / Box',
                            badgeBg: Colors.blue.shade100,
                            badgeTextColor: Colors.blue.shade800,
                            subtitle: 'Porsi banyak / box • Est. ${_getFoodEstimateRange('mobil', distance)}',
                            fee: mobilFee,
                            icon: Icons.directions_car,
                            activeColor: AppTheme.primaryBlue,
                            isSelected: controller.selectedVehicleType.value == 'mobil',
                            onTap: () {
                              controller.selectedVehicleType.value = 'mobil';
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Rincian Pesanan
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Rincian Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${controller.totalCartQuantity} Item', style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.cart.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        var item = controller.cart[index];
                        int qty = (item['quantity'] as int?) ?? 1;
                        int unitPrice = double.parse(item['price'].toString()).toInt();
                        int totalPrice = unitPrice * qty;
                        var menuId = item['menu_id'];

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Info Menu
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'] ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      formatter.format(unitPrice),
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                    if (item['notes'] != null && item['notes'].toString().isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          'Catatan: ${item['notes']}',
                                          style: TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: Colors.orange.shade800),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Counter (-) [qty] (+)
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        controller.updateCartQuantityByMenuId(menuId, -1);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                        child: Icon(
                                          qty == 1 ? Icons.delete_outline : Icons.remove,
                                          size: 16,
                                          color: qty == 1 ? Colors.red.shade600 : AppTheme.primaryBlue,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                      child: Text(
                                        '$qty',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryBlue),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        controller.updateCartQuantityByMenuId(menuId, 1);
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                        child: Icon(Icons.add, size: 16, color: AppTheme.primaryBlue),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Subtotal item
                              Text(
                                formatter.format(totalPrice),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3.5 Kupon & Voucher Diskon
                  Obx(() {
                    final promo = controller.appliedPromo.value;
                    if (promo != null) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.green.shade400, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Text('🎉', style: TextStyle(fontSize: 22)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Voucher ${promo['code']} Berhasil Digunakan!',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade900, fontSize: 13),
                                  ),
                                  Text(
                                    'Hemat sebesar ${formatter.format(controller.discountAmount)}',
                                    style: TextStyle(color: Colors.green.shade800, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: controller.removePromo,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Text('Hapus', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12, decoration: TextDecoration.underline)),
                              ),
                            )
                          ],
                        ),
                      );
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () => _showPromoBottomSheet(context),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.orange.shade50, Colors.amber.shade50],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                                child: const Icon(Icons.confirmation_num, color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Makin Hemat Pakai Voucher & Promo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    Text('Klaim diskon s/d 50% atau gratis ongkir', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: Colors.orange.shade800, borderRadius: BorderRadius.circular(20)),
                                child: const Text('Klaim >', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  // 4. Rincian Pembayaran
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Harga Makanan', style: TextStyle(color: Colors.black87)),
                              Text(formatter.format(controller.cartTotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Ongkos Kirim ${controller.selectedVehicleType.value == 'mobil' ? 'Mobil' : 'Motor'} (${distance.toStringAsFixed(1)} km)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              ),
                              Text(formatter.format(deliveryFee), style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          if (controller.discountAmount > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.local_offer, color: Colors.green, size: 16),
                                    const SizedBox(width: 4),
                                    Text('Diskon Promo (${controller.appliedPromo.value?['code']})', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Text(
                                  '-${formatter.format(controller.discountAmount)}',
                                  style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.green, fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
                              DropdownButton<String>(
                                value: controller.paymentMethod.value,
                                items: const [
                                  DropdownMenuItem(value: 'cash', child: Text('💵 Tunai')),
                                  DropdownMenuItem(value: 'maipay', child: Text('💳 Mai-Pay')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    controller.paymentMethod.value = val;
                                    if (val == 'maipay') {
                                      final authCtrl = Get.find<AuthController>();
                                      final bal = double.tryParse(authCtrl.userData['balance']?.toString() ?? '0') ?? 0;
                                      final total = controller.finalTotal.toDouble();
                                      if (bal < total) {
                                        InsufficientBalanceSheet.show(
                                          currentBalance: bal,
                                          requiredAmount: total,
                                          onPayCash: () {
                                            controller.paymentMethod.value = 'cash';
                                          },
                                        );
                                      }
                                    }
                                  }
                                },
                                underline: const SizedBox(),
                              ),
                            ],
                          ),
                          if (controller.paymentMethod.value == 'maipay') ...[
                            Builder(
                              builder: (context) {
                                final authCtrl = Get.find<AuthController>();
                                final bal = double.tryParse(authCtrl.userData['balance']?.toString() ?? '0') ?? 0;
                                final total = controller.finalTotal.toDouble();
                                final isShort = bal < total;
                                final deficit = total - bal;
                                int recommended = 10000;
                                if (deficit > 10000) recommended = ((deficit / 10000).ceil()) * 10000;

                                return Container(
                                  margin: const EdgeInsets.only(top: 4, bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isShort ? Colors.orange.shade50 : Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isShort ? Colors.orange.shade200 : Colors.blue.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isShort ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                                        color: isShort ? Colors.deepOrange : AppTheme.primaryBlue,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Saldo: ${formatter.format(bal)}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: isShort ? Colors.deepOrange.shade900 : AppTheme.primaryBlue,
                                              ),
                                            ),
                                            if (isShort)
                                              Text(
                                                'Kurang ${formatter.format(deficit)}',
                                                style: const TextStyle(fontSize: 11, color: Colors.red),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (isShort)
                                        ElevatedButton(
                                          onPressed: () {
                                            Get.to(() => TopUpView(initialAmount: recommended));
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.primaryBlue,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                            minimumSize: const Size(0, 30),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                          ),
                                          child: const Text('+ Top Up', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                              Text(
                                formatter.format(controller.finalTotal),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryBlue),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),

            // Checkout Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : () async {
                          if (controller.deliveryAddress.value.isEmpty || controller.deliveryAddress.value == "Pilih Lokasi Pengantaran...") {
                            Get.snackbar('Error', 'Silakan pilih titik koordinat pengantaran');
                            return;
                          }

                          String finalAddress = controller.deliveryAddress.value;
                          if (detailController.text.trim().isNotEmpty) {
                            finalAddress += " (Detail: ${detailController.text.trim()})";
                          }

                          await controller.checkoutOrder(
                            finalAddress,
                            controller.deliveryLat.value,
                            controller.deliveryLng.value,
                            controller.deliveryDistance.value,
                            controller.paymentMethod.value,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: controller.selectedVehicleType.value == 'mobil' ? AppTheme.primaryBlue : Colors.orange.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(controller.selectedVehicleType.value == 'mobil' ? Icons.directions_car : Icons.two_wheeler, size: 20),
                            const SizedBox(width: 8),
                            Text('Pesan dengan Kurir ${controller.selectedVehicleType.value == 'mobil' ? 'Mobil' : 'Motor'}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                ),
              ),
            )
          ],
        ),
      );
    });
  }

  void _showPromoBottomSheet(BuildContext context) {
    final TextEditingController promoInputController = TextEditingController();
    final promos = homeController.promos;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.confirmation_num, color: Colors.orange, size: 22),
                      SizedBox(width: 8),
                      Text('Voucher & Promo Diskon', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              // Input Manual Kode Promo dari Panel
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: promoInputController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'Punya kode promo lain?',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      String code = promoInputController.text.trim().toUpperCase();
                      if (code.isNotEmpty) {
                        controller.applyPromo({'code': code, 'title': 'Kupon $code'});
                        Get.back();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Pakai'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (promos.isNotEmpty) ...[
                const Text('Voucher Aktif Tersedia:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 8),
                ...promos.map((p) {
                  bool isSelected = controller.appliedPromo.value?['code'] == p['code'];
                  dynamic amount = p['discount_amount'];
                  String badge = p['badge'] ?? (p['discount_type'] == 'percent' ? 'DISKON ${amount is double ? amount.toInt() : amount}%' : 'HEMAT');
                  String title = p['title'] ?? 'Promo ${p['code']}';
                  String desc = p['description'] ?? 'Gunakan kode ${p['code']}';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.green.shade50 : Colors.orange.shade50.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? Colors.green : Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text((p['code'] ?? 'PROMO').toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                              Text(desc, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            controller.applyPromo(p);
                            Get.back();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected ? Colors.green : Colors.orange.shade800,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: Text(isSelected ? 'Terpasang' : 'Gunakan'),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}
