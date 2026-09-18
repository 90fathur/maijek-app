import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/food_controller.dart';
import '../../core/theme.dart';
import 'merchant_detail_view.dart';
import 'food_search_view.dart';
import '../../widgets/shimmer_loading.dart';
import '../../core/utils.dart';

class MerchantsView extends StatelessWidget {
  final FoodController controller = Get.put(FoodController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('MaiFood', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            tooltip: 'Cari Makanan & Resto',
            onPressed: () => Get.to(() => const FoodSearchView()),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Trigger Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: GestureDetector(
              onTap: () => Get.to(() => const FoodSearchView()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))
                  ],
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppTheme.primaryBlue, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Mau makan apa hari ini? Cari makanan atau resto...',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.merchants.isEmpty) {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ShimmerLoading(width: double.infinity, height: 150, borderRadius: 12),
                          const SizedBox(height: 12),
                          const ShimmerLoading(width: 200, height: 20),
                          const SizedBox(height: 8),
                          const ShimmerLoading(width: 150, height: 14),
                        ],
                      ),
                    );
                  },
                );
              }

              if (controller.merchants.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.storefront_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 14),
                        const Text('Belum ada restoran yang buka saat ini.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 6),
                        Text('Silakan coba kembali nanti atau gunakan pencarian kuliner.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              }

              final hasNewMenus = controller.newMenus.isNotEmpty;
              final hasBestSellers = controller.bestSellerMenus.isNotEmpty;
              int headerSections = 0;
              if (hasNewMenus) headerSections++;
              if (hasBestSellers) headerSections++;

              return RefreshIndicator(
                onRefresh: () async {
                  await controller.fetchMerchants();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: headerSections + controller.merchants.length,
                  itemBuilder: (context, index) {
                    int currentHeader = 0;
                    if (hasNewMenus) {
                      if (index == currentHeader) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _buildNewMenusSection(),
                        );
                      }
                      currentHeader++;
                    }
                    if (hasBestSellers) {
                      if (index == currentHeader) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _buildBestSellerSection(),
                        );
                      }
                      currentHeader++;
                    }

                    int merchantIndex = index - headerSections;
                    var merchant = controller.merchants[merchantIndex];
                    return GestureDetector(
                      onTap: () {
                        controller.fetchMerchantDetail(int.parse(merchant['id'].toString()));
                        Get.to(() => MerchantDetailView());
                      },
                      child: Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (merchant['photo'] != null && merchant['photo'].toString().isNotEmpty)
                              Image.network(
                                merchant['photo'],
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  height: 150,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.restaurant, size: 50, color: Colors.grey),
                                ),
                              )
                            else
                              Container(
                                height: 150,
                                color: Colors.grey[200],
                                child: const Center(child: Icon(Icons.restaurant, size: 50, color: Colors.grey)),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          merchant['name'] ?? 'Restoran',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (merchant['distance'] != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${double.tryParse(merchant['distance'].toString())?.toStringAsFixed(1) ?? ''} km',
                                            style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 11),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    merchant['top_menu'] ?? 'Menu Lengkap Pilihan',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.primaryBlue, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          merchant['address'] ?? 'Alamat tidak tersedia',
                                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildNewMenusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFF059669), size: 20),
                SizedBox(width: 6),
                Text(
                  'Menu Baru Terupload',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => Get.to(() => const FoodSearchView(initialCategory: 'Menu Baru')),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lihat Semua',
                      style: TextStyle(color: Color(0xFF059669), fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 3),
                    Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFF059669)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 205,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: controller.newMenus.length,
            itemBuilder: (context, idx) {
              final item = controller.newMenus[idx];
              final String name = item['name'] ?? 'Menu Baru';
              final String mName = item['merchant_name'] ?? 'Restoran';
              final double origPrice = double.tryParse(item['price']?.toString() ?? '0') ?? 0;
              final double discPrice = double.tryParse(item['discount_price']?.toString() ?? '0') ?? origPrice;
              final String? photo = item['photo'];
              final dynamic mId = item['merchant_id'];

              return GestureDetector(
                onTap: () {
                  if (mId != null) {
                    controller.fetchMerchantDetail(int.parse(mId.toString()));
                    Get.to(() => MerchantDetailView());
                  }
                },
                child: Container(
                  width: 145,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))
                    ],
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                            child: photo != null && photo.isNotEmpty
                                ? Image.network(
                                    photo,
                                    height: 100,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 100,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.fastfood, color: Colors.grey),
                                    ),
                                  )
                                : Container(
                                    height: 100,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.fastfood, color: Colors.grey),
                                  ),
                          ),
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF059669), Color(0xFF10B981)],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.fiber_new, color: Colors.white, size: 14),
                                  SizedBox(width: 2),
                                  Text(
                                    'BARU',
                                    style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(mName, style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            if (discPrice > 0 && discPrice < origPrice) ...[
                              Text(
                                Formatter.currency(discPrice),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ] else ...[
                              Text(
                                Formatter.currency(origPrice),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                              ),
                            ],
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBestSellerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 22),
                SizedBox(width: 6),
                Text(
                  'Menu Paling Laris',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.deepOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Favorit',
                style: TextStyle(color: Colors.deepOrange, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 205,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: controller.bestSellerMenus.length,
            itemBuilder: (context, idx) {
              final item = controller.bestSellerMenus[idx];
              final String name = item['name'] ?? 'Menu Lezat';
              final String mName = item['merchant_name'] ?? 'Restoran';
              final double origPrice = double.tryParse(item['price']?.toString() ?? '0') ?? 0;
              final double discPrice = double.tryParse(item['discount_price']?.toString() ?? '0') ?? origPrice;
              final int totalSold = int.tryParse(item['total_sold']?.toString() ?? '0') ?? 0;
              final String? photo = item['photo'];
              final dynamic mId = item['merchant_id'];

              return GestureDetector(
                onTap: () {
                  if (mId != null) {
                    controller.fetchMerchantDetail(int.parse(mId.toString()));
                    Get.to(() => MerchantDetailView());
                  }
                },
                child: Container(
                  width: 145,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))
                    ],
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                            child: photo != null && photo.isNotEmpty
                                ? Image.network(
                                    photo,
                                    height: 100,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 100,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.fastfood, color: Colors.grey),
                                    ),
                                  )
                                : Container(
                                    height: 100,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.fastfood, color: Colors.grey),
                                  ),
                          ),
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF5722), Color(0xFFFF9800)],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                totalSold > 0 ? '🔥 $totalSold terjual' : '🔥 Terlaris',
                                style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(mName, style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            if (discPrice > 0 && discPrice < origPrice) ...[
                              Text(
                                Formatter.currency(discPrice),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ] else ...[
                              Text(
                                Formatter.currency(origPrice),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                              ),
                            ],
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        const Row(
          children: [
            Icon(Icons.storefront, size: 18, color: AppTheme.primaryBlue),
            SizedBox(width: 6),
            Text(
              'Daftar Restoran',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
