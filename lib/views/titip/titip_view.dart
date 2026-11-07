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
import 'titip_places_modal.dart';

class TitipView extends StatefulWidget {
  const TitipView({super.key});

  @override
  State<TitipView> createState() => _TitipViewState();
}

class _TitipViewState extends State<TitipView> {
  final AuthController authController = Get.find<AuthController>();
  final OrderController orderController = Get.put(OrderController());
  GoogleMapController? mapController;
  LatLng? _userCurrentLatLng;
  LatLng? _currentMapCenter;
  final ValueNotifier<bool> _isMapDragging = ValueNotifier<bool>(false);
  String _storeNameFromDb = '';
  bool _isGeocodingAddress = false;

  @override
  void initState() {
    super.initState();
    // Reset state & pastikan kendaraan jastip motor
    orderController.reset();
    orderController.currentState.value = OrderState.idle;
    orderController.selectedVehicle.value = 'mai_titip_motor';
    authController.fetchProfile(); // Refresh saldo
  }

  @override
  void dispose() {
    _isMapDragging.dispose();
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
      _userCurrentLatLng = userLatLng;
      _currentMapCenter ??= userLatLng;
      
      // Sesuai alur Mai-Titip: Lokasi Tujuan / Pengantaran otomatis difokuskan ke koordinat pemesan
      if (orderController.dropoffLocation.value.latitude == 0) {
        await orderController.setDropoff(userLatLng);
      }
      
      // Geser peta fokus langsung ke koordinat pemesan jika toko belum ditentukan
      if (mounted && orderController.pickupLocation.value.latitude == 0) {
        mapController?.animateCamera(CameraUpdate.newLatLngZoom(userLatLng, 16));
      }
    } catch (e) {
      debugPrint("Gagal mengambil lokasi GPS: $e");
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _getUserLocation();
  }

  void _fitRouteBounds() {
    if (orderController.pickupLocation.value.latitude != 0 && orderController.dropoffLocation.value.latitude != 0) {
      LatLngBounds bounds;
      if (orderController.pickupLocation.value.latitude > orderController.dropoffLocation.value.latitude) {
        bounds = LatLngBounds(southwest: orderController.dropoffLocation.value, northeast: orderController.pickupLocation.value);
      } else {
        bounds = LatLngBounds(southwest: orderController.pickupLocation.value, northeast: orderController.dropoffLocation.value);
      }
      mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    }
  }

  void _onCameraMove(CameraPosition position) {
    _currentMapCenter = position.target;
    if (!_isMapDragging.value) {
      _isMapDragging.value = true;
    }
  }

  void _onCameraIdle() async {
    if (_isMapDragging.value) {
      _isMapDragging.value = false;
    }
    if (_currentMapCenter == null) return;

    final state = orderController.currentState.value;
    if (state == OrderState.idle) {
      orderController.pickupLocation.value = _currentMapCenter!;
      // Jika tidak ada nama toko khusus dari database/modal, reverse-geocode alamatnya
      if (_storeNameFromDb.isEmpty) {
        _reverseGeocodeCenter(isPickup: true);
      }
    } else if (state == OrderState.selectingDropoff) {
      orderController.dropoffLocation.value = _currentMapCenter!;
      _reverseGeocodeCenter(isPickup: false);
    }
  }

  Future<void> _reverseGeocodeCenter({required bool isPickup}) async {
    if (_isGeocodingAddress || _currentMapCenter == null) return;
    _isGeocodingAddress = true;
    try {
      String addr = await orderController.getAddressFromLatLng(_currentMapCenter!);
      if (mounted) {
        if (isPickup) {
          orderController.pickupAddress.value = addr;
        } else {
          orderController.dropoffAddress.value = addr;
        }
      }
    } catch (e) {
      debugPrint('Reverse geocode error: $e');
    } finally {
      _isGeocodingAddress = false;
    }
  }

  void _onMapTap(LatLng location) {
    if (orderController.currentState.value == OrderState.ready) return;
    // Animasikan kamera ke titik yang diketuk agar pin tengah tepat berada di sana
    _currentMapCenter = location;
    mapController?.animateCamera(CameraUpdate.newLatLng(location));
  }

  Future<void> _openTitipPlacesModal() async {
    final result = await TitipPlacesModal.show(
      context,
      userLocation: _userCurrentLatLng ?? (orderController.dropoffLocation.value.latitude != 0
          ? orderController.dropoffLocation.value
          : null),
    );

    if (result != null && result['latLng'] != null) {
      final LatLng loc = result['latLng'];
      final String storeName = result['name'] ?? 'Toko Pilihan';
      final String fullAddr = result['fullAddress'] ?? '$storeName - ${result['address'] ?? ''}';

      _storeNameFromDb = storeName;
      _currentMapCenter = loc;
      orderController.pickupLocation.value = loc;
      orderController.pickupAddress.value = fullAddr;
      orderController.removePickupMarker(); // Hapus marker statis agar pin tengah leluasa digeser

      // Tetap di mode idle agar pengguna bisa melihat titik dan menggeser peta di halaman ini
      orderController.currentState.value = OrderState.idle;
      mapController?.animateCamera(CameraUpdate.newLatLngZoom(loc, 17));

      Get.snackbar(
        'Lokasi Toko Dipilih',
        'Titik diarahkan ke $storeName. Anda dapat menggeser peta untuk menyesuaikan titiknya.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.teal.shade800,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(12),
        borderRadius: 10,
        icon: const Icon(Icons.touch_app_rounded, color: Colors.white),
      );
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
              style: MapStyle.cleanStyle,
              initialCameraPosition: const CameraPosition(
                target: LatLng(-3.421586, 119.342158),
                zoom: 15,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: false, // Disabled to use custom FAB
              zoomControlsEnabled: false,
              onMapCreated: _onMapCreated,
              onCameraMove: _onCameraMove,
              onCameraIdle: _onCameraIdle,
              onTap: _onMapTap,
              markers: Set<Marker>.of(orderController.markers.values),
              polylines: Set<Polyline>.of(orderController.polylines.values),
            )),

          // 2. Center Marker (Floating Pin for Map Dragging)
          Obx(() {
            final state = orderController.currentState.value;
            if (state != OrderState.idle && state != OrderState.selectingDropoff) {
              return const SizedBox.shrink();
            }

            final bool isPickup = (state == OrderState.idle);
            final String title = isPickup
                ? (_storeNameFromDb.isNotEmpty ? 'Toko: $_storeNameFromDb' : 'Titik Toko / Belanja')
                : 'Titik Rumah / Pengantaran';
            final Color pinColor = isPickup ? Colors.teal.shade700 : Colors.red.shade700;
            final IconData pinIcon = isPickup ? Icons.storefront_rounded : Icons.home_rounded;

            return IgnorePointer(
              ignoring: true,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 36.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Badge Keterangan Titik
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: isPickup ? Colors.teal.shade900 : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(pinIcon, color: Colors.white, size: 14),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    title,
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            ValueListenableBuilder<bool>(
                              valueListenable: _isMapDragging,
                              builder: (context, dragging, _) {
                                return Text(
                                  dragging
                                      ? 'Lepaskan peta untuk mengunci titik'
                                      : (isPickup ? 'Geser peta ke lokasi toko yang pas' : 'Geser peta ke titik rumah Anda'),
                                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 10),
                                  textAlign: TextAlign.center,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Pin Icon dengan animasi mengangkat saat peta digeser
                      ValueListenableBuilder<bool>(
                        valueListenable: _isMapDragging,
                        builder: (context, dragging, _) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            transform: Matrix4.translationValues(0, dragging ? -12 : 0, 0),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(Icons.location_on, size: 48, color: pinColor),
                                Positioned(
                                  top: 8,
                                  child: Icon(pinIcon, size: 18, color: Colors.white),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      // Titik bayangan tanah
                      Container(
                        width: 10,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.all(Radius.elliptical(10, 5)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // 3. Floating App Bar (Back Button)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: _buildBackButton(),
          ),

          // 4. My Location FAB
          Positioned(
            top: MediaQuery.of(context).padding.top + 80, // Moved to top right to avoid overlap
            right: 16,
            child: Obx(() => orderController.currentState.value == OrderState.idle || orderController.currentState.value == OrderState.selectingDropoff
              ? FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: () async {
                    await _getUserLocation();
                    if (_userCurrentLatLng != null) {
                      _currentMapCenter = _userCurrentLatLng;
                      mapController?.animateCamera(CameraUpdate.newLatLngZoom(_userCurrentLatLng!, 17));
                    }
                  },
                  child: const Icon(Icons.my_location, color: AppTheme.primaryBlue),
                )
              : const SizedBox.shrink()
            ),
          ),

          // 5. Dynamic Bottom Sheet
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
        if (orderController.currentState.value == OrderState.ready) {
          // Dari checkout kembali ke penentuan titik antar
          orderController.removeDropoffMarker();
          orderController.currentState.value = OrderState.selectingDropoff;
          if (orderController.dropoffLocation.value.latitude != 0) {
            _currentMapCenter = orderController.dropoffLocation.value;
            mapController?.animateCamera(CameraUpdate.newLatLngZoom(orderController.dropoffLocation.value, 17));
          }
        } else if (orderController.currentState.value == OrderState.selectingDropoff) {
          // Dari titik antar kembali ke penentuan titik toko
          orderController.removePickupMarker();
          orderController.currentState.value = OrderState.idle;
          if (orderController.pickupLocation.value.latitude != 0) {
            _currentMapCenter = orderController.pickupLocation.value;
            mapController?.animateCamera(CameraUpdate.newLatLngZoom(orderController.pickupLocation.value, 17));
          }
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
    bool isPickup = orderController.currentState.value == OrderState.idle;
    
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
                isPickup ? 'Tentukan Lokasi Toko / Belanja' : 'Tentukan Alamat Pengantaran', 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
              ),
              if (orderController.currentState.value == OrderState.calculating)
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            ],
          ),
          const SizedBox(height: 16),
          
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
                // Pickup / Toko Row
                GestureDetector(
                  onTap: () async {
                    if (!isPickup) {
                      orderController.currentState.value = OrderState.idle;
                      orderController.removePickupMarker();
                      if (orderController.pickupLocation.value.latitude != 0) {
                        _currentMapCenter = orderController.pickupLocation.value;
                        mapController?.animateCamera(CameraUpdate.newLatLngZoom(orderController.pickupLocation.value, 17));
                      }
                      return;
                    }
                    var result = await Get.to(() => const LocationSearchView(), arguments: 'pickup');
                    if (result != null && result is Map) {
                      LatLng loc = result['latLng'];
                      _storeNameFromDb = '';
                      _currentMapCenter = loc;
                      orderController.pickupLocation.value = loc;
                      orderController.pickupAddress.value = result['address'] ?? 'Toko Pilihan';
                      orderController.currentState.value = OrderState.idle;
                      orderController.removePickupMarker();
                      mapController?.animateCamera(CameraUpdate.newLatLngZoom(loc, 17));
                    }
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isPickup ? Colors.teal.shade50 : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.storefront_rounded, color: isPickup ? Colors.teal.shade700 : Colors.grey, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Lokasi Toko / Pembelian', style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                            Text(
                              orderController.pickupAddress.value.isEmpty ? 'Pilih toko di peta atau cari nama toko...' : orderController.pickupAddress.value,
                              style: TextStyle(
                                fontSize: 13.5, 
                                fontWeight: isPickup ? FontWeight.bold : FontWeight.normal,
                                color: isPickup ? Colors.teal.shade900 : AppTheme.textMain,
                              ),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.stars_rounded, color: Colors.amber, size: 22),
                        tooltip: 'Pilih dari tempat populer / favorit',
                        onPressed: _openTitipPlacesModal,
                      ),
                      IconButton(
                        icon: Icon(Icons.map_outlined, color: Colors.teal.shade700, size: 20),
                        tooltip: 'Geser titik toko di peta',
                        onPressed: () {
                          orderController.currentState.value = OrderState.idle;
                          orderController.removePickupMarker();
                          LatLng target = orderController.pickupLocation.value.latitude != 0
                              ? orderController.pickupLocation.value
                              : (_userCurrentLatLng ?? const LatLng(-3.421586, 119.342158));
                          _currentMapCenter = target;
                          mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, 17));
                        },
                      ),
                    ],
                  ),
                ),
                
                // Connecting Line
                Container(
                  margin: const EdgeInsets.only(left: 15, top: 4, bottom: 4),
                  height: 18,
                  width: 2,
                  color: Colors.grey.shade300,
                  alignment: Alignment.centerLeft,
                ),
                
                // Dropoff / Rumah Row
                GestureDetector(
                  onTap: () async {
                    if (isPickup) {
                      orderController.currentState.value = OrderState.selectingDropoff;
                      orderController.removeDropoffMarker();
                      if (orderController.dropoffLocation.value.latitude != 0) {
                        _currentMapCenter = orderController.dropoffLocation.value;
                        mapController?.animateCamera(CameraUpdate.newLatLngZoom(orderController.dropoffLocation.value, 17));
                      }
                      return;
                    }
                    var result = await Get.to(() => const LocationSearchView(), arguments: 'dropoff');
                    if (result != null && result is Map) {
                      LatLng loc = result['latLng'];
                      _currentMapCenter = loc;
                      orderController.dropoffLocation.value = loc;
                      orderController.dropoffAddress.value = result['address'] ?? 'Alamat Rumah';
                      orderController.currentState.value = OrderState.selectingDropoff;
                      orderController.removeDropoffMarker();
                      mapController?.animateCamera(CameraUpdate.newLatLngZoom(loc, 17));
                    }
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: !isPickup ? Colors.red.shade50 : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.home_rounded, color: !isPickup ? Colors.red.shade700 : Colors.grey, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Alamat Pengantaran Belanja', style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                            Text(
                              orderController.dropoffAddress.value.isEmpty ? 'Mendeteksi lokasi pemesan...' : orderController.dropoffAddress.value,
                              style: TextStyle(
                                fontSize: 13.5, 
                                fontWeight: !isPickup ? FontWeight.bold : FontWeight.normal,
                                color: !isPickup ? Colors.red.shade900 : AppTheme.textMain,
                              ),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.map_outlined, color: Colors.red, size: 20),
                        tooltip: 'Geser tujuan di peta',
                        onPressed: () {
                          orderController.currentState.value = OrderState.selectingDropoff;
                          orderController.removeDropoffMarker();
                          LatLng target = orderController.dropoffLocation.value.latitude != 0 
                              ? orderController.dropoffLocation.value 
                              : (_userCurrentLatLng ?? const LatLng(-3.421586, 119.342158));
                          _currentMapCenter = target;
                          mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, 17));
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Tombol Pilih Tempat Populer / Favorit (Non-Mitra)
          if (isPickup) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: _openTitipPlacesModal,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD97706).withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.stars_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Pilih Dari Tempat Populer',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD97706),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Tikor Pas',
                                  style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Pasar, toko, apotek, dll tanpa repot cari titik koordinat',
                            style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFFB45309), size: 20),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          
          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (isPickup) {
                  // Validasi lokasi toko
                  if (orderController.pickupLocation.value.latitude == 0) {
                    if (_currentMapCenter != null) {
                      orderController.pickupLocation.value = _currentMapCenter!;
                      if (orderController.pickupAddress.value.isEmpty) {
                        orderController.pickupAddress.value = await orderController.getAddressFromLatLng(_currentMapCenter!);
                      }
                    } else {
                      Get.snackbar('Peringatan', 'Silakan tentukan titik toko belanja terlebih dahulu.',
                          snackPosition: SnackPosition.TOP, backgroundColor: Colors.orange.shade800, colorText: Colors.white);
                      return;
                    }
                  }

                  // Kunci marker toko
                  orderController.updatePickupMarker();

                  // Pindah ke pemilihan tujuan antar
                  orderController.currentState.value = OrderState.selectingDropoff;

                  // Geser peta fokus ke tujuan/pemesan
                  LatLng targetDropoff = orderController.dropoffLocation.value.latitude != 0
                      ? orderController.dropoffLocation.value
                      : (_userCurrentLatLng ?? orderController.pickupLocation.value);
                  _currentMapCenter = targetDropoff;
                  mapController?.animateCamera(CameraUpdate.newLatLngZoom(targetDropoff, 17));

                  Get.snackbar(
                    'Titik Toko Dikonfirmasi',
                    'Sekarang geser peta untuk menentukan titik rumah/pengantaran belanja.',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Colors.teal.shade800,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 3),
                    margin: const EdgeInsets.all(12),
                    borderRadius: 10,
                    icon: const Icon(Icons.home_rounded, color: Colors.white),
                  );
                } else {
                  // Validasi lokasi dropoff
                  if (orderController.dropoffLocation.value.latitude == 0) {
                    if (_currentMapCenter != null) {
                      orderController.dropoffLocation.value = _currentMapCenter!;
                      if (orderController.dropoffAddress.value.isEmpty) {
                        orderController.dropoffAddress.value = await orderController.getAddressFromLatLng(_currentMapCenter!);
                      }
                    } else {
                      Get.snackbar('Peringatan', 'Silakan tentukan alamat pengantaran belanja terlebih dahulu.',
                          snackPosition: SnackPosition.TOP, backgroundColor: Colors.orange.shade800, colorText: Colors.white);
                      return;
                    }
                  }

                  // Kunci marker dropoff
                  orderController.updateDropoffMarker();

                  // Hitung rute dan buka Price Sheet
                  await orderController.calculateRoute();
                  orderController.currentState.value = OrderState.ready;
                  _fitRouteBounds();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isPickup ? Colors.teal.shade700 : AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isPickup ? Icons.arrow_forward_rounded : Icons.check_circle_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isPickup ? 'Konfirmasi Titik Toko & Lanjut ➔' : 'Konfirmasi Titik Antar & Cek Ongkir ➔', 
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)
                  ),
                ],
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
          // Route Summary Card with "Ubah Titik"
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                // Pickup Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(color: Colors.teal.shade50, shape: BoxShape.circle),
                      child: Icon(Icons.storefront_rounded, color: Colors.teal.shade700, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Toko Belanja', style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                          Obx(() => Text(
                            orderController.pickupAddress.value.isEmpty ? 'Toko Pilihan' : orderController.pickupAddress.value,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )),
                        ],
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        orderController.removePickupMarker();
                        orderController.currentState.value = OrderState.idle;
                        _currentMapCenter = orderController.pickupLocation.value;
                        mapController?.animateCamera(CameraUpdate.newLatLngZoom(orderController.pickupLocation.value, 17));
                      },
                      child: const Text('Ubah Titik', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal)),
                    ),
                  ],
                ),
                Divider(height: 12, thickness: 0.8, color: Colors.grey.shade200),
                // Dropoff Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                      child: Icon(Icons.home_rounded, color: Colors.red.shade700, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Alamat Pengantaran', style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                          Obx(() => Text(
                            orderController.dropoffAddress.value.isEmpty ? 'Alamat Rumah' : orderController.dropoffAddress.value,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )),
                        ],
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        orderController.removeDropoffMarker();
                        orderController.currentState.value = OrderState.selectingDropoff;
                        _currentMapCenter = orderController.dropoffLocation.value;
                        mapController?.animateCamera(CameraUpdate.newLatLngZoom(orderController.dropoffLocation.value, 17));
                      },
                      child: const Text('Ubah Titik', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Text('Pilihan Kendaraan Mai-Titip', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          
          // Vehicle Options List
          SizedBox(
            height: 140,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Obx(() => _buildVehicleOption('mai_titip_motor', 'Mai-Titip Motor', Icons.two_wheeler, 'Belanjaan ringan / tas motor')),
                  Obx(() => _buildVehicleOption('mai_titip_mobil', 'Mai-Titip Mobil', Icons.directions_car, 'Belanjaan banyak / kardus / mobil')),
                ],
              ),
            ),
          ),
          
          // Formulir Jastip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.teal.shade200)
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.teal.shade800, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Driver akan membeli barang di toko memakai dana talangan. Uang belanja fisik wajib diganti TUNAI ke Driver saat pesanan tiba.',
                    style: TextStyle(color: Colors.teal.shade900, fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (val) => orderController.itemDescription.value = val,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Daftar Barang Belanjaan (Wajib)',
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              hintText: 'Contoh:\n1. Nasi Padang Ayam Bakar 1 bks\n2. Es Teh Manis 1 bks (jangan manis)',
              hintStyle: const TextStyle(fontSize: 11.5),
              prefixIcon: const Icon(Icons.shopping_bag_outlined, size: 20, color: Colors.teal),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.teal.shade700, width: 1.8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            keyboardType: TextInputType.number,
            onChanged: (val) => orderController.titipItemPrice.value = double.tryParse(val) ?? 0,
            decoration: InputDecoration(
              labelText: 'Estimasi Biaya Belanja (Wajib)',
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              prefixText: 'Rp ',
              hintText: 'Contoh: 45000',
              hintStyle: const TextStyle(fontSize: 11.5),
              prefixIcon: const Icon(Icons.account_balance_wallet_outlined, size: 20, color: Colors.teal),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.teal.shade700, width: 1.8),
              ),
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
                        '🏷️ Ada promo belanja Mai-Titip! Ketuk untuk pakai voucher.',
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
                            Obx(() {
                              final bool qActive = orderController.isQrisAvailableForService('titip');
                              if (!qActive) {
                                return ListTile(
                                  leading: const Icon(Icons.qr_code_2_rounded, color: Colors.grey),
                                  title: const Text('QRIS Instan (Pemeliharaan)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                  subtitle: Text(orderController.qrisMaintenanceMessage.value, style: const TextStyle(fontSize: 10, color: Colors.red)),
                                  onTap: () {
                                    Get.snackbar('QRIS Sedang Gangguan', orderController.qrisMaintenanceMessage.value, backgroundColor: Colors.deepOrange, colorText: Colors.white);
                                  },
                                );
                              }
                              return ListTile(
                                leading: Icon(Icons.qr_code_2_rounded, color: Colors.indigo.shade700),
                                title: const Text('QRIS Instan', style: TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: const Text('BCA, Mandiri, BRI, BNI, GoPay, OVO, Dana, dll', style: TextStyle(fontSize: 11)),
                                trailing: orderController.paymentMethod.value == 'qris' ? const Icon(Icons.check_circle, color: Colors.green) : const SizedBox(),
                                onTap: () {
                                  orderController.paymentMethod.value = 'qris';
                                  Get.back();
                                },
                              );
                            }),
                            const Divider(),
                            ListTile(
                              leading: Icon(Icons.money, color: Colors.green.shade600),
                              title: const Text('Tunai / QRIS Driver', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    final pm = orderController.paymentMethod.value;
                    final isCash = pm == 'cash';
                    final isQris = pm == 'qris';
                    final bal = double.tryParse(authController.userData['balance']?.toString() ?? '0') ?? 0;
                    final orderPrice = orderController.price.value.toDouble();
                    final isShort = pm == 'maipay' && bal < orderPrice;

                    return Row(
                      children: [
                        Icon(
                          isQris 
                              ? Icons.qr_code_2_rounded 
                              : (isCash ? Icons.money : Icons.account_balance_wallet), 
                          color: isQris 
                              ? Colors.indigo.shade700 
                              : (isCash ? Colors.green.shade600 : Colors.blue),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isQris ? 'QRIS' : (isCash ? 'Tunai/QRIS Driver' : 'Mai-Pay'), 
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
                        const Text('Tarif Resmi Belanja/Titip', style: TextStyle(fontSize: 12, color: Colors.black54)),
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
                        const Text('Total Ongkir Pelanggan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        Text('Rp. ${finalP.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '🎉 Anda hemat Rp. ${disc.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}! Selisih diskon disubsidi penuh oleh Maijek.',
                      style: TextStyle(fontSize: 10.5, color: Colors.green.shade900, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
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
              onPressed: orderController.isLoading.value ? null : () {
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
                orderController.createOrder();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: orderController.isLoading.value 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Pesan Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
                        Icon(Icons.schedule, size: 11, color: isSelected ? AppTheme.primaryBlue : Colors.purple.shade800),
                        const SizedBox(width: 3),
                        Text(
                          estDuration,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppTheme.primaryBlue : Colors.purple.shade900,
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
