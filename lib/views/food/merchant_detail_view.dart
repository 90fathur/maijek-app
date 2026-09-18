import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/food_controller.dart';
import '../../core/theme.dart';
import 'checkout_view.dart';

class MerchantDetailView extends StatelessWidget {
  final FoodController controller = Get.find<FoodController>();
  final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp. ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.merchantDetail['name'] ?? 'Loading...', style: TextStyle(color: Colors.white))),
        backgroundColor: AppTheme.primaryBlue,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.merchantDetail.isEmpty) {
          return Center(child: CircularProgressIndicator());
        }

        var merchant = controller.merchantDetail;
        return Column(
          children: [
            // Merchant Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(merchant['name'] ?? '', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Expanded(child: Text(merchant['address'] ?? '', style: TextStyle(color: Colors.grey[700]))),
                    ],
                  ),
                  if (merchant['opening_time'] != null || merchant['operating_days_text'] != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${merchant['operating_days_text'] ?? 'Buka'} • ${(merchant['opening_time'] ?? '08:00').toString().length >= 5 ? (merchant['opening_time'] ?? '08:00').toString().substring(0, 5) : (merchant['opening_time'] ?? '08:00')} - ${(merchant['closing_time'] ?? '21:00').toString().length >= 5 ? (merchant['closing_time'] ?? '21:00').toString().substring(0, 5) : (merchant['closing_time'] ?? '21:00')}',
                            style: TextStyle(color: Colors.grey[700], fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 8),
            
            // Menu List
            Expanded(
              child: controller.merchantMenus.isEmpty
                  ? Center(child: Text('Tidak ada menu tersedia'))
                  : ListView.builder(
                      itemCount: controller.merchantMenus.length,
                      itemBuilder: (context, index) {
                        var menu = controller.merchantMenus[index];
                        return Card(
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: InkWell(
                            onTap: () => _showAddMenuDialog(context, menu),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  if (menu['photo'] != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(menu['photo'], width: 80, height: 80, fit: BoxFit.cover,
                                        errorBuilder: (_,__,___) => Container(width: 80, height: 80, color: Colors.grey[300], child: Icon(Icons.fastfood, color: Colors.grey))),
                                    )
                                  else
                                    Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)), child: Icon(Icons.fastfood, color: Colors.grey)),
                                  
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(menu['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                        if (menu['description'] != null)
                                          Text(menu['description'], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        const SizedBox(height: 6),
                                        Builder(builder: (context) {
                                          double orig = double.tryParse(menu['price']?.toString() ?? '0') ?? 0;
                                          double disc = double.tryParse(menu['discount_price']?.toString() ?? '0') ?? 0;
                                          bool hasDiscount = (disc > 0 && disc < orig);

                                          if (hasDiscount) {
                                            int pct = menu['discount_percent'] ?? (((orig - disc) / orig) * 100).round();
                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                      decoration: BoxDecoration(
                                                        color: Colors.redAccent,
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text('-$pct%', style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900)),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      formatter.format(orig.toInt()),
                                                      style: const TextStyle(fontSize: 11, color: Colors.grey, decoration: TextDecoration.lineThrough),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  formatter.format(disc.toInt()),
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                                                ),
                                              ],
                                            );
                                          }

                                          return Text(
                                            formatter.format(orig.toInt()),
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),                                  const SizedBox(width: 8),
                                  Obx(() {
                                    int inCart = controller.getMenuCartQuantity(menu['id']);
                                    if (inCart == 0) {
                                      return ElevatedButton(
                                        onPressed: () => _showAddMenuDialog(context, menu),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primaryBlue,
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
                                        color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppTheme.primaryBlue),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              controller.updateCartQuantityByMenuId(menu['id'], -1);
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                              child: Icon(
                                                inCart == 1 ? Icons.delete_outline : Icons.remove,
                                                size: 16,
                                                color: inCart == 1 ? Colors.red.shade600 : AppTheme.primaryBlue,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4),
                                            child: Text(
                                              '$inCart',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryBlue),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              controller.updateCartQuantityByMenuId(menu['id'], 1);
                                            },
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                              child: Icon(Icons.add, size: 16, color: AppTheme.primaryBlue),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
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
        int totalQty = controller.totalCartQuantity;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$totalQty Item (${controller.cart.length} Menu)', style: TextStyle(color: Colors.grey[600], fontSize: 12.5)),
                      Text(formatter.format(controller.cartTotal), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Get.to(() => CheckoutView()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                  ),
                  child: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                )
              ],
            ),
          ),
        );
      }),
    );
  }

  void _showAddMenuDialog(BuildContext context, Map menu) {
    int inCart = controller.getMenuCartQuantity(menu['id']);
    int quantity = inCart > 0 ? inCart : 1;
    String existingNotes = '';
    int cartIdx = controller.cart.indexWhere((item) => item['menu_id'].toString() == menu['id'].toString());
    if (cartIdx >= 0) {
      existingNotes = controller.cart[cartIdx]['notes'] ?? '';
    }
    TextEditingController notesController = TextEditingController(text: existingNotes);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            double orig = double.tryParse(menu['price']?.toString() ?? '0') ?? 0;
            double disc = double.tryParse(menu['discount_price']?.toString() ?? '0') ?? 0;
            double activePrice = (disc > 0 && disc < orig) ? disc : orig;

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(menu['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                      if (inCart > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Text('Di Keranjang: $inCart', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade900)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (disc > 0 && disc < orig)
                    Row(
                      children: [
                        Text(
                          formatter.format(disc.toInt()),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatter.format(orig.toInt()),
                          style: const TextStyle(fontSize: 13, color: Colors.grey, decoration: TextDecoration.lineThrough),
                        ),
                      ],
                    )
                  else
                    Text(formatter.format(orig.toInt()), style: const TextStyle(fontSize: 18, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Catatan (Opsional)',
                      hintText: 'Misal: Pedas, tanpa bawang',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          quantity == 1 && inCart > 0 ? Icons.delete_outline : Icons.remove_circle_outline,
                          size: 32,
                          color: quantity == 1 && inCart > 0 ? Colors.red : null,
                        ),
                        onPressed: quantity > (inCart > 0 ? 0 : 1) ? () => setState(() => quantity--) : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          quantity.toString(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: quantity == 0 ? Colors.red : Colors.black87,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 32, color: AppTheme.primaryBlue),
                        onPressed: () => setState(() => quantity++),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (inCart > 0) {
                          if (quantity <= 0) {
                            controller.removeCartItemByMenuId(menu['id']);
                          } else {
                            controller.setCartItemQuantity(menu['id'], quantity, notes: notesController.text.trim());
                          }
                        } else {
                          if (quantity > 0) {
                            controller.addToCart(menu, quantity, notesController.text.trim());
                          }
                        }
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: quantity == 0 ? Colors.red : AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        quantity == 0 
                            ? 'Hapus dari Keranjang'
                            : (inCart > 0
                                ? 'Simpan Perubahan Pesanan - ${formatter.format(activePrice.toInt() * quantity)}'
                                : 'Tambah ke Keranjang - ${formatter.format(activePrice.toInt() * quantity)}'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
