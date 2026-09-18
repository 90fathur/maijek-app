import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/mart_controller.dart';
import '../../core/utils.dart';
import 'mart_shop_detail_view.dart';
import 'mart_checkout_view.dart';

class MartSearchView extends StatefulWidget {
  final String? initialCategory;
  const MartSearchView({super.key, this.initialCategory});

  @override
  State<MartSearchView> createState() => _MartSearchViewState();
}

class _MartSearchViewState extends State<MartSearchView> with SingleTickerProviderStateMixin {
  final MartController controller = Get.isRegistered<MartController>()
      ? Get.find<MartController>()
      : Get.put(MartController());
  final TextEditingController searchInput = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.initialCategory != null && widget.initialCategory != 'Semua') {
      controller.searchCategory.value = widget.initialCategory!;
      controller.searchMart(category: widget.initialCategory!);
    }
  }

  @override
  void dispose() {
    searchInput.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Get.back(),
        ),
        title: Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: searchInput,
            autofocus: widget.initialCategory == null,
            textInputAction: TextInputAction.search,
            onChanged: (val) => controller.searchMart(query: val),
            onSubmitted: (val) => controller.searchMart(query: val),
            decoration: InputDecoration(
              hintText: 'Cari produk kebutuhan harian...',
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13.5),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF059669), size: 20),
              suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                      onPressed: () {
                        searchInput.clear();
                        controller.clearSearch();
                      },
                    )
                  : const SizedBox.shrink()),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 11),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Category chips
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  children: [
                    _buildCategoryChip('Semua', '🛒'),
                    ...MartController.mainCategories.map((c) => _buildCategoryChip(c.name, c.emoji)),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF059669),
                labelColor: const Color(0xFF059669),
                unselectedLabelColor: Colors.grey.shade600,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                tabs: const [
                  Tab(text: 'Produk Belanja'),
                  Tab(text: 'Toko / Mitra Mart'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductsTab(),
          _buildMerchantsTab(),
        ],
      ),
      bottomNavigationBar: _buildCartBottomBar(),
    );
  }

  Widget _buildCategoryChip(String label, String emoji) {
    return Obx(() {
      final isSelected = controller.searchCategory.value == label;
      return Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 6),
        child: FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
              Text(label),
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            String newCat = selected ? label : 'Semua';
            controller.searchMart(category: newCat);
          },
          selectedColor: const Color(0xFFECFDF5),
          checkmarkColor: const Color(0xFF059669),
          backgroundColor: Colors.white,
          side: BorderSide(
            color: isSelected ? const Color(0xFF059669) : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1.0,
          ),
          labelStyle: TextStyle(
            color: isSelected ? const Color(0xFF059669) : Colors.grey.shade800,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        ),
      );
    });
  }

  Widget _buildProductsTab() {
    return Obx(() {
      if (controller.isSearching.value) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF059669)),
        );
      }

      if (controller.searchProducts.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_basket_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'Tidak ada produk ditemukan',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 4),
              Text(
                'Coba gunakan kata kunci atau kategori lain',
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
              ),
            ],
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: controller.searchProducts.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          var product = controller.searchProducts[index];
          double price = double.tryParse(product['price']?.toString() ?? '0') ?? 0;
          double discPrice = double.tryParse(product['discount_price']?.toString() ?? '0') ?? 0;
          bool hasDiscount = discPrice > 0 && discPrice < price;
          double activePrice = hasDiscount ? discPrice : price;
          String unit = product['unit'] ?? 'pcs';
          String mName = product['merchant_name'] ?? 'Toko MaiMart';
          dynamic menuId = product['id'];

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product photo
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 76,
                    height: 76,
                    color: Colors.grey.shade100,
                    child: product['photo'] != null && product['photo'].toString().startsWith('http')
                        ? Image.network(
                            product['photo'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.shopping_bag, color: Colors.grey),
                          )
                        : const Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 36),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.storefront, size: 13, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              mName,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
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
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
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
                // Add to cart / quantity button
                Obx(() {
                  int qty = controller.getCartQuantity(menuId);
                  if (qty == 0) {
                    return ElevatedButton(
                      onPressed: () {
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
                      child: const Text('+ Tambah', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
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
                          onTap: () => controller.updateCartQuantityByProductId(menuId, -1),
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
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF059669)),
                        ),
                        InkWell(
                          onTap: () => controller.updateCartQuantityByProductId(menuId, 1),
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
      );
    });
  }

  Widget _buildMerchantsTab() {
    return Obx(() {
      if (controller.isSearching.value) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF059669)),
        );
      }

      if (controller.searchMerchants.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.storefront_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'Tidak ada toko ditemukan',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
              ),
            ],
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: controller.searchMerchants.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          var merchant = controller.searchMerchants[index];
          String name = merchant['name'] ?? 'Toko MaiMart';
          String address = merchant['address'] ?? '';
          String distance = merchant['distance'] != null
              ? '${double.parse(merchant['distance'].toString()).toStringAsFixed(1)} km'
              : '';

          return InkWell(
            onTap: () {
              controller.fetchMerchantDetail(int.parse(merchant['id'].toString()));
              Get.to(() => MartShopDetailView(merchantId: int.parse(merchant['id'].toString())));
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 60,
                      height: 60,
                      color: const Color(0xFFECFDF5),
                      child: merchant['photo'] != null && merchant['photo'].toString().startsWith('http')
                          ? Image.network(merchant['photo'], fit: BoxFit.cover)
                          : const Icon(Icons.storefront_rounded, color: Color(0xFF059669), size: 32),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          address,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (distance.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.near_me, size: 12, color: Color(0xFF059669)),
                              const SizedBox(width: 3),
                              Text(distance, style: const TextStyle(fontSize: 11.5, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ]
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  Widget? _buildCartBottomBar() {
    return Obx(() {
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
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
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
    });
  }
}
