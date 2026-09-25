import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/mart_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../core/utils.dart';
import '../home/map_picker_view.dart';

class MartCheckoutView extends StatelessWidget {
  const MartCheckoutView({super.key});

  @override
  Widget build(BuildContext context) {
    final MartController controller = Get.isRegistered<MartController>()
        ? Get.find<MartController>()
        : Get.put(MartController());
    final AuthController authController = Get.find<AuthController>();
    final TextEditingController notesInput = TextEditingController(text: controller.deliveryNotes.value);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Konfirmasi Belanja MaiMart',
          style: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: Obx(() {
        if (controller.cart.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_basket_outlined, size: 72, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text(
                  'Keranjang Belanja Masih Kosong',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Mulai Belanja'),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Toko Asal Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.storefront_rounded, color: Color(0xFF059669), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Toko Belanja',
                          style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          controller.currentMerchantName.value.isNotEmpty
                              ? controller.currentMerchantName.value
                              : 'Toko MaiMart',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        if (controller.currentMerchantAddress.value.isNotEmpty)
                          Text(
                            controller.currentMerchantAddress.value,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Alamat Pengantaran
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.location_on, color: Color(0xFF059669), size: 18),
                          SizedBox(width: 6),
                          Text('Alamat Pengantaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        ],
                      ),
                      TextButton(
                        onPressed: () async {
                          final result = await Get.to(() => const MapPickerView());
                          if (result != null && result is Map) {
                            final latLng = result['latLng'];
                            controller.setDeliveryLocation(
                              result['address']?.toString() ?? '',
                              latLng?.latitude ?? 0.0,
                              latLng?.longitude ?? 0.0,
                            );
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF059669),
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                        ),
                        child: const Text('Ubah Alamat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    controller.deliveryAddress.value.isNotEmpty
                        ? controller.deliveryAddress.value
                        : 'Pilih lokasi pengantaran Anda...',
                    style: TextStyle(
                      fontSize: 13,
                      color: controller.deliveryAddress.value.isNotEmpty ? Colors.grey.shade800 : Colors.grey.shade500,
                    ),
                  ),
                  if (controller.deliveryDistance.value > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Estimasi jarak pengantaran: ${controller.deliveryDistance.value.toStringAsFixed(1)} km',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF059669), fontWeight: FontWeight.bold),
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextField(
                    controller: notesInput,
                    onChanged: (val) => controller.deliveryNotes.value = val,
                    decoration: InputDecoration(
                      hintText: 'Patokan rumah / catatan driver (cth: Pagar hijau)',
                      hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      prefixIcon: const Icon(Icons.note_alt_outlined, size: 16, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. Pilihan Armada (Motor vs Mobil)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pilihan Kendaraan Pengantar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => controller.selectedVehicleType.value = 'motor',
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: controller.selectedVehicleType.value == 'motor'
                                  ? const Color(0xFFECFDF5)
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: controller.selectedVehicleType.value == 'motor'
                                    ? const Color(0xFF059669)
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.two_wheeler_rounded,
                                  color: controller.selectedVehicleType.value == 'motor'
                                      ? const Color(0xFF059669)
                                      : Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Motor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                      Text(
                                        Formatter.currency(controller.calculateDeliveryFee('motor')),
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => controller.selectedVehicleType.value = 'mobil',
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: controller.selectedVehicleType.value == 'mobil'
                                  ? const Color(0xFFECFDF5)
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: controller.selectedVehicleType.value == 'mobil'
                                    ? const Color(0xFF059669)
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.directions_car_rounded,
                                  color: controller.selectedVehicleType.value == 'mobil'
                                      ? const Color(0xFF059669)
                                      : Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Mobil (Banyak)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                      Text(
                                        Formatter.currency(controller.calculateDeliveryFee('mobil')),
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 4. Daftar Produk Belanjaan
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Daftar Belanja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      Text(
                        '${controller.cart.length} Jenis Item',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const Divider(height: 18),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.cart.length,
                    separatorBuilder: (context, index) => const Divider(height: 14),
                    itemBuilder: (context, index) {
                      var item = controller.cart[index];
                      double itemPrice = double.tryParse(item['price'].toString()) ?? 0;
                      int qty = item['quantity'] as int;
                      String unit = item['unit'] ?? 'pcs';
                      dynamic menuId = item['menu_id'];

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                ),
                                Text(
                                  '${Formatter.currency(itemPrice)} / $unit',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          // Counter
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF059669)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () => controller.updateCartQuantityByProductId(menuId, -1),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    child: Icon(
                                      qty == 1 ? Icons.delete_outline : Icons.remove,
                                      size: 14,
                                      color: qty == 1 ? Colors.red.shade600 : const Color(0xFF059669),
                                    ),
                                  ),
                                ),
                                Text(
                                  '$qty',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF059669)),
                                ),
                                InkWell(
                                  onTap: () => controller.updateCartQuantityByProductId(menuId, 1),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    child: Icon(Icons.add, size: 14, color: Color(0xFF059669)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            Formatter.currency(itemPrice * qty),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 5. Metode Pembayaran Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Tunai
                      Expanded(
                        child: InkWell(
                          onTap: () => controller.paymentMethod.value = 'cash',
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: controller.paymentMethod.value == 'cash'
                                  ? const Color(0xFFECFDF5)
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: controller.paymentMethod.value == 'cash'
                                    ? const Color(0xFF059669)
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.money_rounded,
                                  color: controller.paymentMethod.value == 'cash'
                                      ? const Color(0xFF059669)
                                      : Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                const Text('Tunai (Cash)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // MaiPay
                      Expanded(
                        child: InkWell(
                          onTap: () => controller.paymentMethod.value = 'maipay',
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: controller.paymentMethod.value == 'maipay'
                                  ? const Color(0xFFECFDF5)
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: controller.paymentMethod.value == 'maipay'
                                    ? const Color(0xFF059669)
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: controller.paymentMethod.value == 'maipay'
                                      ? const Color(0xFF059669)
                                      : Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('MaiPay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                      Text(
                                        Formatter.currency(authController.userData['balance'] ?? 0),
                                        style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 6. Rincian Pembayaran
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rincian Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Subtotal Belanja', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                      Text(Formatter.currency(controller.cartTotal), style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Ongkos Kirim Driver', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                      Text(Formatter.currency(controller.currentDeliveryFee), style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  if (controller.discountAmount > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Diskon Promo', style: TextStyle(color: Color(0xFF059669), fontSize: 13)),
                        Text('- ${Formatter.currency(controller.discountAmount)}',
                            style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ],
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                        Formatter.currency(controller.finalTotal),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        );
      }),
      bottomNavigationBar: Obx(() {
        if (controller.cart.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, -3),
              )
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () {
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
                          return;
                        }

                        if (controller.deliveryAddress.value.isEmpty || controller.deliveryAddress.value.contains('...')) {
                          Get.snackbar('Alamat Belum Dipilih', 'Silakan pilih lokasi pengantaran Anda terlebih dahulu');
                          return;
                        }

                        controller.checkoutOrder(
                          controller.deliveryAddress.value,
                          controller.deliveryLat.value,
                          controller.deliveryLng.value,
                          controller.deliveryDistance.value,
                          controller.paymentMethod.value,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: controller.isLoading.value
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_bag_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Pesan Sekarang • ${Formatter.currency(controller.finalTotal)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
