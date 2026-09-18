import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/mart_controller.dart';
import '../../core/utils.dart';
import 'mart_checkout_view.dart';
import 'mart_search_view.dart';

class MartShopDetailView extends StatefulWidget {
  final int merchantId;
  const MartShopDetailView({super.key, required this.merchantId});

  @override
  State<MartShopDetailView> createState() => _MartShopDetailViewState();
}

class _MartShopDetailViewState extends State<MartShopDetailView> {
  final MartController controller = Get.isRegistered<MartController>()
      ? Get.find<MartController>()
      : Get.put(MartController());
  String selectedFilterCategory = 'Semua';

  @override
  void initState() {
    super.initState();
    controller.fetchMerchantDetail(widget.merchantId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Get.back(),
        ),
        title: Obx(() => Text(
              controller.merchantDetail['name'] ?? 'Toko MaiMart',
              style: const TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.bold, fontSize: 16),
            )),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF1F2937)),
            onPressed: () => Get.to(() => const MartSearchView()),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.merchantDetail.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF059669)));
        }

        var merchant = controller.merchantDetail;
        bool isOpen = (merchant['is_open'] == 1 || merchant['is_open'] == '1') &&
            (merchant['is_operating_today'] == null || merchant['is_operating_today'] == true);

        // Group/filter products
        List products = controller.merchantProducts;
        if (selectedFilterCategory != 'Semua') {
          products = products.where((p) {
            String cat = (p['category'] ?? '').toString().toLowerCase();
            return cat.contains(selectedFilterCategory.toLowerCase());
          }).toList();
        }

        // Get unique categories present in this merchant
        Set<String> categoriesPresent = {'Semua'};
        for (var p in controller.merchantProducts) {
          if (p['category'] != null && p['category'].toString().isNotEmpty) {
            categoriesPresent.add(p['category'].toString());
          }
        }

        return Column(
          children: [
            // 1. Merchant Header Card
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 64,
                          height: 64,
                          color: const Color(0xFFECFDF5),
                          child: merchant['photo'] != null && merchant['photo'].toString().startsWith('http')
                              ? Image.network(merchant['photo'], fit: BoxFit.cover)
                              : const Icon(Icons.storefront_rounded, color: Color(0xFF059669), size: 36),
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
                                    merchant['name'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isOpen ? const Color(0xFFECFDF5) : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: isOpen ? const Color(0xFF059669) : Colors.red),
                                  ),
                                  child: Text(
                                    isOpen ? 'BUKA' : 'TUTUP',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isOpen ? const Color(0xFF059669) : Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    merchant['address'] ?? '',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.schedule, size: 14, color: Colors.grey),
                                const SizedBox(width: 3),
                                Text(
                                  merchant['operating_days_text'] ?? 'Buka Setiap Hari',
                                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // 2. Filter Category Pills (if more than 1 category)
            if (categoriesPresent.length > 1)
              Container(
                height: 44,
                color: Colors.white,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  children: categoriesPresent.map((cat) {
                    bool isSel = selectedFilterCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSel,
                        onSelected: (val) {
                          setState(() {
                            selectedFilterCategory = cat;
                          });
                        },
                        selectedColor: const Color(0xFFECFDF5),
                        backgroundColor: Colors.grey.shade100,
                        side: BorderSide(
                          color: isSel ? const Color(0xFF059669) : Colors.transparent,
                        ),
                        labelStyle: TextStyle(
                          color: isSel ? const Color(0xFF059669) : Colors.grey.shade700,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            // 3. Products List
            Expanded(
              child: products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 54, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'Belum ada produk di kategori ini',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(14),
                      itemCount: products.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        var product = products[index];
                        double price = double.tryParse(product['price']?.toString() ?? '0') ?? 0;
                        double discPrice = double.tryParse(product['discount_price']?.toString() ?? '0') ?? 0;
                        bool hasDiscount = discPrice > 0 && discPrice < price;
                        double activePrice = hasDiscount ? discPrice : price;
                        String unit = product['unit'] ?? 'pcs';
                        dynamic productId = product['id'];

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 72,
                                  height: 72,
                                  color: Colors.grey.shade100,
                                  child: product['photo'] != null && product['photo'].toString().startsWith('http')
                                      ? Image.network(
                                          product['photo'],
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) =>
                                              const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
                                        )
                                      : const Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 34),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product['name'] ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    if (product['description'] != null && product['description'].toString().isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        product['description'],
                                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text(
                                          Formatter.currency(activePrice),
                                          style: const TextStyle(
                                            color: Color(0xFF059669),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          ' / $unit',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5),
                                        ),
                                        if (hasDiscount) ...[
                                          const SizedBox(width: 6),
                                          Text(
                                            Formatter.currency(price),
                                            style: TextStyle(
                                              decoration: TextDecoration.lineThrough,
                                              color: Colors.grey.shade400,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Counter or Add Button
                              Obx(() {
                                int qty = controller.getCartQuantity(productId);
                                if (qty == 0) {
                                  return ElevatedButton(
                                    onPressed: !isOpen
                                        ? null
                                        : () {
                                            controller.addToCart(product, 1, '');
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF059669),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      minimumSize: const Size(0, 32),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text('+ Tambah',
                                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                  );
                                }

                                return Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF059669)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                       InkWell(
                                         onTap: () => controller.updateCartQuantityByProductId(productId, -1),
                                         child: Padding(
                                           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                           child: Icon(
                                             qty == 1 ? Icons.delete_outline : Icons.remove,
                                             size: 15,
                                             color: qty == 1 ? Colors.red.shade600 : const Color(0xFF059669),
                                           ),
                                         ),
                                       ),
                                      Text(
                                        '$qty',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF059669)),
                                      ),
                                      InkWell(
                                        onTap: () => controller.updateCartQuantityByProductId(productId, 1),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                          child: Icon(Icons.add, size: 15, color: Color(0xFF059669)),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      }),
      bottomNavigationBar: Obx(() {
        if (controller.cart.isEmpty) return const SizedBox.shrink();
        int totalItems = controller.cart.fold(0, (sum, item) => sum + (item['quantity'] as int));

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFECFDF5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shopping_basket_rounded, color: Color(0xFF059669), size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$totalItems Produk di Keranjang',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        Formatter.currency(controller.cartTotal),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Get.to(() => const MartCheckoutView()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Lihat Keranjang', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
