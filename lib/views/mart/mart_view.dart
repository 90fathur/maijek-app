import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/mart_controller.dart';
import '../../core/utils.dart';
import '../../widgets/shimmer_loading.dart';
import 'mart_shop_detail_view.dart';
import 'mart_search_view.dart';
import 'mart_checkout_view.dart';

class MartView extends StatelessWidget {
  const MartView({super.key});

  @override
  Widget build(BuildContext context) {
    final MartController controller = Get.isRegistered<MartController>()
        ? Get.find<MartController>()
        : Get.put(MartController());

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shopping_basket_rounded, color: Color(0xFF059669), size: 20),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MaiMart',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17),
                ),
                Text(
                  'Belanja Kebutuhan Harian',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            tooltip: 'Cari Produk & Toko',
            onPressed: () => Get.to(() => const MartSearchView()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.fetchMerchants(),
        color: const Color(0xFF059669),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            // 1. Search Trigger Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () => Get.to(() => const MartSearchView()),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      )
                    ],
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Color(0xFF059669), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Cari sayur, beras, telur, obat, popok...',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 2. Banner Promo Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF065F46), Color(0xFF059669), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF059669).withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'BARU DI MAIJEK',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Belanja Cepat & Segar\nLangsung Antar ke Rumah',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Sayur, sembako, obat & kebutuhan harian',
                            style: TextStyle(color: Colors.white70, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Text('🛒', style: TextStyle(fontSize: 36)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 3. 8 Kategori Utama MaiMart
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Kategori Pilihan',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1F2937)),
                  ),
                  GestureDetector(
                    onTap: () => Get.to(() => const MartSearchView()),
                    child: const Text(
                      'Lihat Semua',
                      style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 8-item Category Grid (2 rows x 4 columns)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: MartController.mainCategories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.76,
                ),
                itemBuilder: (context, index) {
                  final cat = MartController.mainCategories[index];
                  return GestureDetector(
                    onTap: () {
                      controller.fetchMerchants(category: cat.name);
                      Get.to(() => MartSearchView(initialCategory: cat.name));
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: cat.bgColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: cat.color.withValues(alpha: 0.2)),
                            boxShadow: [
                              BoxShadow(
                                color: cat.color.withValues(alpha: 0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Center(
                            child: Text(cat.emoji, style: const TextStyle(fontSize: 24)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cat.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF374151),
                            height: 1.15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),

            // 4. Toko Mart Terdekat Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Toko & Mitra MaiMart Terdekat',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1F2937)),
                  ),
                  Obx(() => Text(
                        '${controller.merchants.length} Toko',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Category Filter Chips
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  _buildCategoryFilterChip(controller, 'Semua', '🛒'),
                  ...MartController.mainCategories.map((c) => _buildCategoryFilterChip(controller, c.name, c.emoji)),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Merchant List
            Obx(() {
              if (controller.isLoading.value && controller.merchants.isEmpty) {
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 4,
                  itemBuilder: (_, _) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          ShimmerLoading(width: 70, height: 70, borderRadius: 12),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ShimmerLoading(width: 150, height: 16),
                                SizedBox(height: 8),
                                ShimmerLoading(width: 100, height: 12),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              if (controller.merchants.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.storefront_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada toko MaiMart di kategori ini',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Nantikan kehadiran mitra toko baru segera!',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: controller.merchants.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  var m = controller.merchants[index];
                  String name = m['name'] ?? 'Toko MaiMart';
                  String address = m['address'] ?? '';
                  String topProduct = m['top_product'] ?? 'Produk Lengkap';
                  String categoryLabel = m['category_label'] ?? 'Toko Kebutuhan';
                  String distance = m['distance'] != null
                      ? '${double.parse(m['distance'].toString()).toStringAsFixed(1)} km'
                      : '';
                  bool isOpen = (m['is_open'] == 1 || m['is_open'] == '1');

                  return InkWell(
                    onTap: () {
                      controller.fetchMerchantDetail(int.parse(m['id'].toString()));
                      Get.to(() => MartShopDetailView(merchantId: int.parse(m['id'].toString())));
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Photo
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  width: 76,
                                  height: 76,
                                  color: const Color(0xFFECFDF5),
                                  child: m['photo'] != null && m['photo'].toString().startsWith('http')
                                      ? Image.network(
                                          m['photo'],
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) =>
                                              const Icon(Icons.storefront_rounded, color: Color(0xFF059669), size: 36),
                                        )
                                      : const Icon(Icons.storefront_rounded, color: Color(0xFF059669), size: 36),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isOpen ? const Color(0xFF059669) : Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isOpen ? 'BUKA' : 'TUTUP',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          // Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (distance.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFECFDF5),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          distance,
                                          style: const TextStyle(
                                            color: Color(0xFF059669),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  categoryLabel,
                                  style: const TextStyle(color: Color(0xFF059669), fontSize: 11.5, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 13, color: Colors.grey),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        address,
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.shopping_bag_outlined, size: 13, color: Colors.grey),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        topProduct,
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5),
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
                  );
                },
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
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
                        '$totalItems Produk Belanja',
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

  Widget _buildCategoryFilterChip(MartController controller, String label, String emoji) {
    return Obx(() {
      final isSel = controller.selectedCategory.value == label;
      return Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 4),
        child: FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 12.5)),
              const SizedBox(width: 4),
              Text(label),
            ],
          ),
          selected: isSel,
          onSelected: (val) {
            controller.fetchMerchants(category: val ? label : 'Semua');
          },
          selectedColor: const Color(0xFFECFDF5),
          checkmarkColor: const Color(0xFF059669),
          backgroundColor: Colors.white,
          side: BorderSide(
            color: isSel ? const Color(0xFF059669) : Colors.grey.shade300,
            width: isSel ? 1.5 : 1.0,
          ),
          labelStyle: TextStyle(
            color: isSel ? const Color(0xFF059669) : Colors.grey.shade800,
            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        ),
      );
    });
  }
}
