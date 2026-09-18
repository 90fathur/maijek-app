import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/food_controller.dart';
import '../../core/theme.dart';
import 'merchant_detail_view.dart';
import 'checkout_view.dart';

class FoodSearchView extends StatefulWidget {
  final String? initialQuery;
  final String? initialCategory;
  const FoodSearchView({super.key, this.initialQuery, this.initialCategory});

  @override
  State<FoodSearchView> createState() => _FoodSearchViewState();
}

class _FoodSearchViewState extends State<FoodSearchView> {
  final FoodController controller = Get.isRegistered<FoodController>() ? Get.find<FoodController>() : Get.put(FoodController());
  final TextEditingController textController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  final NumberFormat formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
  Timer? _debounce;

  final List<String> categories = [
    'Semua',
    'Menu Baru',
    'Ayam & Bebek',
    'Bakso & Mie',
    'Nasi Goreng',
    'Kopi & Minuman',
    'Camilan & Snack',
    'Seafood',
  ];

  final List<String> popularKeywords = [
    'Ayam Geprek',
    'Es Teh Jumbo',
    'Kopi Susu',
    'Nasi Goreng',
    'Mie Pangsit',
    'Bakso Mercon',
    'Pisang Crispy',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null && widget.initialCategory!.isNotEmpty) {
      controller.clearSearch();
      controller.searchCategory.value = widget.initialCategory!;
      if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
        textController.text = widget.initialQuery!;
        controller.searchFood(query: widget.initialQuery!, category: widget.initialCategory!);
      } else {
        controller.searchFood(category: widget.initialCategory!);
      }
    } else if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      textController.text = widget.initialQuery!;
      controller.searchFood(query: widget.initialQuery!);
    } else {
      controller.clearSearch();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    textController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      controller.searchFood(query: val);
    });
    setState(() {});
  }

  void _goToCheckout() async {
    if (controller.currentMerchantId.value.isNotEmpty) {
      if (controller.merchantDetail.isEmpty || controller.merchantDetail['id'].toString() != controller.currentMerchantId.value) {
        await controller.fetchMerchantDetail(int.parse(controller.currentMerchantId.value));
      }
    }
    Get.to(() => CheckoutView());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textMain, size: 20),
          onPressed: () => Get.back(),
        ),
        titleSpacing: 0,
        title: Container(
          height: 42,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: textController,
            focusNode: focusNode,
            autofocus: widget.initialQuery == null || widget.initialQuery!.isEmpty,
            onChanged: _onSearchChanged,
            onSubmitted: (val) => controller.searchFood(query: val),
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Cari makanan, minuman, atau resto...',
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: AppTheme.primaryBlue, size: 20),
              suffixIcon: textController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                      onPressed: () {
                        textController.clear();
                        controller.clearSearch();
                        setState(() {});
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Kategori Chips
          _buildCategoryFilter(),

          // Hasil Pencarian atau Saran
          Expanded(
            child: Obx(() {
              if (controller.isSearching.value) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppTheme.primaryBlue),
                      SizedBox(height: 12),
                      Text('Mencari kuliner favoritmu...', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                );
              }

              bool hasQuery = controller.searchQuery.value.isNotEmpty || controller.searchCategory.value != 'Semua';

              if (!hasQuery) {
                return _buildEmptyInitialView();
              }

              if (controller.searchMenus.isEmpty && controller.searchMerchants.isEmpty) {
                return _buildNoResultsView();
              }

              return _buildSearchResults();
            }),
          ),
        ],
      ),
      bottomNavigationBar: _buildFloatingCartBottomBar(),
    );
  }

  // Floating Cart Bottom Bar (Akses Cepat ke Checkout/Pembayaran)
  Widget _buildFloatingCartBottomBar() {
    return Obx(() {
      if (controller.cart.isEmpty) return const SizedBox.shrink();

      int totalItems = 0;
      for (var item in controller.cart) {
        totalItems += (item['quantity'] as int?) ?? 0;
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -3),
            )
          ],
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shopping_bag, color: AppTheme.primaryBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$totalItems Item di Keranjang',
                          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                        ),
                        if (controller.currentMerchantName.value.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          const Text('•', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              controller.currentMerchantName.value,
                              style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatter.format(controller.cartTotal),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _goToCheckout,
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Bayar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                ),
              )
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCategoryFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        child: Obx(() {
          return Row(
            children: categories.map((cat) {
              bool isSelected = controller.searchCategory.value == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: cat == 'Menu Baru'
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome, size: 13, color: isSelected ? AppTheme.primaryBlue : Colors.deepOrange),
                            const SizedBox(width: 4),
                            Text(cat),
                          ],
                        )
                      : Text(cat),
                  selected: isSelected,
                  onSelected: (selected) {
                    controller.searchCategory.value = selected ? cat : 'Semua';
                    controller.searchFood(category: controller.searchCategory.value);
                  },
                  backgroundColor: Colors.grey.shade100,
                  selectedColor: AppTheme.primaryBlue.withValues(alpha: 0.15),
                  checkmarkColor: AppTheme.primaryBlue,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade700,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyInitialView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: const [
            Icon(Icons.trending_up, color: Colors.deepOrange, size: 20),
            SizedBox(width: 8),
            Text('Pencarian Populer di Polman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: popularKeywords.map((keyword) {
            return ActionChip(
              label: Text(keyword),
              backgroundColor: Colors.white,
              elevation: 0.5,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              onPressed: () {
                textController.text = keyword;
                controller.searchFood(query: keyword);
                focusNode.unfocus();
                setState(() {});
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Rekomendasi Resto
        if (controller.merchants.isNotEmpty) ...[
          const Text('Restoran Populer di Sekitarmu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          ...controller.merchants.take(4).map((m) => _buildMerchantCard(m)),
        ]
      ],
    );
  }

  Widget _buildNoResultsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off, size: 56, color: Colors.deepOrange),
            ),
            const SizedBox(height: 18),
            Text(
              'Kuliner "${controller.searchQuery.value}" belum ditemukan',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba gunakan kata kunci yang lebih umum seperti "Ayam", "Kopi", atau nama restoran.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Menu Makanan Cocok
        if (controller.searchMenus.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.fastfood, color: AppTheme.primaryBlue, size: 18),
              const SizedBox(width: 8),
              Text(
                'Menu Makanan (${controller.searchMenus.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...controller.searchMenus.map((menu) => _buildMenuCard(menu)),
          const SizedBox(height: 20),
        ],

        // Restoran Cocok
        if (controller.searchMerchants.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.storefront, color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              Text(
                'Restoran & Warung (${controller.searchMerchants.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...controller.searchMerchants.map((m) => _buildMerchantCard(m)),
        ],
      ],
    );
  }

  Widget _buildMenuCard(dynamic menu) {
    final double price = double.tryParse(menu['price']?.toString() ?? '0') ?? 0;
    final double discountPrice = double.tryParse(menu['discount_price']?.toString() ?? '0') ?? 0;
    final bool hasDiscount = discountPrice > 0 && discountPrice < price;
    final int discountPct = menu['discount_percent'] != null ? int.parse(menu['discount_percent'].toString()) : 0;
    final int merchantId = int.tryParse(menu['merchant_id']?.toString() ?? '0') ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showOrderModal(menu),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto Menu
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 85,
                  height: 85,
                  color: Colors.grey.shade100,
                  child: menu['photo'] != null && menu['photo'].toString().isNotEmpty
                      ? Image.network(
                          menu['photo'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.restaurant, color: Colors.grey),
                        )
                      : const Icon(Icons.restaurant, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 12),

              // Detail Menu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menu['name'] ?? 'Menu',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),

                    // Baris Nama Toko (Dapat diklik untuk melihat menu-menu toko ini)
                    GestureDetector(
                      onTap: () {
                        if (merchantId > 0) {
                          controller.fetchMerchantDetail(merchantId);
                          Get.to(() => MerchantDetailView());
                        }
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.storefront, size: 13, color: AppTheme.primaryBlue),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              menu['merchant_name'] ?? 'Restoran',
                              style: const TextStyle(fontSize: 11.5, color: AppTheme.primaryBlue, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (menu['distance'] != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              '• ${double.tryParse(menu['distance'].toString())?.toStringAsFixed(1) ?? ''} km',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Harga & Diskon
                    Row(
                      children: [
                        if (hasDiscount) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              '-$discountPct%',
                              style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            formatter.format(price),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            formatter.format(discountPrice),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ] else ...[
                          Text(
                            formatter.format(price),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Tombol Tambah Pesan / Counter
              Obx(() {
                int inCart = controller.getMenuCartQuantity(menu['id']);
                if (inCart == 0) {
                  return ElevatedButton(
                    onPressed: () => _showOrderModal(menu),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      minimumSize: const Size(64, 34),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 14),
                        SizedBox(width: 2),
                        Text('Pesan', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                } else {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            controller.updateCartQuantityByMenuId(menu['id'], -1);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                            child: Icon(
                              inCart == 1 ? Icons.delete_outline : Icons.remove,
                              size: 15,
                              color: inCart == 1 ? Colors.red.shade600 : Colors.green,
                            ),
                          ),
                        ),
                        Text(
                          '$inCart',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            controller.addToCartFromSearch(menu, quantity: 1);
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                            child: Icon(Icons.add, size: 15, color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              }),
            ],
          ),
        ),
      ),
    );
  }

  // Modal Detail Pesanan: Tambah/Kurangi di Keranjang & Langsung Bayar atau Belanja Multi di Toko yang Sama
  void _showOrderModal(dynamic menu) {
    int inCart = controller.getMenuCartQuantity(menu['id']);
    int quantity = inCart > 0 ? inCart : 1;
    String existingNotes = '';
    int cartIdx = controller.cart.indexWhere((item) => item['menu_id'].toString() == menu['id'].toString());
    if (cartIdx >= 0) {
      existingNotes = controller.cart[cartIdx]['notes'] ?? '';
    }
    final TextEditingController notesCtrl = TextEditingController(text: existingNotes);
    final double price = double.tryParse(menu['price']?.toString() ?? '0') ?? 0;
    final double discountPrice = double.tryParse(menu['discount_price']?.toString() ?? '0') ?? 0;
    final bool hasDiscount = discountPrice > 0 && discountPrice < price;
    final double finalPrice = hasDiscount ? discountPrice : price;
    final int merchantId = int.tryParse(menu['merchant_id']?.toString() ?? '0') ?? 0;
    final String merchantName = menu['merchant_name'] ?? 'Restoran';

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
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
                      Row(
                        children: [
                          const Text(
                            'Detail Pesanan',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          if (inCart > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.green.shade300),
                              ),
                              child: Text('Di Keranjang: $inCart', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade900)),
                            ),
                          ],
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Get.back(),
                      )
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Info Menu & Toko
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 70,
                          height: 70,
                          color: Colors.grey.shade100,
                          child: menu['photo'] != null && menu['photo'].toString().isNotEmpty
                              ? Image.network(menu['photo'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.restaurant))
                              : const Icon(Icons.restaurant),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              menu['name'] ?? 'Menu',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.store, size: 14, color: AppTheme.primaryBlue),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    merchantName,
                                    style: const TextStyle(fontSize: 12, color: AppTheme.primaryBlue, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              formatter.format(finalPrice),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: hasDiscount ? Colors.green : AppTheme.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Catatan Pesanan
                  TextField(
                    controller: notesCtrl,
                    decoration: InputDecoration(
                      hintText: 'Catatan (misal: pedas, tanpa es, banyakin kuah)',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Quantity Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Jumlah Pesanan:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                quantity == 1 && inCart > 0 ? Icons.delete_outline : Icons.remove,
                                size: 18,
                                color: quantity == 1 && inCart > 0 ? Colors.red : null,
                              ),
                              onPressed: quantity > (inCart > 0 ? 0 : 1)
                                  ? () => setModalState(() => quantity--)
                                  : null,
                            ),
                            Text(
                              '$quantity',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: quantity == 0 ? Colors.red : Colors.black87,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18, color: AppTheme.primaryBlue),
                              onPressed: () => setModalState(() => quantity++),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons:
                  if (quantity == 0)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          controller.removeCartItemByMenuId(menu['id']);
                          Get.back();
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Hapus dari Keranjang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                      ),
                    )
                  else ...[
                    // 1. Tambah/Simpan & Langsung Bayar (Checkout)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (inCart > 0) {
                            controller.setCartItemQuantity(menu['id'], quantity, notes: notesCtrl.text.trim());
                            Get.back();
                            _goToCheckout();
                          } else {
                            controller.addToCartFromSearch(
                              menu,
                              quantity: quantity,
                              notes: notesCtrl.text.trim(),
                              onSuccess: () {
                                Get.back();
                                _goToCheckout();
                              },
                            );
                          }
                        },
                        icon: const Icon(Icons.payment),
                        label: Text(
                          inCart > 0
                              ? 'Simpan & Checkout (${formatter.format(finalPrice * quantity)})'
                              : 'Tambah & Langsung Bayar (${formatter.format(finalPrice * quantity)})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 2. Tambah/Simpan & Lihat Menu Lain di Toko Ini (Pesan Multi-Item)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (inCart > 0) {
                            controller.setCartItemQuantity(menu['id'], quantity, notes: notesCtrl.text.trim());
                            Get.back();
                            if (merchantId > 0) {
                              controller.fetchMerchantDetail(merchantId);
                              Get.to(() => MerchantDetailView());
                            }
                          } else {
                            controller.addToCartFromSearch(
                              menu,
                              quantity: quantity,
                              notes: notesCtrl.text.trim(),
                              onSuccess: () {
                                Get.back();
                                if (merchantId > 0) {
                                  controller.fetchMerchantDetail(merchantId);
                                  Get.to(() => MerchantDetailView());
                                }
                              },
                            );
                          }
                        },
                        icon: const Icon(Icons.storefront, color: AppTheme.primaryBlue),
                        label: Text(
                          inCart > 0
                              ? 'Simpan & Pilih Menu Lain di $merchantName'
                              : 'Tambah & Pilih Menu Lain di $merchantName',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryBlue),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildMerchantCard(dynamic merchant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          int merchantId = int.tryParse(merchant['id']?.toString() ?? '0') ?? 0;
          if (merchantId > 0) {
            controller.fetchMerchantDetail(merchantId);
            Get.to(() => MerchantDetailView());
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 65,
                  height: 65,
                  color: Colors.grey.shade100,
                  child: merchant['photo'] != null && merchant['photo'].toString().isNotEmpty
                      ? Image.network(
                          merchant['photo'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.store, color: Colors.grey),
                        )
                      : const Icon(Icons.store, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      merchant['name'] ?? 'Restoran',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      merchant['top_menu'] ?? merchant['address'] ?? 'Menu Lezat Pilihan',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 13),
                        const SizedBox(width: 3),
                        Text(
                          merchant['rating']?.toString() ?? '5.0',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                        if (merchant['distance'] != null) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.location_on, color: Colors.grey, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            '${double.tryParse(merchant['distance'].toString())?.toStringAsFixed(1) ?? '1.0'} km',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
