import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/home_controller.dart';
import '../ride/ride_view.dart';
import '../food/merchants_view.dart';
import '../food/food_search_view.dart';
import '../../controllers/food_controller.dart';
import '../food/merchant_detail_view.dart';
import '../wallet/topup_view.dart';
import '../mart/mart_view.dart';
import '../mart/mart_shop_detail_view.dart';
import '../../core/utils.dart';
import '../../controllers/mart_controller.dart';
import '../../controllers/order_controller.dart';

class HomeView extends StatelessWidget {
  HomeView({super.key});

  final AuthController authController = Get.find<AuthController>();
  final HomeController homeController = Get.put(HomeController());
  final FoodController foodController = Get.put(FoodController());
  final MartController martController = Get.isRegistered<MartController>()
      ? Get.find<MartController>()
      : Get.put(MartController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await homeController.fetchHomeData();
              await homeController.checkActiveOrder();
              await foodController.fetchMerchants();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAccountCards(),
                        const SizedBox(height: 18),
                        _buildServiceGrid(),
                        const SizedBox(height: 24),
                        _buildNewMenusSection(),
                        const SizedBox(height: 24),
                        _buildNewMerchantsSection(),
                        const SizedBox(height: 22),
                        _buildBanners(),
                        const SizedBox(height: 20),
                        _buildNewUserVoucherCard(),
                        const SizedBox(height: 24),
                        _buildFlashSaleSection(),
                        const SizedBox(height: 24),
                        _buildBestSellerFoodSection(),
                        _buildBestSellerMartSection(),
                        _buildNearbyFood(),
                        const SizedBox(height: 24),
                        _buildPromoFeed(),
                        const SizedBox(height: 90), // ekstra padding agar konten terbawah tidak tertutup floating card
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: AppTheme.primaryNavy,
      expandedHeight: 180.0,
      floating: false,
      pinned: true,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 16.0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.navyDark, AppTheme.primaryNavy, AppTheme.navyLight],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              // Ambient gold radial glow di sudut kanan atas
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.accentGold.withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 36, top: 78),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Badge Tagline Resmi Logo Maijek
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.45)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, color: AppTheme.accentGold, size: 13),
                          SizedBox(width: 6),
                          Text(
                            'Kita Bertemu, Kita Bertumbuh',
                            style: TextStyle(
                              color: AppTheme.accentGold,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() {
                      final name = (authController.userData['name'] ?? 'Pengguna Maijek').toString();
                      return Text(
                        'Hai, $name 👋',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      title: Row(
        children: [
          // Logo 3 Warna Resmi
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/logo.png',
              height: 24,
              width: 24,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => Get.to(() => const FoodSearchView()),
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: AppTheme.accentGold, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cari layanan, resto, tujuan...',
                        style: TextStyle(color: Colors.white70, fontSize: 12.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => Get.toNamed('/profile'),
            child: Obx(() {
              String photoUrl = (authController.userData['photo_url'] ?? '').toString();
              return Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.accentGold, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentGold.withValues(alpha: 0.3),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: photoUrl.isNotEmpty
                      ? (photoUrl.startsWith('http')
                          ? Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => const Icon(Icons.person, color: Colors.white, size: 20),
                            )
                          : Image.file(
                              File(photoUrl),
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => const Icon(Icons.person, color: Colors.white, size: 20),
                            ))
                      : Container(
                          color: AppTheme.navyLight,
                          child: const Icon(Icons.person, color: Colors.white, size: 20),
                        ),
                ),
              );
            }),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(24),
        child: Container(
          height: 24,
          decoration: const BoxDecoration(
            color: AppTheme.backgroundLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountCards() {
    return Obx(() {
      final balance = authController.userData['balance'] ?? 0;
      final balanceStr = Formatter.currency(balance);
      final coins = authController.userData['coins'] ?? 0;

      return Row(
        children: [
          // 1. MaiPay Saldo (Midnight Navy & Radiant Gold)
          Expanded(
            flex: 6,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.navyDark, AppTheme.primaryNavy],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryNavy.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: AppTheme.accentGold.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.accentGold.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: AppTheme.accentGold,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'MaiPay',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Get.toNamed('/wallet'),
                        child: const Row(
                          children: [
                            Text(
                              'Riwayat',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Colors.white70, size: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    balanceStr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Get.to(() => const TopUpView()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentGold,
                        foregroundColor: AppTheme.navyDark,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        minimumSize: const Size(0, 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle, size: 14, color: AppTheme.navyDark),
                          SizedBox(width: 4),
                          Text(
                            'Top Up',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.navyDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 2. Koin Maijek & Reward (Golden Amber & Crisp Card)
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: AppTheme.accentGold.withValues(alpha: 0.4),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.stars_rounded,
                          color: AppTheme.goldDark,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Koin',
                        style: TextStyle(
                          color: AppTheme.textMain,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$coins Koin',
                    style: const TextStyle(
                      color: AppTheme.goldDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => homeController.checkDailyReward(isManual: true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryNavy,
                        side: const BorderSide(color: AppTheme.accentGold, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        minimumSize: const Size(0, 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Klaim',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildServiceGrid() {
    return Obx(() {
      final bool hasActivePromos = homeController.promos.isNotEmpty;
      final String rideBadge = hasActivePromos ? 'PROMO' : 'CEPAT';
      final String carBadge = hasActivePromos ? 'PROMO' : 'NYAMAN';
      final String sendBadge = hasActivePromos ? 'HEMAT' : 'KILAT';

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          children: [
            // Baris 1: Makanan, MaiMart, Ride
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _buildServiceItem(
                    icon: Icons.restaurant_rounded,
                    label: 'Makanan',
                    color: const Color(0xFFE65100),
                    bgColor: const Color(0xFFFFF3E0),
                    badge: 'PROMO',
                    onTap: () => Get.to(() => MerchantsView()),
                  ),
                ),
                Expanded(
                  child: _buildServiceItem(
                    icon: Icons.shopping_basket_rounded,
                    label: 'MaiMart',
                    color: const Color(0xFF059669),
                    bgColor: const Color(0xFFECFDF5),
                    badge: 'BARU',
                    onTap: () => Get.to(() => const MartView()),
                  ),
                ),
                Expanded(
                  child: _buildServiceItem(
                    icon: Icons.two_wheeler_rounded,
                    label: 'Ride',
                    color: AppTheme.primaryNavy,
                    bgColor: AppTheme.primaryNavy.withValues(alpha: 0.10),
                    badge: rideBadge,
                    onTap: () => Get.to(() => const RideView(initialVehicle: 'motor')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Baris 2: Car, Send, Titip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _buildServiceItem(
                    icon: Icons.directions_car_rounded,
                    label: 'Car',
                    color: const Color(0xFF1E3A8A),
                    bgColor: const Color(0xFFEFF6FF),
                    badge: carBadge,
                    onTap: () => Get.to(() => const RideView(initialVehicle: 'car')),
                  ),
                ),
                Expanded(
                  child: _buildServiceItem(
                    icon: Icons.local_shipping_rounded,
                    label: 'Send',
                    color: const Color(0xFF0F766E),
                    bgColor: const Color(0xFFF0FDFA),
                    badge: sendBadge,
                    onTap: () => Get.toNamed('/send'),
                  ),
                ),
                Expanded(
                  child: _buildServiceItem(
                    icon: Icons.shopping_bag_rounded,
                    label: 'Titip',
                    color: const Color(0xFF7E22CE),
                    bgColor: const Color(0xFFFAF5FF),
                    badge: 'HEMAT',
                    onTap: () => Get.toNamed('/titip'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildServiceItem({
    required IconData icon,
    required String label,
    required Color color,
    Color? bgColor,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: bgColor ?? color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.15)),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain,
                ),
              ),
            ],
          ),
          if (badge != null)
            Positioned(
              top: -6,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  gradient: badge == 'PROMO' || badge == 'HEMAT'
                      ? const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFFF7043)])
                      : badge == 'BARU'
                          ? const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)])
                          : const LinearGradient(colors: [AppTheme.primaryNavy, AppTheme.navyLight]),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 1. Auto-sliding Banner Carousel Dinamis (Dari CMS Panel Admin)
  Widget _buildBanners() {
    return Obx(() {
      final banners = homeController.banners;
      if (banners.isEmpty) return const SizedBox.shrink();

      return Column(
        children: [
          SizedBox(
            height: 150,
            child: PageView.builder(
              controller: homeController.bannerPageController,
              onPageChanged: (idx) => homeController.currentBannerPage.value = idx,
              itemCount: banners.length,
              itemBuilder: (context, index) {
                final banner = banners[index];
                final String img = banner['image_path'] ?? '';
                final String title = banner['title'] ?? 'Promo Maijek';
                final String? promoCode = banner['promo_code'];

                return GestureDetector(
                  onTap: () {
                    if (promoCode != null && promoCode.isNotEmpty) {
                      Clipboard.setData(ClipboardData(text: promoCode));
                      Get.snackbar(
                        '🎉 Voucher Disalin!',
                        'Kode promo $promoCode siap digunakan saat checkout!',
                        backgroundColor: Colors.orange.shade800,
                        colorText: Colors.white,
                        snackPosition: SnackPosition.TOP,
                      );
                    }
                    Get.to(() => MerchantsView());
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 3))
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: img.isNotEmpty
                          ? Image.network(
                              img,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: AppTheme.primaryNavy,
                                alignment: Alignment.center,
                                child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            )
                          : Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFFFF5722), Color(0xFFFF9800)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                title,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (banners.length > 1) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(banners.length, (idx) {
                bool isActive = homeController.currentBannerPage.value == idx;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.accentGold : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ],
        ],
      );
    });
  }

  // 2. Kupon Tiket Interaktif Dinamis (Dari Panel Admin Promo)
  Widget _buildNewUserVoucherCard() {
    return Obx(() {
      final promos = homeController.promos;
      if (promos.isEmpty) return const SizedBox.shrink();

      final promo = promos.firstWhere(
        (p) => (p['code'] ?? '').toString().toUpperCase() == 'MAIPERTAMA',
        orElse: () => promos.first,
      );

      final String code = promo['code'] ?? 'PROMO';
      final dynamic amount = promo['discount_amount'];
      final String badge = promo['badge'] ?? (promo['discount_type'] == 'percent' ? 'DISKON ${amount is double ? amount.toInt() : amount}%' : 'HEMAT');
      final String title = promo['title'] ?? 'Kupon Promo Spesial';
      final String desc = promo['description'] ?? 'Gunakan kode promo $code';

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade50, Colors.amber.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.shade300, width: 1.2),
          boxShadow: [
            BoxShadow(color: Colors.orange.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 3))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.deepOrange, Colors.orangeAccent]),
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [BoxShadow(color: Colors.deepOrangeAccent, blurRadius: 4)],
              ),
              child: const Icon(Icons.card_giftcard, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Kode: $code • $desc',
                    style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                Get.snackbar(
                  '🎉 Voucher Disalin!',
                  'Kode $code siap digunakan di keranjang belanja!',
                  backgroundColor: Colors.deepOrange,
                  colorText: Colors.white,
                  snackPosition: SnackPosition.TOP,
                );
                Get.to(() => MerchantsView());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                elevation: 1,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: const Size(54, 34),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Klaim', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            )
          ],
        ),
      );
    });
  }

  // 2b. Mitra / Merchant yang Baru Bergabung
  Widget _buildNewMerchantsSection() {
    return Obx(() {
      final items = homeController.newMerchants;
      if (items.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.30),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mitra Baru Bergabung',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMain,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Resto & toko baru pilihan di sekitarmu',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Get.to(() => MerchantsView()),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryNavy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryNavy.withValues(alpha: 0.15)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Semua',
                        style: TextStyle(
                          color: AppTheme.primaryNavy,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right, color: AppTheme.primaryNavy, size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 208,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final String name = item['name'] ?? 'Mitra Baru';
                final String type = (item['merchant_type'] ?? 'food').toString().toLowerCase();
                final bool isMart = type == 'mart';
                final String category = item['category'] ?? (isMart ? 'MaiMart' : 'Restoran');
                final String topMenu = item['top_menu'] ?? 'Menu Lengkap';
                final String? photo = item['photo'];
                final dynamic mId = item['id'];
                final dynamic distance = item['distance'];

                return GestureDetector(
                  onTap: () {
                    if (isMart && mId != null) {
                      Get.to(() => MartShopDetailView(merchantId: int.parse(mId.toString())));
                    } else if (mId != null) {
                      foodController.fetchMerchantDetail(int.parse(mId.toString()));
                      Get.to(() => MerchantDetailView());
                    } else {
                      Get.to(() => isMart ? const MartView() : MerchantsView());
                    }
                  },
                  child: Container(
                    width: 155,
                    margin: const EdgeInsets.only(right: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: photo != null && photo.isNotEmpty
                                  ? Image.network(
                                      photo,
                                      height: 100,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                                    )
                                  : _buildPlaceholder(),
                            ),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF00B074), Color(0xFF00D68F)],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black26, blurRadius: 4),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.auto_awesome, color: Colors.white, size: 10),
                                    SizedBox(width: 3),
                                    Text(
                                      'BARU',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppTheme.textMain,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                category,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isMart ? Colors.green.shade700 : AppTheme.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(
                                    isMart ? Icons.shopping_bag_outlined : Icons.restaurant_menu,
                                    size: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      topMenu,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (distance != null) ...[
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 11, color: Colors.grey),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${double.tryParse(distance.toString())?.toStringAsFixed(1) ?? '0.5'} km',
                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  // 2c. Menu Baru Terupload
  Widget _buildNewMenusSection() {
    return Obx(() {
      final items = homeController.latestMenus;
      if (items.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF8C00), Color(0xFFFF5722)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5722).withValues(alpha: 0.30),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Flexible(
                          child: Text(
                            'Menu Baru Terupload',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textMain,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00B074), Color(0xFF00D68F)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'FRESH',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Menu lezat terbaru yang baru diunggah mitra',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Get.to(() => const FoodSearchView(initialCategory: 'Menu Baru')),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryNavy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryNavy.withValues(alpha: 0.15)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Semua',
                        style: TextStyle(
                          color: AppTheme.primaryNavy,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right, color: AppTheme.primaryNavy, size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 232,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final String name = item['name'] ?? 'Menu Baru';
                final String mName = item['merchant_name'] ?? 'Restoran';
                final double origPrice = double.tryParse(item['price']?.toString() ?? '0') ?? 0;
                final double discPrice = double.tryParse(item['discount_price']?.toString() ?? '0') ?? origPrice;
                final bool hasDiscount = discPrice > 0 && discPrice < origPrice;
                final int discPercent = int.tryParse(item['discount_percent']?.toString() ?? '0') ??
                    (hasDiscount && origPrice > 0 ? (((origPrice - discPrice) / origPrice) * 100).round() : 0);
                final String? photo = item['photo'];
                final dynamic mId = item['merchant_id'];
                final dynamic isOpen = item['is_open'];
                final bool isStoreOpen = isOpen == 1 || isOpen == '1' || isOpen == true;

                return GestureDetector(
                  onTap: () {
                    if (mId != null) {
                      foodController.fetchMerchantDetail(int.parse(mId.toString()));
                      Get.to(() => MerchantDetailView());
                    } else {
                      Get.to(() => MerchantsView());
                    }
                  },
                  child: Container(
                    width: 154,
                    margin: const EdgeInsets.only(right: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: photo != null && photo.isNotEmpty
                                  ? Image.network(
                                      photo,
                                      height: 110,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                                    )
                                  : _buildPlaceholder(),
                            ),
                            // Badge Promo atau Baru
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: hasDiscount
                                        ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                                        : [const Color(0xFF00B074), const Color(0xFF059669)],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      hasDiscount ? Icons.local_fire_department : Icons.auto_awesome,
                                      color: Colors.white,
                                      size: 10,
                                    ),
                                    const SizedBox(width: 2.5),
                                    Text(
                                      hasDiscount ? 'HEMAT $discPercent%' : 'BARU',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Status Buka Toko
                            if (isStoreOpen)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.94),
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black12, blurRadius: 3),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 5.5,
                                        height: 5.5,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF10B981),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 3.5),
                                      const Text(
                                        'Buka',
                                        style: TextStyle(
                                          color: Color(0xFF15803D),
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppTheme.textMain,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.storefront_outlined, size: 11.5, color: AppTheme.primaryNavy),
                                  const SizedBox(width: 3.5),
                                  Expanded(
                                    child: Text(
                                      mName,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 7),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (hasDiscount)
                                          Text(
                                            Formatter.currency(origPrice),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.shade400,
                                              decoration: TextDecoration.lineThrough,
                                              height: 1,
                                            ),
                                          ),
                                        Text(
                                          Formatter.currency(hasDiscount ? discPrice : origPrice),
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF00A86B),
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 25,
                                    height: 25,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [AppTheme.primaryNavy, AppTheme.navyLight],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryNavy.withValues(alpha: 0.25),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 13),
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
          ),
        ],
      );
    });
  }

  // 3. Flash Sale & Menu Diskon Spesial Hari Ini
  Widget _buildFlashSaleSection() {
    return Obx(() {
      final items = homeController.flashSaleMenus;
      if (items.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚡', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Diskon Spesial Hari Ini',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Get.to(() => MerchantsView()),
                child: const Text('Lihat Semua', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 215,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final String name = item['name'] ?? 'Menu Lezat';
                final String mName = item['merchant_name'] ?? 'Restoran';
                final double origPrice = double.tryParse(item['price']?.toString() ?? '0') ?? 0;
                final double discPrice = double.tryParse(item['discount_price']?.toString() ?? '0') ?? origPrice;
                final int pct = int.tryParse(item['discount_percent']?.toString() ?? '25') ?? 25;
                final String? photo = item['photo'];

                return GestureDetector(
                  onTap: () {
                    final isMart = (item['merchant_type'] ?? '').toString().toLowerCase() == 'mart';
                    final dynamic mId = item['merchant_id'];
                    if (isMart && mId != null) {
                      Get.to(() => MartShopDetailView(merchantId: int.parse(mId.toString())));
                    } else if (mId != null) {
                      foodController.fetchMerchantDetail(int.parse(mId.toString()));
                      Get.to(() => MerchantDetailView());
                    } else {
                      Get.to(() => isMart ? const MartView() : MerchantsView());
                    }
                  },
                  child: Container(
                    width: 150,
                    margin: const EdgeInsets.only(right: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))
                      ],
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: photo != null && photo.isNotEmpty
                                  ? Image.network(
                                      photo,
                                      height: 105,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                                    )
                                  : _buildPlaceholder(),
                            ),
                            Positioned(
                              top: 8, left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                ),
                                child: Text('-$pct%', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(mName, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              // Harga Coret
                              if (origPrice > discPrice)
                                Text(
                                  Formatter.currency(origPrice),
                                  style: const TextStyle(fontSize: 10.5, color: Colors.grey, decoration: TextDecoration.lineThrough),
                                ),
                              Text(
                                Formatter.currency(discPrice),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
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
    });
  }

  // 3b. Menu Paling Laris MaiFood (Kuliner Restoran)
  Widget _buildBestSellerFoodSection() {
    return Obx(() {
      final items = homeController.bestSellerFoodMenus;
      if (items.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5722).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('🔥', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Menu Terlaris MaiFood',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Kuliner lezat paling sering dipesan',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Get.to(() => MerchantsView()),
                  child: const Text('Lihat Semua', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
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
                        foodController.fetchMerchantDetail(int.parse(mId.toString()));
                        Get.to(() => MerchantDetailView());
                      } else {
                        Get.to(() => MerchantsView());
                      }
                    },
                    child: Container(
                      width: 155,
                      margin: const EdgeInsets.only(right: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))
                        ],
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                child: photo != null && photo.isNotEmpty
                                    ? Image.network(
                                        photo,
                                        height: 110,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                                      )
                                    : _buildPlaceholder(),
                              ),
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFF5722), Color(0xFFFF9800)],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.local_fire_department, color: Colors.white, size: 12),
                                      const SizedBox(width: 2),
                                      Text(
                                        totalSold > 0 ? '$totalSold terjual' : 'Terlaris',
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(Icons.restaurant_rounded, size: 12, color: Colors.grey.shade600),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(mName, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                if (discPrice > 0 && discPrice < origPrice) ...[
                                  Text(
                                    Formatter.currency(origPrice),
                                    style: const TextStyle(fontSize: 10.5, color: Colors.grey, decoration: TextDecoration.lineThrough),
                                  ),
                                  Text(
                                    Formatter.currency(discPrice),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green),
                                  ),
                                ] else ...[
                                  Text(
                                    Formatter.currency(origPrice),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
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
        ),
      );
    });
  }

  // 3c. Produk Paling Laris MaiMart (Toko & Kebutuhan)
  Widget _buildBestSellerMartSection() {
    return Obx(() {
      final items = homeController.bestSellerMartMenus;
      if (items.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('🛒', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Produk Terlaris MaiMart',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Kebutuhan harian & sembako terfavorit',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Get.to(() => const MartView()),
                  child: const Text('Lihat Semua', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final String name = item['name'] ?? 'Produk Mart';
                  final String mName = item['merchant_name'] ?? 'Toko Mart';
                  final double origPrice = double.tryParse(item['price']?.toString() ?? '0') ?? 0;
                  final double discPrice = double.tryParse(item['discount_price']?.toString() ?? '0') ?? origPrice;
                  final int totalSold = int.tryParse(item['total_sold']?.toString() ?? '0') ?? 0;
                  final String? photo = item['photo'];
                  final dynamic mId = item['merchant_id'];
                  final String unit = (item['unit'] ?? '').toString().trim();

                  return GestureDetector(
                    onTap: () {
                      if (mId != null) {
                        Get.to(() => MartShopDetailView(merchantId: int.parse(mId.toString())));
                      } else {
                        Get.to(() => const MartView());
                      }
                    },
                    child: Container(
                      width: 155,
                      margin: const EdgeInsets.only(right: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))
                        ],
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                child: photo != null && photo.isNotEmpty
                                    ? Image.network(
                                        photo,
                                        height: 110,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                                      )
                                    : _buildPlaceholder(),
                              ),
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF059669), Color(0xFF10B981)],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 12),
                                      const SizedBox(width: 2),
                                      Text(
                                        totalSold > 0 ? '$totalSold terjual' : 'Favorit',
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (unit.isNotEmpty)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      '/$unit',
                                      style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.storefront, size: 12, color: Color(0xFF059669)),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(mName, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                if (discPrice > 0 && discPrice < origPrice) ...[
                                  Text(
                                    Formatter.currency(origPrice),
                                    style: const TextStyle(fontSize: 10.5, color: Colors.grey, decoration: TextDecoration.lineThrough),
                                  ),
                                  Text(
                                    Formatter.currency(discPrice),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                                  ),
                                ] else ...[
                                  Text(
                                    Formatter.currency(origPrice),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
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
        ),
      );
    });
  }

  // 4. Restoran Populer & Terdekat
  Widget _buildNearbyFood() {
    return Obx(() {
      if (foodController.isLoading.value && foodController.merchants.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (foodController.merchants.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🍽️', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Restoran Pilihan',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Get.to(() => MerchantsView()),
                child: const Text('Lihat Semua', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 190,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: foodController.merchants.length > 6 ? 6 : foodController.merchants.length,
              itemBuilder: (context, index) {
                var merchant = foodController.merchants[index];
                return GestureDetector(
                  onTap: () {
                    foodController.fetchMerchantDetail(int.parse(merchant['id'].toString()));
                    Get.to(() => MerchantDetailView());
                  },
                  child: Container(
                    width: 145,
                    margin: const EdgeInsets.only(right: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: merchant['photo'] != null && merchant['photo'].toString().isNotEmpty
                              ? Image.network(
                                  merchant['photo'],
                                  height: 100,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                                )
                              : _buildPlaceholder(),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(merchant['name'] ?? 'Restoran', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(merchant['top_menu'] ?? 'Menu Lengkap', style: const TextStyle(fontSize: 11, color: AppTheme.primaryBlue, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 12),
                                  const SizedBox(width: 2),
                                  Text(merchant['rating'] != null ? merchant['rating'].toString() : '5.0', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  if (merchant['distance'] != null) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.location_on, color: Colors.grey, size: 12),
                                    const SizedBox(width: 2),
                                    Text('${double.tryParse(merchant['distance'].toString())?.toStringAsFixed(1) ?? '0.5'} km', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ],
                              )
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
    });
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 100,
      width: double.infinity,
      color: Colors.grey[200],
      child: const Icon(Icons.restaurant, color: Colors.grey, size: 30),
    );
  }


  // 5. Rekomendasi Promo & Kupon Hemat
  Widget _buildPromoFeed() {
    return Obx(() {
      final promos = homeController.promos;
      if (homeController.isLoading.value && promos.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      
      if (promos.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🎟️', style: TextStyle(fontSize: 18)),
              SizedBox(width: 6),
              Text('Promo & Voucher Menarik', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
            ],
          ),
          const SizedBox(height: 14),
          ...promos.map((promo) {
            final String code = promo['code'] ?? 'PROMO';
            final String title = promo['title'] ?? 'Promo Diskon';
            final String desc = promo['description'] ?? 'Gunakan voucher ini saat checkout untuk mendapatkan potongan harga spesial.';
            final String badge = promo['badge'] ?? (promo['discount_type'] == 'percent' ? 'DISKON ${promo['discount_amount']}%' : 'HEMAT RP ${promo['discount_amount']}');

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.navyDark, AppTheme.primaryNavy]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.local_offer, color: AppTheme.accentGold, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.accentGold,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                badge,
                                style: const TextStyle(
                                  color: AppTheme.navyDark,
                                  fontSize: 9.0,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                code,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  color: AppTheme.primaryNavy,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          desc,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final orderCtrl = Get.isRegistered<OrderController>()
                          ? Get.find<OrderController>()
                          : Get.put(OrderController());
                      
                      Get.bottomSheet(
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.local_offer, color: AppTheme.primaryNavy),
                                  const SizedBox(width: 8),
                                  Text('Gunakan Kupon $code', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Pilih layanan untuk menikmati potongan harga voucher ini:', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                              const SizedBox(height: 14),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const CircleAvatar(backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.two_wheeler_rounded, color: AppTheme.primaryNavy)),
                                title: const Text('Mai-Ride (Motor)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                subtitle: const Text('Perjalanan cepat & hemat bersama kurir motor', style: TextStyle(fontSize: 12)),
                                trailing: const Icon(Icons.chevron_right, size: 20),
                                onTap: () {
                                  Get.back();
                                  orderCtrl.appliedPromo.value = code;
                                  orderCtrl.promoAmount = int.tryParse(promo['discount_amount']?.toString() ?? '0') ?? 0;
                                  orderCtrl.promoType = promo['discount_type'] ?? 'fixed';
                                  orderCtrl.applyPromoDiscount();
                                  Get.to(() => const RideView(initialVehicle: 'motor'));
                                },
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const CircleAvatar(backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.directions_car_rounded, color: Color(0xFF1E3A8A))),
                                title: const Text('Mai-Car (Mobil)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                subtitle: const Text('Perjalanan nyaman bersama armada mobil', style: TextStyle(fontSize: 12)),
                                trailing: const Icon(Icons.chevron_right, size: 20),
                                onTap: () {
                                  Get.back();
                                  orderCtrl.appliedPromo.value = code;
                                  orderCtrl.promoAmount = int.tryParse(promo['discount_amount']?.toString() ?? '0') ?? 0;
                                  orderCtrl.promoType = promo['discount_type'] ?? 'fixed';
                                  orderCtrl.applyPromoDiscount();
                                  Get.to(() => const RideView(initialVehicle: 'car'));
                                },
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const CircleAvatar(backgroundColor: Color(0xFFF0FDFA), child: Icon(Icons.local_shipping_rounded, color: Color(0xFF0F766E))),
                                title: const Text('Mai-Send (Pengiriman)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                subtitle: const Text('Kirim paket instan aman', style: TextStyle(fontSize: 12)),
                                trailing: const Icon(Icons.chevron_right, size: 20),
                                onTap: () {
                                  Get.back();
                                  orderCtrl.appliedPromo.value = code;
                                  orderCtrl.promoAmount = int.tryParse(promo['discount_amount']?.toString() ?? '0') ?? 0;
                                  orderCtrl.promoType = promo['discount_type'] ?? 'fixed';
                                  orderCtrl.applyPromoDiscount();
                                  Get.toNamed('/send');
                                },
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const CircleAvatar(backgroundColor: Color(0xFFFFF3E0), child: Icon(Icons.restaurant_rounded, color: Color(0xFFE65100))),
                                title: const Text('Mai-Food (Makanan)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                subtitle: const Text('Pesan menu resto & kuliner pilihan', style: TextStyle(fontSize: 12)),
                                trailing: const Icon(Icons.chevron_right, size: 20),
                                onTap: () {
                                  Get.back();
                                  Clipboard.setData(ClipboardData(text: code));
                                  Get.snackbar('🎉 Kupon Disalin!', 'Gunakan kode $code saat checkout makanan.', backgroundColor: AppTheme.primaryNavy, colorText: Colors.white);
                                  Get.to(() => MerchantsView());
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryNavy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Pakai', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                  ),
                ],
              ),
            );
          }),
        ],
      );
    });
  }
}
