import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import '../../core/theme.dart';
import '../../core/map_style.dart';
import '../../controllers/auth_controller.dart';
import '../promo/promo_modal.dart';
import '../../controllers/order_controller.dart';
import '../home/location_search_view.dart';
import '../wallet/topup_view.dart';
import '../wallet/insufficient_balance_sheet.dart';

class RideView extends StatefulWidget {
  final String? initialVehicle;
  const RideView({super.key, this.initialVehicle});

  @override
  State<RideView> createState() => _RideViewState();
}

class _RideViewState extends State<RideView> {
  final AuthController authController = Get.find<AuthController>();
  final OrderController orderController = Get.put(OrderController());
  late GoogleMapController mapController;

  @override
  void initState() {
    super.initState();
    if (widget.initialVehicle != null) {
      orderController.selectedVehicle.value = widget.initialVehicle!;
    }
    // Force picking state when opened
    orderController.currentState.value = OrderState.selectingPickup;
    authController.fetchProfile(); // Refresh saldo
    orderController.startPollingNearbyDrivers();
  }

  @override
  void dispose() {
    orderController.stopPollingNearbyDrivers();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      
      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
      LatLng userLatLng = LatLng(position.latitude, position.longitude);
      
      // Set default pickup ke lokasi saat ini
      orderController.setPickup(userLatLng);
      
      // Geser peta ke lokasi pengguna jika widget masih aktif
      if (mounted) {
        mapController.animateCamera(CameraUpdate.newLatLngZoom(userLatLng, 15));
      }
    } catch (e) {
      debugPrint("Gagal mengambil lokasi GPS: $e");
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    mapController.setMapStyle(MapStyle.cleanStyle);
    _getUserLocation();
  }

  void _onMapTap(LatLng location) {
    if (orderController.currentState.value == OrderState.selectingPickup) {
      orderController.setPickup(location);
      orderController.currentState.value = OrderState.selectingDropoff;
    } else if (orderController.currentState.value == OrderState.selectingDropoff) {
      orderController.setDropoff(location);
      orderController.calculateRoute();
      
      // Animate Camera to show both markers
      LatLngBounds bounds;
      if (orderController.pickupLocation.value.latitude > orderController.dropoffLocation.value.latitude) {
        bounds = LatLngBounds(southwest: orderController.dropoffLocation.value, northeast: orderController.pickupLocation.value);
      } else {
        bounds = LatLngBounds(southwest: orderController.pickupLocation.value, northeast: orderController.dropoffLocation.value);
      }
      mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Map Layer
          kIsWeb 
          ? Container(
              color: const Color(0xFFE5E9EA),
              child: const Center(child: Text('Peta Google Maps (Hanya tampil di HP asli)')),
            )
          : Obx(() => GoogleMap(
              initialCameraPosition: CameraPosition(
                target: orderController.pickupLocation.value,
                zoom: 15,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: false, // Disabled to use custom FAB
              zoomControlsEnabled: false,
              onMapCreated: _onMapCreated,
              onTap: _onMapTap,
              markers: Set<Marker>.of(orderController.markers.values),
              polylines: Set<Polyline>.of(orderController.polylines.values),
            )),

          // 2. Floating App Bar (Back Button + Service Badge)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _buildBackButton(),
                const SizedBox(width: 12),
                Obx(() {
                  final isCar = orderController.selectedVehicle.value == 'car';
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 2))],
                      border: Border.all(
                        color: isCar ? const Color(0xFF0066CC).withValues(alpha: 0.3) : AppTheme.primaryNavy.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCar ? Icons.directions_car_rounded : Icons.two_wheeler_rounded,
                          size: 18,
                          color: isCar ? const Color(0xFF0066CC) : AppTheme.primaryNavy,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isCar ? 'MaiCar (Mobil)' : 'MaiRide (Motor)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isCar ? const Color(0xFF0066CC) : AppTheme.primaryNavy,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          // 3. My Location FAB
          Positioned(
            top: MediaQuery.of(context).padding.top + 80, // Moved to top right to avoid overlap
            right: 16,
            child: Obx(() => orderController.currentState.value == OrderState.selectingPickup || orderController.currentState.value == OrderState.selectingDropoff
              ? FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _getUserLocation,
                  child: const Icon(Icons.my_location, color: AppTheme.primaryBlue),
                )
              : const SizedBox.shrink()
            ),
          ),

          // 4. Dynamic Bottom Sheet
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Obx(() {
              if (orderController.currentState.value == OrderState.ready) {
                return _buildPriceSheet();
              } else {
                return _buildInstructionSheet();
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return InkWell(
      onTap: () {
        if (orderController.currentState.value == OrderState.selectingDropoff) {
           orderController.currentState.value = OrderState.selectingPickup;
        } else if (orderController.currentState.value == OrderState.ready) {
           orderController.reset();
           orderController.currentState.value = OrderState.selectingPickup;
        } else {
           Get.back(); // Back to Dashboard
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
        child: const Icon(Icons.arrow_back, color: AppTheme.textMain),
      ),
    );
  }

  Widget _buildInstructionSheet() {
    bool isPickup = orderController.currentState.value == OrderState.selectingPickup;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isPickup ? 'Tentukan Titik Jemput' : 'Mau Pergi Ke Mana?', 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
              ),
              if (orderController.currentState.value == OrderState.calculating)
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            ],
          ),
          const SizedBox(height: 20),
          
          // Custom Location Input Field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                // Pickup Row
                GestureDetector(
                  onTap: () async {
                    var result = await Get.to(() => const LocationSearchView(), arguments: 'pickup');
                    if (result != null) {
                      orderController.pickupLocation.value = result['latLng'];
                      orderController.pickupAddress.value = result['address'];
                      orderController.currentState.value = OrderState.selectingDropoff;
                      mapController.animateCamera(CameraUpdate.newLatLngZoom(result['latLng'], 15));
                    }
                  },
                  child: Row(
                    children: [
                      Icon(Icons.trip_origin, color: isPickup ? AppTheme.primaryBlue : Colors.grey, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Dari', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                            Text(
                              orderController.pickupAddress.value.isEmpty ? 'Pilih di peta atau ketik...' : orderController.pickupAddress.value,
                              style: TextStyle(
                                fontSize: 14, 
                                fontWeight: isPickup ? FontWeight.bold : FontWeight.normal,
                                color: isPickup ? AppTheme.primaryBlue : AppTheme.textMain,
                              ),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Connecting Line
                Container(
                  margin: const EdgeInsets.only(left: 9, top: 4, bottom: 4),
                  height: 20,
                  width: 2,
                  color: Colors.grey.shade300,
                  alignment: Alignment.centerLeft,
                ),
                
                // Dropoff Row
                GestureDetector(
                  onTap: () async {
                    var result = await Get.to(() => const LocationSearchView(), arguments: 'dropoff');
                    if (result != null) {
                      orderController.dropoffLocation.value = result['latLng'];
                      orderController.dropoffAddress.value = result['address'];
                      orderController.calculateRoute();
                    }
                  },
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: !isPickup ? Colors.red : Colors.grey, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Ke', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                            Text(
                              orderController.dropoffAddress.value.isEmpty ? 'Ketik tujuan Anda...' : orderController.dropoffAddress.value,
                              style: TextStyle(
                                fontSize: 14, 
                                fontWeight: !isPickup ? FontWeight.bold : FontWeight.normal,
                                color: !isPickup ? Colors.red : AppTheme.textMain,
                              ),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (isPickup) {
                  orderController.currentState.value = OrderState.selectingDropoff;
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isPickup ? 'Konfirmasi Jemput' : 'Geser Peta Untuk Tujuan', 
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPriceSheet() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Pilih Layanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          // Vehicle Options List
          SizedBox(
            height: 155,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Obx(() => _buildVehicleOption('motor', 'Mai-Ride', Icons.two_wheeler, '1 Penumpang')),
                  Obx(() => _buildVehicleOption('car', 'Mai-Car', Icons.directions_car, '1-4 Penumpang')),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          // Notes Field
          TextField(
            onChanged: (val) => orderController.notes.value = val,
            decoration: InputDecoration(
              hintText: 'Catatan untuk driver (opsional)',
              hintStyle: const TextStyle(fontSize: 12),
              prefixIcon: const Icon(Icons.note, size: 16),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 8),

          // Banner Promo Dinamis & Promo Tersedia
          Obx(() {
            if (orderController.appliedPromo.value.isNotEmpty && orderController.appliedPromo.value != 'Tidak Ada') {
              String displayText = orderController.isDynamicPromoActive.value 
                  ? orderController.dynamicPromoText.value 
                  : '🎉 Promo ${orderController.appliedPromo.value} Diterapkan! (Diskon Ditanggung Maijek)';
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.celebration, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        displayText,
                        style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              );
            }
            return GestureDetector(
              onTap: () => Get.bottomSheet(const PromoModal(), isScrollControlled: true),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_offer_rounded, color: Colors.orange.shade800, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '🏷️ Ada promo perjalanan untuk Mai-Ride & Mai-Car! Ketuk untuk pakai.',
                        style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.orange.shade800, size: 18),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 4),
          
          // Payment Method and Promo Code
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    Get.bottomSheet(
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24))
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Pilih Metode Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 24),
                            ListTile(
                              leading: const Icon(Icons.account_balance_wallet, color: Colors.blue),
                              title: const Text('Mai-Pay', style: TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Obx(() {
                                final bal = double.tryParse(authController.userData['balance']?.toString() ?? '0') ?? 0;
                                final formatted = 'Rp. ${bal.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
                                final orderPrice = orderController.price.value.toDouble();
                                final isShort = bal < orderPrice;
                                return Text(
                                  isShort ? 'Saldo: $formatted (Kurang)' : 'Saldo: $formatted',
                                  style: TextStyle(color: isShort ? Colors.red.shade700 : Colors.grey.shade600, fontSize: 12),
                                );
                              }),
                              trailing: Obx(() {
                                final bal = double.tryParse(authController.userData['balance']?.toString() ?? '0') ?? 0;
                                final orderPrice = orderController.price.value.toDouble();
                                if (bal < orderPrice) {
                                  return ElevatedButton(
                                    onPressed: () {
                                      Get.back();
                                      int recommended = 10000;
                                      double deficit = orderPrice - bal;
                                      if (deficit > 10000) recommended = ((deficit / 10000).ceil()) * 10000;
                                      Get.to(() => TopUpView(initialAmount: recommended));
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryBlue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                      minimumSize: const Size(0, 32),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text('+ Top Up', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                  );
                                }
                                return orderController.paymentMethod.value == 'maipay' ? const Icon(Icons.check_circle, color: Colors.green) : const SizedBox();
                              }),
                              onTap: () {
                                final bal = double.tryParse(authController.userData['balance']?.toString() ?? '0') ?? 0;
                                final orderPrice = orderController.price.value.toDouble();
                                if (bal < orderPrice) {
                                  Get.back();
                                  InsufficientBalanceSheet.show(
                                    currentBalance: bal,
                                    requiredAmount: orderPrice,
                                    onPayCash: () {
                                      orderController.paymentMethod.value = 'cash';
                                    },
                                  );
                                  return;
                                }
                                orderController.paymentMethod.value = 'maipay';
                                Get.back();
                              },
                            ),
                            const Divider(),
                            ListTile(
                              leading: Icon(Icons.money, color: Colors.green.shade600),
                              title: const Text('Tunai', style: TextStyle(fontWeight: FontWeight.bold)),
                              trailing: Obx(() => orderController.paymentMethod.value == 'cash' ? const Icon(Icons.check_circle, color: Colors.green) : const SizedBox()),
                              onTap: () {
                                orderController.paymentMethod.value = 'cash';
                                Get.back();
                              },
                            ),
                          ],
                        ),
                      )
                    );
                  },
                  child: Obx(() {
                    final isCash = orderController.paymentMethod.value == 'cash';
                    final bal = double.tryParse(authController.userData['balance']?.toString() ?? '0') ?? 0;
                    final orderPrice = orderController.price.value.toDouble();
                    final isShort = !isCash && bal < orderPrice;

                    return Row(
                      children: [
                        Icon(
                          isCash ? Icons.money : Icons.account_balance_wallet, 
                          color: isCash ? Colors.green.shade600 : Colors.blue,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isCash ? 'Tunai' : 'Mai-Pay', 
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (isShort) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.orange.shade300),
                            ),
                            child: const Text(
                              'Saldo Kurang',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                            ),
                          ),
                        ],
                        const Icon(Icons.keyboard_arrow_down, size: 16),
                      ],
                    );
                  }),
                ),
                GestureDetector(
                  onTap: () {
                    Get.bottomSheet(
                      const PromoModal(),
                      isScrollControlled: true,
                    );
                  },
                  child: Row(
                    children: [
                      Obx(() => Text(
                        orderController.discount.value > 0 ? 'Diskon Aktif' : 'Pakai Promo',
                        style: TextStyle(color: orderController.discount.value > 0 ? Colors.green : AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                      )),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Rincian Promo & Total Bayar
          Obx(() {
            if (orderController.discount.value > 0) {
              final origP = orderController.originalPrice;
              final disc = orderController.discount.value;
              final finalP = orderController.price.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tarif Resmi Perjalanan', style: TextStyle(fontSize: 12, color: Colors.black54)),
                        Text('Rp. ${origP.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.local_offer, size: 13, color: Colors.green.shade800),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Diskon Promo (${orderController.appliedPromo.value})', 
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('- Rp. ${disc.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                      ],
                    ),
                    const Divider(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Pembayaran', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        Text('Rp. ${finalP.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                      ],
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: orderController.isLoading.value ? null : () => orderController.createOrder(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: orderController.isLoading.value 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    orderController.selectedVehicle.value == 'car' ? 'Pesan MaiCar Sekarang' : 'Pesan MaiRide Sekarang',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildVehicleOption(String type, String name, IconData icon, String capacityDesc) {
    bool isSelected = orderController.selectedVehicle.value == type;
    
    String formattedDistance = orderController.distanceKm.value < 1.0 
      ? '${(orderController.distanceKm.value * 1000).toInt()} m' 
      : '${orderController.distanceKm.value.toStringAsFixed(1)} KM';

    int grossPrice = orderController.calculateVehicleGrossPrice(type);
    int discountAmt = orderController.calculateVehicleDiscount(type);
    int finalPrice = orderController.calculateVehicleFinalPrice(type);
    String promoBadge = orderController.getVehiclePromoBadge(type);
    bool hasPromo = orderController.hasActivePromo && discountAmt > 0;

    String estDuration = orderController.getEstimatedDuration(type);

    return GestureDetector(
      onTap: () {
        orderController.selectedVehicle.value = type;
        orderController.calculateRoute(); // Recalculate price
        orderController.fetchNearbyDrivers(); // Refresh markers di peta sesuai jenis kendaraan
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue.withOpacity(0.05) : Colors.transparent,
          border: Border.all(color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade200, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 26, color: isSelected ? AppTheme.primaryBlue : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasPromo && promoBadge.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.green.shade300, width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.local_offer, size: 9, color: Colors.green.shade800),
                              const SizedBox(width: 2),
                              Text(
                                promoBadge,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (estDuration.isNotEmpty) ...[
                        Icon(Icons.schedule, size: 11, color: isSelected ? AppTheme.primaryBlue : Colors.orange.shade800),
                        const SizedBox(width: 3),
                        Text(
                          estDuration,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppTheme.primaryBlue : Colors.orange.shade900,
                          ),
                        ),
                        Text(' • ', style: TextStyle(color: Colors.grey.shade400, fontSize: 10.5)),
                      ],
                      Expanded(
                        child: Text(
                          '$capacityDesc • $formattedDistance',
                          style: TextStyle(fontSize: 11, color: isSelected ? AppTheme.primaryBlue.withOpacity(0.85) : Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasPromo)
                  Text(
                    'Rp. ${grossPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                    style: TextStyle(
                      fontSize: 11,
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                Text(
                  'Rp. ${finalPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: hasPromo ? Colors.green.shade700 : (isSelected ? AppTheme.primaryBlue : AppTheme.textMain),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
