import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme.dart';
import '../../controllers/promo_controller.dart';
import '../../controllers/order_controller.dart';

class PromoModal extends StatefulWidget {
  const PromoModal({super.key});

  @override
  State<PromoModal> createState() => _PromoModalState();
}

class _PromoModalState extends State<PromoModal> {
  final promoController = Get.put(PromoController());
  final orderController = Get.find<OrderController>();
  final TextEditingController _codeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pakai Promo / Voucher',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Get.back(),
              )
            ],
          ),
          const SizedBox(height: 16),
          // Input Manual Kode Promo
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Masukkan kode promo...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primaryBlue),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  if (_codeController.text.isNotEmpty) {
                    promoController.applyPromo(_codeController.text);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                child: const Text('Terapkan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Promo Tersedia',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              if (promoController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (promoController.promos.isEmpty) {
                return const Center(
                  child: Text('Tidak ada promo yang tersedia saat ini', style: TextStyle(color: Colors.grey)),
                );
              }

              return ListView.builder(
                itemCount: promoController.promos.length,
                itemBuilder: (context, index) {
                  var promo = promoController.promos[index];
                  bool isPercent = promo['discount_type'] == 'percent' || promo['discount_type'] == 'percentage';
                  
                  String discountLabel = isPercent 
                      ? '${promo['discount_amount']}%' 
                      : 'Rp. ${promo['discount_amount']}';
                      
                  String expiry = promo['valid_until'] ?? '';
                  if (expiry.length > 10) expiry = expiry.substring(0, 10); // Ambil YYYY-MM-DD
                  
                  bool isApplied = orderController.appliedPromo.value == promo['code'];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: isApplied ? AppTheme.primaryBlue : Colors.transparent, width: 2),
                    ),
                    elevation: 2,
                    child: InkWell(
                      onTap: () {
                        if (!isApplied) {
                          promoController.applyPromo(promo['code']);
                        } else {
                          orderController.removePromo();
                          Get.back(); // Tutup modal setelah dibatalkan
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.local_offer, color: AppTheme.primaryBlue),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    promo['code'].toString().toUpperCase(),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Diskon $discountLabel',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Berlaku: Mai-Ride, Mai-Car, Mai-Send & Mai-Titip',
                                    style: TextStyle(color: Colors.green.shade800, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Berlaku s/d $expiry',
                                    style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            if (isApplied)
                              const Icon(Icons.check_circle, color: AppTheme.primaryBlue, size: 28)
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          )
        ],
      ),
    );
  }
}
