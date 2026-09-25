import 'dart:async';
import 'dart:convert';
import 'dart:math' show atan2, cos, sin, pi, asin, sqrt;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../core/api_client.dart';
import '../core/map_style.dart';
import 'auth_controller.dart';
import 'home_controller.dart';

class FoodTrackingController extends GetxController with GetSingleTickerProviderStateMixin {
  var isLoading = false.obs;
  var orderData = {}.obs;
  Timer? _timer;
  int? orderId;

  var driverLocation = Rxn<LatLng>();
  var pickupLocation = Rxn<LatLng>();
  var dropoffLocation = Rxn<LatLng>();
  
  var markers = <MarkerId, Marker>{}.obs;
  GoogleMapController? mapController;
  
  // ETA & Smart Estimation
  var etaMinutes = 0.obs;
  var etaRangeText = ''.obs;
  var etaArrivalClock = ''.obs;
  var etaStatusBadge = ''.obs;
  var prepEstimatedMinutes = 15.obs;
  var deliveryEstimatedMinutes = 10.obs;

  // Animasi
  AnimationController? _animController;
  Animation<double>? _latTween;
  Animation<double>? _lngTween;
  LatLng? _oldDriverLocation;
  double _currentBearing = 0.0;
  BitmapDescriptor? _vehicleIcon;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null) {
      if (Get.arguments['order_id'] != null) {
        orderId = int.tryParse(Get.arguments['order_id'].toString());
      } else if (Get.arguments['orderId'] != null) {
        orderId = int.tryParse(Get.arguments['orderId'].toString());
      }
    }
    _createVehicleIcon();
    _setupAnimation();
    
    fetchOrderStatus();
    // Poll every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      fetchOrderStatus();
    });
  }

  Future<void> _createVehicleIcon() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 80;
    
    // Lingkaran dasar
    final Paint paint = Paint()..color = Colors.orange.shade700;
    canvas.drawCircle(const Offset(size/2, size/2), size/2, paint);
    
    // Border putih
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(const Offset(size/2, size/2), size/2 - 2, borderPaint);

    // Panah petunjuk arah
    final Paint arrowPaint = Paint()..color = Colors.white;
    final Path arrowPath = Path();
    arrowPath.moveTo(size/2, 10);
    arrowPath.lineTo(size/2 - 15, size/2 + 5); 
    arrowPath.lineTo(size/2 + 15, size/2 + 5); 
    arrowPath.close();
    canvas.drawPath(arrowPath, arrowPaint);

    final ui.Image image = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData != null) {
      _vehicleIcon = BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
    }
  }

  void _setupAnimation() {
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _animController!.addListener(() {
      if (_latTween != null && _lngTween != null) {
        final animatedLatLng = LatLng(_latTween!.value, _lngTween!.value);
        _setMarker(animatedLatLng, _currentBearing);
      }
    });
  }

  Future<void> fetchOrderStatus() async {
    try {
      // 1. Coba ambil dari endpoint pesanan aktif terlebih dahulu (ringan, cepat, hemat bandwidth)
      String activeUrl = orderId != null ? '/user/food/active?order_id=$orderId' : '/user/food/active';
      final activeResponse = await ApiClient.get(activeUrl);
      if (activeResponse.statusCode == 200) {
        var activeData = json.decode(activeResponse.body);
        if (activeData['data'] != null) {
          var activeOrder = activeData['data'];
          if (orderId == null || activeOrder['id'].toString() == orderId.toString()) {
            orderData.value = activeOrder;
            if (Get.isRegistered<HomeController>()) {
              Get.find<HomeController>().activeFoodOrder.value = activeOrder;
            }
            _parseCoordinates(activeOrder);
            _calculateETA(activeOrder['status'] ?? 'pending');
            _checkAutoRating(activeOrder);
            return;
          }
        }
      }

      // 2. Jika tidak ada di active (misal baru saja completed atau cancelled), cek endpoint detail spesifik
      if (orderId != null) {
        final detailResponse = await ApiClient.get('/user/food/detail/$orderId');
        if (detailResponse.statusCode == 200) {
          var detailData = json.decode(detailResponse.body);
          if (detailData['data'] != null) {
            var detailOrder = detailData['data'];
            orderData.value = detailOrder;
            String st = (detailOrder['status'] ?? '').toString().toLowerCase();
            if (['completed', 'cancelled', 'delivered'].contains(st)) {
              if (Get.isRegistered<HomeController>()) {
                Get.find<HomeController>().activeFoodOrder.value = null;
              }
              if (Get.isRegistered<AuthController>()) {
                Get.find<AuthController>().fetchProfile();
              }
            } else if (Get.isRegistered<HomeController>()) {
              Get.find<HomeController>().activeFoodOrder.value = detailOrder;
            }
            _parseCoordinates(detailOrder);
            _calculateETA(detailOrder['status'] ?? 'pending');
            _checkAutoRating(detailOrder);
            return;
          }
        }
      }

      // 3. Fallback ke history jika endpoint detail belum selesai merender
      final response = await ApiClient.get('/user/food/history');
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        List orders = data['data'] ?? [];
        
        dynamic targetOrder;
        if (orderId != null) {
          targetOrder = orders.firstWhere((o) => o['id'].toString() == orderId.toString(), orElse: () => null);
        } else {
          targetOrder = orders.firstWhere((o) => ['pending', 'accepted_by_merchant', 'processing', 'ready', 'accepted', 'driver_assigned', 'driver_at_merchant', 'delivering', 'in_progress', 'completed', 'delivered', 'cancelled'].contains(o['status']), orElse: () => null);
        }

        if (targetOrder != null) {
          orderData.value = targetOrder;
          String st = (targetOrder['status'] ?? '').toString().toLowerCase();
          if (['completed', 'cancelled', 'delivered'].contains(st)) {
            if (Get.isRegistered<HomeController>()) {
              Get.find<HomeController>().activeFoodOrder.value = null;
            }
          }
          _parseCoordinates(targetOrder);
          _calculateETA(targetOrder['status'] ?? 'pending');
          _checkAutoRating(targetOrder);
        }
      }
    } catch (e) {
      debugPrint('Error fetchOrderStatus: $e');
    }
  }

  void _parseCoordinates(dynamic order) {
    bool hasStaticPoints = false;
    if (order['merchant_lat'] != null && order['merchant_lng'] != null) {
      pickupLocation.value = LatLng(double.parse(order['merchant_lat'].toString()), double.parse(order['merchant_lng'].toString()));
      hasStaticPoints = true;
    }
    if (order['delivery_lat'] != null && order['delivery_lng'] != null) {
      dropoffLocation.value = LatLng(double.parse(order['delivery_lat'].toString()), double.parse(order['delivery_lng'].toString()));
      hasStaticPoints = true;
    }
    
    if (hasStaticPoints) _updateStaticMarkers();

    if (order['driver_lat'] != null && order['driver_lng'] != null) {
      driverLocation.value = LatLng(double.parse(order['driver_lat'].toString()), double.parse(order['driver_lng'].toString()));
      _updateDriverMarker();
    }
  }

  void _updateStaticMarkers() {
    bool isMart = (orderData['order_type'] ?? '').toString().toLowerCase() == 'mart';
    if (pickupLocation.value != null) {
      markers[const MarkerId('pickup')] = Marker(
        markerId: const MarkerId('pickup'),
        position: pickupLocation.value!,
        icon: BitmapDescriptor.defaultMarkerWithHue(isMart ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(title: isMart ? 'Toko' : 'Restoran'),
      );
    }
    if (dropoffLocation.value != null) {
      markers[const MarkerId('dropoff')] = Marker(
        markerId: const MarkerId('dropoff'),
        position: dropoffLocation.value!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Lokasi Anda'),
      );
    }
  }

  void _updateDriverMarker() {
    if (driverLocation.value == null) return;
    
    final newLocation = driverLocation.value!;
    
    if (_oldDriverLocation == null) {
      _oldDriverLocation = newLocation;
      _setMarker(newLocation, _currentBearing);
      mapController?.animateCamera(CameraUpdate.newLatLng(newLocation));
      return;
    }

    if (_oldDriverLocation!.latitude == newLocation.latitude && _oldDriverLocation!.longitude == newLocation.longitude) {
      return; // Tidak ada pergerakan
    }

    _currentBearing = _calculateBearing(_oldDriverLocation!, newLocation);
    
    _latTween = Tween<double>(begin: _oldDriverLocation!.latitude, end: newLocation.latitude).animate(_animController!);
    _lngTween = Tween<double>(begin: _oldDriverLocation!.longitude, end: newLocation.longitude).animate(_animController!);
    
    _animController!.reset();
    _animController!.forward();

    _oldDriverLocation = newLocation;
    mapController?.animateCamera(CameraUpdate.newLatLng(newLocation));
  }

  void _setMarker(LatLng pos, double rotation) {
    markers[const MarkerId('driver')] = Marker(
      markerId: const MarkerId('driver'),
      position: pos,
      rotation: rotation,
      anchor: const Offset(0.5, 0.5),
      icon: _vehicleIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: const InfoWindow(title: 'Driver Maijek'),
    );
  }

  void _calculateETA(String status) {
    var order = orderData;
    double distanceKm = double.tryParse(order['distance']?.toString() ?? '0') ?? 0.0;
    if (distanceKm <= 0 && pickupLocation.value != null && dropoffLocation.value != null) {
      distanceKm = _haversineDistance(pickupLocation.value!, dropoffLocation.value!);
    }
    if (distanceKm <= 0) distanceKm = 2.0;

    String vehicleType = (order['vehicle_type'] ?? 'motor').toString().toLowerCase();
    bool isCar = vehicleType == 'mobil' || vehicleType == 'car';

    // 1. Waktu tempuh pengantaran (motor ~2.4 mnt/km + 3, mobil ~3.0 mnt/km + 5)
    int tripMinutes = isCar ? (distanceKm * 3.0 + 5).round() : (distanceKm * 2.4 + 3).round();
    if (tripMinutes < 4) tripMinutes = 4;
    deliveryEstimatedMinutes.value = tripMinutes;

    // 2. Waktu yang sudah berlalu sejak order dibuat
    int elapsedMinutes = 0;
    if (order['created_at'] != null) {
      try {
        DateTime created = DateTime.parse(order['created_at'].toString().replaceAll(' ', 'T'));
        elapsedMinutes = DateTime.now().difference(created).inMinutes;
        if (elapsedMinutes < 0) elapsedMinutes = 0;
      } catch (_) {}
    }

    // 3. Waktu penyiapan makanan di resto (standar 15-20 menit)
    int remainingPrepMinutes = 15 - elapsedMinutes;
    if (remainingPrepMinutes < 3) remainingPrepMinutes = 3;
    prepEstimatedMinutes.value = remainingPrepMinutes;

    int totalRemainingMinutes = 0;

    if (['pending', 'accepted_by_merchant', 'processing'].contains(status)) {
      totalRemainingMinutes = remainingPrepMinutes + tripMinutes;
      int minRange = (totalRemainingMinutes * 0.9).round();
      int maxRange = (totalRemainingMinutes * 1.2).round();
      if (maxRange <= minRange) maxRange = minRange + 5;
      etaRangeText.value = "$minRange-$maxRange mnt";
    } else if (status == 'ready') {
      totalRemainingMinutes = 4 + tripMinutes;
      int minRange = (totalRemainingMinutes * 0.9).round();
      int maxRange = minRange + 5;
      etaRangeText.value = "$minRange-$maxRange mnt";
    } else if (['accepted', 'driver_assigned'].contains(status)) {
      int driverToResto = 5;
      if (driverLocation.value != null && pickupLocation.value != null) {
        double dKm = _haversineDistance(driverLocation.value!, pickupLocation.value!);
        driverToResto = (dKm / 0.45).ceil();
      }
      totalRemainingMinutes = driverToResto + remainingPrepMinutes.clamp(1, 5) + tripMinutes;
      etaRangeText.value = "${(totalRemainingMinutes * 0.9).round()}-${(totalRemainingMinutes * 1.2).round()} mnt";
    } else if (status == 'driver_at_merchant') {
      totalRemainingMinutes = 3 + tripMinutes;
      etaRangeText.value = "${totalRemainingMinutes - 1}-${totalRemainingMinutes + 3} mnt";
    } else if (['delivering', 'in_progress'].contains(status)) {
      if (driverLocation.value != null && dropoffLocation.value != null) {
        double dKm = _haversineDistance(driverLocation.value!, dropoffLocation.value!);
        totalRemainingMinutes = (dKm / 0.5).ceil();
      } else {
        totalRemainingMinutes = tripMinutes;
      }
      if (totalRemainingMinutes < 2) totalRemainingMinutes = 2;
      etaRangeText.value = "$totalRemainingMinutes mnt";
    } else {
      totalRemainingMinutes = 0;
      etaRangeText.value = "";
    }

    if (totalRemainingMinutes > 0) {
      etaMinutes.value = totalRemainingMinutes;
      final arrivalTime = DateTime.now().add(Duration(minutes: totalRemainingMinutes));
      final clockStr = "${arrivalTime.hour.toString().padLeft(2, '0')}:${arrivalTime.minute.toString().padLeft(2, '0')}";
      etaArrivalClock.value = "Tiba ~$clockStr";
      etaStatusBadge.value = "⏱️ Est. Tiba ~$clockStr (${etaRangeText.value})";
    } else {
      etaMinutes.value = 0;
      etaArrivalClock.value = "";
      etaStatusBadge.value = "";
    }
  }

  double _haversineDistance(LatLng p1, LatLng p2) {
    const double r = 6371; // radius bumi dalam KM
    final double dLat = (p2.latitude - p1.latitude) * pi / 180;
    final double dLng = (p2.longitude - p1.longitude) * pi / 180;
    
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(p1.latitude * pi / 180) * cos(p2.latitude * pi / 180) *
        sin(dLng / 2) * sin(dLng / 2);
    final double c = 2 * asin(sqrt(a));
    return r * c;
  }

  double _calculateBearing(LatLng start, LatLng end) {
    final double startLat = start.latitude * pi / 180;
    final double startLng = start.longitude * pi / 180;
    final double endLat = end.latitude * pi / 180;
    final double endLng = end.longitude * pi / 180;

    final double dLng = endLng - startLng;

    final double y = sin(dLng) * cos(endLat);
    final double x = cos(startLat) * sin(endLat) - sin(startLat) * cos(endLat) * cos(dLng);
    
    final double bearing = atan2(y, x);
    return (bearing * 180 / pi + 360) % 360;
  }

  void setMapController(GoogleMapController controller) {
    mapController = controller;
    if (driverLocation.value != null) {
      mapController?.animateCamera(CameraUpdate.newLatLngZoom(driverLocation.value!, 16));
    }
  }

  void fitMapCamera() {
    if (mapController == null) return;
    List<LatLng> points = [];
    if (driverLocation.value != null) points.add(driverLocation.value!);
    if (pickupLocation.value != null) points.add(pickupLocation.value!);
    if (dropoffLocation.value != null) points.add(dropoffLocation.value!);

    if (points.isEmpty) return;

    if (points.length == 1) {
      mapController?.animateCamera(CameraUpdate.newLatLngZoom(points.first, 16));
      return;
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        80.0,
      ),
    );
  }

  bool _hasShownRating = false;
  bool _hasShownCancelled = false;

  void _checkAutoRating(dynamic order) {
    if (order['status'] == 'completed' || order['status'] == 'delivered') {
      if (!_hasShownRating) {
        _hasShownRating = true;
        _timer?.cancel();
        Future.delayed(const Duration(milliseconds: 500), () {
          showRatingDialog(order);
        });
      }
    } else if (order['status'] == 'cancelled') {
        if (!_hasShownCancelled) {
          _hasShownCancelled = true;
          _timer?.cancel();
          bool isMart = (order['order_type'] ?? '').toString().toLowerCase() == 'mart';
          Get.snackbar(
            'Pesanan Dibatalkan', 
            isMart 
                ? 'Maaf, pesanan MaiMart Anda ditolak oleh Toko atau dibatalkan sistem.'
                : 'Maaf, pesanan MaiFood Anda ditolak oleh Restoran atau dibatalkan sistem.',
            backgroundColor: Colors.red.withOpacity(0.9),
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
          Future.delayed(const Duration(seconds: 2), () {
            Get.offAllNamed('/home');
          });
        }
    }
  }

  void showRatingDialog(dynamic order) {
    bool isMart = (order['order_type'] ?? '').toString().toLowerCase() == 'mart';
    int merchantRating = 5;
    int driverRating = 5;
    final merchantReviewController = TextEditingController();
    final driverReviewController = TextEditingController();
    final tipController = TextEditingController();
    
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Beri Nilai Pesanan Anda', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Divider(height: 24),
                  
                  // Merchant Rating
                  Text('${isMart ? "Toko" : "Restoran"}: ${order['merchant_name'] ?? (isMart ? "Toko" : "Resto")}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  FittedBox(
                    child: Row(
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(index < merchantRating ? Icons.star : Icons.star_border, color: Colors.amber, size: 32),
                          onPressed: () => setState(() => merchantRating = index + 1),
                        );
                      }),
                    ),
                  ),
                  TextField(
                    controller: merchantReviewController,
                    decoration: InputDecoration(
                      hintText: isMart ? 'Komentar untuk toko (opsional)' : 'Komentar untuk restoran (opsional)',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    maxLines: 2,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Driver Rating
                  if (order['driver_name'] != null) ...[
                    Text('Driver: ${order['driver_name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    FittedBox(
                      child: Row(
                        children: List.generate(5, (index) {
                          return IconButton(
                            icon: Icon(index < driverRating ? Icons.star : Icons.star_border, color: Colors.amber, size: 32),
                            onPressed: () => setState(() => driverRating = index + 1),
                          );
                        }),
                      ),
                    ),
                    TextField(
                      controller: driverReviewController,
                      decoration: InputDecoration(
                        hintText: 'Komentar untuk driver (opsional)',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      maxLines: 2,
                    ),
                  ],

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        Get.back();
                        try {
                          await ApiClient.post('/user/food/rate', {
                            'order_id': order['id'],
                            'merchant_rating': merchantRating,
                            'driver_rating': driverRating,
                            'review_merchant': merchantReviewController.text,
                            'review_driver': driverReviewController.text,
                            'tip': tipController.text.isEmpty ? 0 : int.parse(tipController.text),
                          });
                          Get.offAllNamed('/home');
                          Get.snackbar('Berhasil', 'Terima kasih atas penilaian Anda!');
                        } catch (e) {
                           Get.offAllNamed('/home');
                        }
                      },
                      child: const Text('Kirim Penilaian', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> cancelOrder(String reason) async {
    int? targetId = orderId ?? (orderData['id'] != null ? int.tryParse(orderData['id'].toString()) : null);
    
    if (targetId == null) {
      Get.snackbar('Gagal', 'ID pesanan tidak ditemukan');
      return;
    }

    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);

    try {
      final response = await ApiClient.post('/user/food/cancel', {
        'order_id': targetId,
        'reason': reason
      });

      if (Get.isDialogOpen ?? false) Get.back();

      if (response.statusCode == 200) {
        _timer?.cancel();
        var body = json.decode(response.body);
        if (Get.isRegistered<HomeController>()) {
          Get.find<HomeController>().activeFoodOrder.value = null;
          Get.find<HomeController>().checkActiveOrder();
        }
        if (Get.isRegistered<AuthController>()) {
          Get.find<AuthController>().fetchProfile();
        }
        Get.offAllNamed('/home');
        Get.snackbar(
          'Pesanan Dibatalkan',
          body['message'] ?? 'Pesanan MaiFood Anda berhasil dibatalkan.',
          backgroundColor: Colors.orange.shade800,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      } else {
        var body = json.decode(response.body);
        Get.snackbar(
          'Gagal Membatalkan',
          body['message'] ?? 'Tidak dapat membatalkan pesanan saat ini.',
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      debugPrint('Cancel food order error: $e');
      Get.snackbar(
        'Terjadi Kesalahan',
        'Gagal membatalkan pesanan. Periksa koneksi internet.',
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    _animController?.dispose();
    super.onClose();
  }
}
