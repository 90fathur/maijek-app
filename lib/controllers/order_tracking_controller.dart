import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math' show atan2, cos, sin, pi, asin, sqrt;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/api_client.dart';
import '../core/map_style.dart';

class OrderTrackingController extends GetxController with GetSingleTickerProviderStateMixin {
  final String orderId;
  OrderTrackingController(this.orderId);

  var status = 'pending'.obs; // pending, accepted, in_progress, completed, cancelled
  var paymentMethod = 'cash'.obs;
  var driverData = Rxn<Map<String, dynamic>>();
  var driverLocation = Rxn<LatLng>();
  
  var markers = <MarkerId, Marker>{}.obs;
  var polylines = <PolylineId, Polyline>{}.obs;
  var isAutoFollow = true.obs;
  var isNavigationPerspective = true.obs; // 3D road perspective ("kayak jalan")
  bool _isProgrammaticCameraMove = false;
  bool _hasFetchedRoute = false;

  GoogleMapController? mapController;
  Timer? _pollingTimer;

  // Koordinat statis tujuan dan jemput
  LatLng? pickupLocation;
  LatLng? dropoffLocation;

  // ETA & Smart Estimation
  var etaMinutes = 0.obs;
  var etaArrivalClock = ''.obs;
  var etaRangeText = ''.obs;
  var etaTitle = ''.obs;
  var etaSubtitle = ''.obs;
  var orderDistance = 0.0.obs;
  var serviceType = ''.obs;
  var pickupAddress = ''.obs;
  var dropoffAddress = ''.obs;
  var orderPrice = 0.0.obs;
  var discountAmount = 0.0.obs;
  var originalFare = 0.0.obs;
  var promoCode = ''.obs;

  // Animasi & Rotasi Variabel
  AnimationController? _animController;
  Animation<double>? _latTween;
  Animation<double>? _lngTween;
  LatLng? _oldDriverLocation;
  double _currentBearing = 0.0;
  BitmapDescriptor? _vehicleIcon;
  BitmapDescriptor? _carMarkerIcon;
  BitmapDescriptor? _motorcycleMarkerIcon;

  @override
  void onInit() {
    super.onInit();
    _loadMarkerIcons();
    _createVehicleIcon();
    _setupAnimation();
    _startTracking();
  }

  Future<void> _loadMarkerIcons() async {
    try {
      _carMarkerIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(devicePixelRatio: 2.5),
        'assets/images/car_marker.png',
      );
    } catch (e) {
      debugPrint('Error loading car marker icon in tracking: $e');
    }
    try {
      _motorcycleMarkerIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(devicePixelRatio: 2.5),
        'assets/images/motorcycle_marker.png',
      );
    } catch (e) {
      debugPrint('Error loading motorcycle marker icon in tracking: $e');
    }
  }

  Future<void> _createVehicleIcon() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 80;
    
    // Lingkaran dasar
    final Paint paint = Paint()..color = Colors.blue.shade700;
    canvas.drawCircle(const Offset(size/2, size/2), size/2, paint);
    
    // Border putih
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(const Offset(size/2, size/2), size/2 - 2, borderPaint);

    // Panah petunjuk arah (depan kendaraan) menghadap ke atas (0 derajat)
    final Paint arrowPaint = Paint()..color = Colors.white;
    final Path arrowPath = Path();
    arrowPath.moveTo(size/2, 10); // Ujung panah atas
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

  void _startTracking() {
    _fetchOrderData(); // Fetch immediately
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchOrderData();
    });
  }

  Future<void> _fetchOrderData() async {
    try {
      final response = await ApiClient.get('/user/orders/track/$orderId?t=${DateTime.now().millisecondsSinceEpoch}');
      if (response.statusCode == 200) {
        var body = jsonDecode(response.body);
        var order = body['data'];
        
        status.value = order['status'];
        paymentMethod.value = order['payment_method'] ?? 'cash';
        serviceType.value = order['service_type'] ?? '';
        pickupAddress.value = order['pickup_address'] ?? '';
        dropoffAddress.value = order['dropoff_address'] ?? '';
        orderPrice.value = double.tryParse(order['price']?.toString() ?? '0') ?? 0;
        discountAmount.value = double.tryParse(order['discount_amount']?.toString() ?? '0') ?? 0;
        originalFare.value = orderPrice.value + discountAmount.value;
        promoCode.value = order['promo_code']?.toString() ?? '';
        
        // Simpan titik jemput / antar dari response
        if (order['pickup_lat'] != null) {
          pickupLocation = LatLng(double.parse(order['pickup_lat'].toString()), double.parse(order['pickup_lng'].toString()));
          dropoffLocation = LatLng(double.parse(order['dropoff_lat'].toString()), double.parse(order['dropoff_lng'].toString()));
          _updateStaticMarkers();
          if (!_hasFetchedRoute) {
            _fetchRoutePolyline();
          }
        }

        if (order['driver_id'] != null) {
          driverData.value = {
            'order_id': order['id'],
            'name': order['driver_name'],
            'vehicle_plate': order['vehicle_plate'],
            'vehicle_brand': order['driver_vehicle_brand'] ?? (order['service_type'] == 'ride_car' ? 'Toyota Avanza' : ''),
            'vehicle_capacity': order['driver_vehicle_capacity'] ?? (order['service_type'] == 'ride_car' ? 4 : 1),
            'vehicle_type': order['driver_vehicle_type'] ?? order['vehicle_type'],
            'phone': order['driver_phone'],
            'driver_photo': order['driver_photo'],
            'driver_rating': order['driver_rating'],
            'unread_count': order['unread_count'],
            'driver_qris_image': order['driver_qris_image'],
            'driver_qris_image_url': order['driver_qris_image_url'],
            'driver_qris_merchant_name': order['driver_qris_merchant_name'],
            'driver_qris_is_active': order['driver_qris_is_active'],
          };
          
          if (order['driver_lat'] != null && order['driver_lng'] != null) {
            driverLocation.value = LatLng(
              double.parse(order['driver_lat'].toString()),
              double.parse(order['driver_lng'].toString())
            );
            _updateDriverMarker();
          }
        }
        
        _calculateETA(order);

        // Navigasi jika selesai
        if (status.value == 'completed') {
          _pollingTimer?.cancel();
          Get.offNamed('/rating', arguments: driverData.value);
        } else if (status.value == 'cancelled') {
          _pollingTimer?.cancel();
          Get.snackbar('Dibatalkan', 'Pesanan ini telah dibatalkan');
          Get.offAllNamed('/home');
        }
      }
    } catch (e) {
      debugPrint('Error tracking order: $e');
    }
  }

  static const String _googleApiKey = 'AIzaSyBWbn_419MiSm_i__nTTX4HIANLmkXuNw4';

  Future<void> _fetchRoutePolyline() async {
    if (pickupLocation == null || dropoffLocation == null) return;
    try {
      final url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${pickupLocation!.latitude},${pickupLocation!.longitude}&destination=${dropoffLocation!.latitude},${dropoffLocation!.longitude}&key=$_googleApiKey';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final String encodedPolyline = data['routes'][0]['overview_polyline']['points'];
          final List<LatLng> polylineCoordinates = _decodePolyline(encodedPolyline);
          _setRoutePolylines(polylineCoordinates);
          _hasFetchedRoute = true;
        }
      }
    } catch (e) {
      debugPrint('Error fetching directions polyline in tracking: $e');
    }
  }

  void _setRoutePolylines(List<LatLng> coords) {
    if (coords.isEmpty) return;

    // Dual-layer polyline untuk tampilan rute jalan modern & jelas
    polylines[const PolylineId('route_bg')] = Polyline(
      polylineId: const PolylineId('route_bg'),
      points: coords,
      color: const Color(0xFF1E3A8A),
      width: 7,
      jointType: JointType.round,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    );

    polylines[const PolylineId('route_fg')] = Polyline(
      polylineId: const PolylineId('route_fg'),
      points: coords,
      color: const Color(0xFF2563EB),
      width: 5,
      jointType: JointType.round,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    );
  }

  List<LatLng> _decodePolyline(String polyline) {
    List<LatLng> points = [];
    int index = 0, len = polyline.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  void _updateStaticMarkers() {
    if (pickupLocation != null) {
      markers[const MarkerId('pickup')] = Marker(
        markerId: const MarkerId('pickup'),
        position: pickupLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Titik Jemput'),
      );
    }
    if (dropoffLocation != null) {
      markers[const MarkerId('dropoff')] = Marker(
        markerId: const MarkerId('dropoff'),
        position: dropoffLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Titik Tujuan'),
      );
    }
  }

  void _updateDriverMarker() {
    if (driverLocation.value == null) return;
    
    final newLocation = driverLocation.value!;
    
    if (_oldDriverLocation == null) {
      _oldDriverLocation = newLocation;
      _setMarker(newLocation, _currentBearing);
      if (isAutoFollow.value) {
        _animateCameraToDriver(newLocation, isInitial: true);
      }
      return;
    }

    if (_oldDriverLocation!.latitude == newLocation.latitude && _oldDriverLocation!.longitude == newLocation.longitude) {
      return;
    }

    _currentBearing = _calculateBearing(_oldDriverLocation!, newLocation);
    
    _latTween = Tween<double>(begin: _oldDriverLocation!.latitude, end: newLocation.latitude).animate(_animController!);
    _lngTween = Tween<double>(begin: _oldDriverLocation!.longitude, end: newLocation.longitude).animate(_animController!);
    
    _animController!.reset();
    _animController!.forward();

    _oldDriverLocation = newLocation;

    if (isAutoFollow.value) {
      _animateCameraToDriver(newLocation);
    }
  }

  void _animateCameraToDriver(LatLng target, {bool isInitial = false}) {
    if (mapController == null) return;
    
    _isProgrammaticCameraMove = true;
    
    final bool isTripInProgress = status.value == 'in_progress';
    // Di status in_progress (membawa penumpang), jika mode navigasi aktif, gunakan tilt 48° dan rotasikan bearing searah arah jalan driver
    final double targetZoom = isTripInProgress ? 17.5 : (isInitial ? 16.2 : 16.8);
    final double targetTilt = (isTripInProgress && isNavigationPerspective.value) ? 48.0 : 0.0;
    final double targetBearing = (isTripInProgress && isNavigationPerspective.value && _currentBearing != 0.0)
        ? _currentBearing
        : 0.0;

    mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: targetZoom,
          tilt: targetTilt,
          bearing: targetBearing,
        ),
      ),
    ).then((_) {
      Future.delayed(const Duration(milliseconds: 350), () {
        _isProgrammaticCameraMove = false;
      });
    }).catchError((_) {
      _isProgrammaticCameraMove = false;
    });
  }

  void onUserDragMap() {
    if (!_isProgrammaticCameraMove) {
      isAutoFollow.value = false;
    }
  }

  void focusOnDriver({bool enable3d = true}) {
    isAutoFollow.value = true;
    if (enable3d && status.value == 'in_progress') {
      isNavigationPerspective.value = true;
    }
    if (driverLocation.value != null) {
      _animateCameraToDriver(driverLocation.value!);
    } else if (pickupLocation != null) {
      mapController?.animateCamera(CameraUpdate.newLatLngZoom(pickupLocation!, 16.5));
    }
  }

  void togglePerspective() {
    isNavigationPerspective.value = !isNavigationPerspective.value;
    focusOnDriver(enable3d: isNavigationPerspective.value);
  }

  void showOverview() {
    if (mapController == null) return;
    _isProgrammaticCameraMove = true;
    isAutoFollow.value = false;

    List<LatLng> points = [];
    if (driverLocation.value != null) points.add(driverLocation.value!);
    if (pickupLocation != null) points.add(pickupLocation!);
    if (dropoffLocation != null) points.add(dropoffLocation!);

    if (points.isEmpty) return;

    if (points.length == 1) {
      mapController!.animateCamera(CameraUpdate.newLatLngZoom(points.first, 15)).then((_) {
        Future.delayed(const Duration(milliseconds: 400), () => _isProgrammaticCameraMove = false);
      });
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

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 70),
    ).then((_) {
      Future.delayed(const Duration(milliseconds: 400), () => _isProgrammaticCameraMove = false);
    }).catchError((_) {
      _isProgrammaticCameraMove = false;
    });
  }

  void _setMarker(LatLng pos, double rotation) {
    final vType = (driverData.value?['vehicle_type'] ?? serviceType.value).toString().toLowerCase();
    final bool isCar = vType.contains('car') || vType.contains('mobil');

    final BitmapDescriptor iconToUse = isCar
        ? (_carMarkerIcon ?? _vehicleIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure))
        : (_motorcycleMarkerIcon ?? _vehicleIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange));

    final String driverTitle = isCar ? 'Driver MaiCar' : 'Driver MaiRide';

    markers[const MarkerId('driver')] = Marker(
      markerId: const MarkerId('driver'),
      position: pos,
      rotation: rotation,
      flat: true,
      anchor: const Offset(0.5, 0.5),
      icon: iconToUse,
      infoWindow: InfoWindow(title: driverData.value?['name'] ?? driverTitle),
    );
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
      _animateCameraToDriver(driverLocation.value!, isInitial: true);
    } else if (pickupLocation != null) {
      mapController?.animateCamera(CameraUpdate.newLatLngZoom(pickupLocation!, 16));
    }
  }

  Future<void> cancelOrder(String reason) async {
    try {
      final response = await ApiClient.post('/user/orders/cancel', {
        'order_id': orderId,
        'reason': reason
      });
      if (response.statusCode == 200) {
        _pollingTimer?.cancel();
        Get.offAllNamed('/home');
        Get.snackbar('Dibatalkan', 'Pesanan berhasil dibatalkan', backgroundColor: Colors.orange, colorText: Colors.white);
      } else {
        var body = jsonDecode(response.body);
        Get.snackbar('Gagal', body['message'] ?? 'Gagal membatalkan pesanan', backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      debugPrint('Cancel error: $e');
    }
  }

  void _calculateETA(dynamic order) {
    String st = status.value;
    String vType = (order['service_type'] ?? 'motor').toString().toLowerCase();
    bool isCar = vType.contains('car') || vType.contains('mobil');
    bool isTitip = vType.contains('titip');

    double dist = double.tryParse(order['distance']?.toString() ?? '0') ?? 0.0;
    if (dist <= 0 && pickupLocation != null && dropoffLocation != null) {
      dist = _haversineDistance(pickupLocation!, dropoffLocation!);
    }
    if (dist <= 0) dist = 2.0;
    orderDistance.value = dist;
    serviceType.value = vType;

    if (st == 'pending') {
      int baseMinutes = isCar ? (dist * 3.0 + 5).round() : (dist * 2.4 + 3).round();
      if (isTitip) baseMinutes += 12;
      if (baseMinutes < 3) baseMinutes = 3;

      int minMin = baseMinutes;
      int maxMin = (baseMinutes * 1.3).round();
      if (maxMin <= minMin) maxMin = minMin + 4;

      etaMinutes.value = baseMinutes;
      etaRangeText.value = '$minMin-$maxMin mnt';
      DateTime arrival = DateTime.now().add(Duration(minutes: (minMin + maxMin) ~/ 2));
      etaArrivalClock.value = 'Tiba ~${arrival.hour.toString().padLeft(2, '0')}:${arrival.minute.toString().padLeft(2, '0')}';
      etaTitle.value = isCar ? 'Mencari Driver MaiCar...' : 'Mencari Driver MaiRide...';
      etaSubtitle.value = 'Estimasi perjalanan: $minMin-$maxMin mnt (${etaArrivalClock.value})';
    } else if (st == 'accepted') {
      int pickupMin = 4;
      if (driverLocation.value != null && pickupLocation != null) {
        double dKm = _haversineDistance(driverLocation.value!, pickupLocation!);
        pickupMin = isCar ? (dKm / 0.4).ceil() : (dKm / 0.5).ceil();
      }
      if (pickupMin < 2) pickupMin = 2;
      if (pickupMin > 45) pickupMin = 45;

      etaMinutes.value = pickupMin;
      etaRangeText.value = '~$pickupMin mnt';
      DateTime arrival = DateTime.now().add(Duration(minutes: pickupMin));
      etaArrivalClock.value = 'Tiba ~${arrival.hour.toString().padLeft(2, '0')}:${arrival.minute.toString().padLeft(2, '0')}';
      etaTitle.value = isCar ? 'Driver MaiCar Menuju Lokasi Anda' : 'Driver MaiRide Menuju Lokasi Anda';
      etaSubtitle.value = 'Estimasi tiba di titik jemput: ~$pickupMin mnt (${etaArrivalClock.value})';
    } else if (st == 'in_progress') {
      int tripMin = isCar ? (dist * 3.0 + 5).round() : (dist * 2.4 + 3).round();
      if (driverLocation.value != null && dropoffLocation != null) {
        double dKm = _haversineDistance(driverLocation.value!, dropoffLocation!);
        tripMin = isCar ? (dKm / 0.45).ceil() : (dKm / 0.5).ceil();
      }
      if (tripMin < 2) tripMin = 2;
      if (tripMin > 60) tripMin = 60;

      etaMinutes.value = tripMin;
      etaRangeText.value = '~$tripMin mnt';
      DateTime arrival = DateTime.now().add(Duration(minutes: tripMin));
      etaArrivalClock.value = 'Tiba ~${arrival.hour.toString().padLeft(2, '0')}:${arrival.minute.toString().padLeft(2, '0')}';
      etaTitle.value = isCar ? 'Dalam Perjalanan MaiCar Menuju Tujuan' : 'Dalam Perjalanan MaiRide Menuju Tujuan';
      etaSubtitle.value = 'Estimasi sampai tujuan: ~$tripMin mnt (${etaArrivalClock.value})';
    } else {
      etaMinutes.value = 0;
      etaArrivalClock.value = '';
      etaRangeText.value = '';
      etaTitle.value = '';
      etaSubtitle.value = '';
    }
  }

  double _haversineDistance(LatLng p1, LatLng p2) {
    const double r = 6371;
    final double dLat = (p2.latitude - p1.latitude) * pi / 180;
    final double dLng = (p2.longitude - p1.longitude) * pi / 180;
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(p1.latitude * pi / 180) * cos(p2.latitude * pi / 180) *
        sin(dLng / 2) * sin(dLng / 2);
    final double c = 2 * asin(sqrt(a));
    return r * c;
  }

  @override
  void onClose() {
    _pollingTimer?.cancel();
    _animController?.dispose();
    super.onClose();
  }
}
