import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../core/api_client.dart';
import 'auth_controller.dart';
import '../views/wallet/insufficient_balance_sheet.dart';
import 'dart:math' show atan2, cos, sin, pi;
import 'package:flutter/material.dart';

enum OrderState { idle, selectingPickup, selectingDropoff, calculating, ready }

class OrderController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();

  var currentState = OrderState.idle.obs;
  var pickupLocation = const LatLng(-3.421586, 119.342158).obs;
  var dropoffLocation = const LatLng(0, 0).obs;
  var pickupAddress = ''.obs;
  var dropoffAddress = ''.obs;
  var polylines = <PolylineId, Polyline>{}.obs;
  var markers = <MarkerId, Marker>{}.obs;
  var distanceKm = 0.0.obs;
  var durationText = "".obs;
  var price = 0.obs;
  var isLoading = false.obs;
  var notes = ''.obs;
  var selectedVehicle = 'motor'.obs;
  var paymentMethod = 'cash'.obs; // 'cash' or 'maipay'
  
  // Promo
  var appliedPromo = ''.obs;
  var discount = 0.obs;
  int promoAmount = 0;
  String promoType = 'fixed'; // 'fixed' or 'percentage'

  int get originalPrice => price.value + discount.value;
  bool get hasActivePromo => appliedPromo.value.isNotEmpty && appliedPromo.value != 'Tidak Ada' && promoAmount > 0;

  int calculateVehicleGrossPrice(String type) {
    double base = baseFare.value.toDouble();
    double pkm = perKmFare.value.toDouble();
    double bDist = baseDistance.value;

    if (type == 'car') {
      base = rideMobilBaseFare.value.toDouble();
      pkm = rideMobilPerKmFare.value.toDouble();
      bDist = rideMobilBaseDistance.value;
    } else if (type == 'mai_send_motor') {
      base = sendMotorBaseFare.value.toDouble();
      pkm = sendMotorPerKm.value.toDouble();
      bDist = sendMotorBaseDistance.value;
    } else if (type == 'mai_send_mobil') {
      base = sendMobilBaseFare.value.toDouble();
      pkm = sendMobilPerKm.value.toDouble();
      bDist = sendMobilBaseDistance.value;
    } else if (type == 'mai_titip_motor') {
      base = titipMotorBaseFare.value.toDouble();
      pkm = titipMotorPerKm.value.toDouble();
      bDist = titipMotorBaseDistance.value;
    } else if (type == 'mai_titip_mobil') {
      base = titipMobilBaseFare.value.toDouble();
      pkm = titipMobilPerKm.value.toDouble();
      bDist = titipMobilBaseDistance.value;
    }

    if (distanceKm.value <= bDist) {
      return base.round();
    } else {
      double extra = distanceKm.value - bDist;
      return (base + (extra * pkm)).round();
    }
  }

  int calculateVehicleDiscount(String type) {
    if (!hasActivePromo) return 0;
    int gross = calculateVehicleGrossPrice(type);
    if (promoType == 'percent' || promoType == 'percentage') {
      return (gross * (promoAmount / 100.0)).round();
    } else {
      return promoAmount > gross ? gross : promoAmount;
    }
  }

  int calculateVehicleFinalPrice(String type) {
    int gross = calculateVehicleGrossPrice(type);
    int disc = calculateVehicleDiscount(type);
    int finalP = gross - disc;
    return finalP < 0 ? 0 : finalP;
  }

  String getVehiclePromoBadge(String type) {
    if (!hasActivePromo) return '';
    if (promoType == 'percent' || promoType == 'percentage') {
      return 'DISKON $promoAmount%';
    } else {
      int disc = calculateVehicleDiscount(type);
      if (disc >= 1000) {
        if (disc % 1000 == 0) {
          return 'HEMAT Rp ${(disc ~/ 1000)}RB';
        } else {
          return 'HEMAT Rp ${(disc / 1000.0).toStringAsFixed(1)}RB';
        }
      }
      return 'HEMAT Rp $disc';
    }
  }

  // Variabel Tarif dari Backend (sementara, kita modifikasi agar mendukung tipe kendaraan)
  var baseFare = 12000.obs;
  var baseDistance = 3.0.obs;
  var perKmFare = 3000.obs;

  // Mai-Ride Mobil Tarif
  var rideMobilBaseFare = 15000.obs;
  var rideMobilBaseDistance = 3.0.obs;
  var rideMobilPerKmFare = 4000.obs;

  var foodBaseFare = 5000.obs;
  var foodPerKmFare = 2000.obs;
  
  // Mai-Send & Mai-Titip Tarif
  var sendMotorBaseFare = 8000.obs;
  var sendMotorBaseDistance = 3.0.obs;
  var sendMotorPerKm = 2000.obs;
  
  var sendMobilBaseFare = 20000.obs;
  var sendMobilBaseDistance = 3.0.obs;
  var sendMobilPerKm = 4000.obs;
  
  var titipMotorBaseFare = 10000.obs;
  var titipMotorBaseDistance = 3.0.obs;
  var titipMotorPerKm = 2000.obs;
  
  var titipMobilBaseFare = 25000.obs;
  var titipMobilBaseDistance = 3.0.obs;
  var titipMobilPerKm = 5000.obs;

  // Mai-Send & Mai-Titip Form Data
  var recipientName = ''.obs;
  var recipientPhone = ''.obs;
  var itemDescription = ''.obs;
  var itemWeight = 'Sedang'.obs;
  var titipItemPrice = 0.0.obs;

  final String googleApiKey = 'AIzaSyBWbn_419MiSm_i__nTTX4HIANLmkXuNw4';
  
  BitmapDescriptor? motorcycleIcon;
  BitmapDescriptor? carIcon;
  Timer? _nearbyTimer;
  var nearbyDrivers = <dynamic>[].obs;

  /// Mendapatkan estimasi durasi cerdas (contoh: "12 mnt" atau "15 mnt")
  String getEstimatedDuration(String vehicleType) {
    if (distanceKm.value <= 0) return '';
    
    int baseMinutes = 0;
    if (durationText.value.isNotEmpty) {
      final match = RegExp(r'(\d+)').firstMatch(durationText.value);
      if (match != null) {
        baseMinutes = int.tryParse(match.group(1) ?? '0') ?? 0;
      }
    }
    
    // Fallback jika Directions API belum mengembalikan durasi:
    if (baseMinutes <= 0) {
      if (vehicleType == 'car' || vehicleType == 'mai_send_mobil' || vehicleType == 'mai_titip_mobil') {
        baseMinutes = (distanceKm.value * 3.0 + 5).round();
      } else {
        baseMinutes = (distanceKm.value * 2.4 + 3).round();
      }
    } else {
      if (vehicleType != 'car' && vehicleType != 'mai_send_mobil' && vehicleType != 'mai_titip_mobil') {
        baseMinutes = (baseMinutes * 0.85).round();
      }
    }
    
    if (vehicleType.contains('titip')) {
      baseMinutes += 12;
    }
    
    if (baseMinutes < 3) baseMinutes = 3;
    return '$baseMinutes mnt';
  }

  /// Mendapatkan rentang estimasi tiba cerdas (contoh: "10-15 mnt (Tiba ~14:35)")
  String getEstimatedArrivalRange(String vehicleType) {
    if (distanceKm.value <= 0) return '';
    
    int baseMinutes = 0;
    if (durationText.value.isNotEmpty) {
      final match = RegExp(r'(\d+)').firstMatch(durationText.value);
      if (match != null) {
        baseMinutes = int.tryParse(match.group(1) ?? '0') ?? 0;
      }
    }
    
    if (baseMinutes <= 0) {
      if (vehicleType == 'car' || vehicleType == 'mai_send_mobil' || vehicleType == 'mai_titip_mobil') {
        baseMinutes = (distanceKm.value * 3.0 + 5).round();
      } else {
        baseMinutes = (distanceKm.value * 2.4 + 3).round();
      }
    } else {
      if (vehicleType != 'car' && vehicleType != 'mai_send_mobil' && vehicleType != 'mai_titip_mobil') {
        baseMinutes = (baseMinutes * 0.85).round();
      }
    }

    int minMinutes = baseMinutes;
    int maxMinutes = (baseMinutes * 1.3).round();

    if (vehicleType.contains('titip')) {
      minMinutes += 10;
      maxMinutes = minMinutes + 12;
    }

    if (minMinutes < 3) minMinutes = 3;
    if (maxMinutes <= minMinutes) maxMinutes = minMinutes + 4;

    final now = DateTime.now();
    final arrivalTime = now.add(Duration(minutes: (minMinutes + maxMinutes) ~/ 2));
    final formattedTime = "${arrivalTime.hour.toString().padLeft(2, '0')}:${arrivalTime.minute.toString().padLeft(2, '0')}";

    return "$minMinutes-$maxMinutes mnt (Tiba ~$formattedTime)";
  }

  String get currentEstimatedArrival => getEstimatedArrivalRange(selectedVehicle.value);
  String get currentEstimatedDuration => getEstimatedDuration(selectedVehicle.value);

  @override
  void onInit() {
    super.onInit();
    _loadMotorcycleIcon();
    _loadCarIcon();
    fetchSettings();
    fetchDynamicPromo();
    _checkActiveOrder();
  }

  Future<void> _loadMotorcycleIcon() async {
    try {
      motorcycleIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(devicePixelRatio: 2.5),
        'assets/images/motorcycle_marker.png',
      );
    } catch(e) {
      debugPrint('Error loading motorcycle icon: $e');
    }
  }

  Future<void> _loadCarIcon() async {
    try {
      carIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(devicePixelRatio: 2.5),
        'assets/images/car_marker.png',
      );
    } catch(e) {
      debugPrint('Error loading car icon: $e');
    }
  }

  void startPollingNearbyDrivers() {
    _nearbyTimer?.cancel();
    fetchNearbyDrivers();
    _nearbyTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      // Hanya polling jika sedang milih pickup/awal
      if (currentState.value == OrderState.calculating || currentState.value == OrderState.ready) return;
      fetchNearbyDrivers();
    });
  }

  void stopPollingNearbyDrivers() {
    _nearbyTimer?.cancel();
    markers.removeWhere((key, value) => key.value.startsWith('driver_'));
  }

  Future<void> fetchNearbyDrivers() async {
    try {
      final lat = pickupLocation.value.latitude;
      final lng = pickupLocation.value.longitude;
      if (lat == 0 || lng == 0) return;

      final bool wantCar = selectedVehicle.value == 'car' || selectedVehicle.value == 'mai_send_mobil' || selectedVehicle.value == 'mai_titip_mobil';
      final vTypeParam = wantCar ? 'mobil' : 'motor';

      final res = await ApiClient.get('/user/drivers/nearby?lat=$lat&lng=$lng&vehicle_type=$vTypeParam');
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        nearbyDrivers.value = body['data'] ?? [];
        _updateDriverMarkers();
      }
    } catch(e) {
      debugPrint("Gagal load nearby drivers: $e");
    }
  }

  void _updateDriverMarkers() {
    var newMarkers = <MarkerId, Marker>{};
    
    // Pertahankan marker non-driver (pickup / dropoff)
    markers.forEach((key, value) {
      if (!key.value.startsWith('driver_')) {
        newMarkers[key] = value;
      }
    });

    final bool wantCar = selectedVehicle.value == 'car' || selectedVehicle.value == 'mai_send_mobil' || selectedVehicle.value == 'mai_titip_mobil';
    final bool wantMotor = selectedVehicle.value == 'motor' || selectedVehicle.value == 'mai_send_motor' || selectedVehicle.value == 'mai_titip_motor';

    for (var d in nearbyDrivers) {
      final markerId = MarkerId('driver_${d['id']}');
      final lat = double.tryParse(d['latitude'].toString()) ?? 0.0;
      final lng = double.tryParse(d['longitude'].toString()) ?? 0.0;
      
      if (lat != 0.0 && lng != 0.0) {
        // Tentukan apakah kendaraan mobil atau motor
        final vType = (d['vehicle_type'] ?? '').toString().toLowerCase();
        final bool isCar = vType == 'mobil' || vType == 'car' || vType == 'car_premium';

        // Filter kendaraan agar sesuai dengan pilihan kendaraan pelanggan
        if (wantCar && !isCar) continue;
        if (wantMotor && isCar) continue;

        final newPosition = LatLng(lat, lng);
        double rotation = 0.0;
        
        // Cek posisi sebelumnya untuk hitung rotasi
        if (markers.containsKey(markerId)) {
          final oldPosition = markers[markerId]!.position;
          rotation = _calculateBearing(oldPosition, newPosition);
          
          // Jika posisinya sama persis, gunakan rotasi sebelumnya agar tidak reset
          if (oldPosition.latitude == newPosition.latitude && oldPosition.longitude == newPosition.longitude) {
            rotation = markers[markerId]!.rotation;
          }
        }

        final BitmapDescriptor iconToUse = isCar
            ? (carIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure))
            : (motorcycleIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange));

        newMarkers[markerId] = Marker(
          markerId: markerId,
          position: newPosition,
          rotation: rotation,
          flat: true,
          icon: iconToUse,
          infoWindow: InfoWindow(title: d['name']),
          anchor: const Offset(0.5, 0.5), // Center icon
        );
      }
    }
    
    markers.value = newMarkers;
  }

  double _calculateBearing(LatLng start, LatLng end) {
    var lat1 = start.latitude * pi / 180;
    var lng1 = start.longitude * pi / 180;
    var lat2 = end.latitude * pi / 180;
    var lng2 = end.longitude * pi / 180;

    var dLng = lng2 - lng1;

    var y = sin(dLng) * cos(lat2);
    var x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);
    var brng = atan2(y, x);

    brng = brng * 180 / pi;
    brng = (brng + 360) % 360;
    return brng;
  }

  Future<void> _checkActiveOrder() async {
    try {
      final response = await ApiClient.get('/user/orders/active');
      if (response.statusCode == 200) {
        var body = jsonDecode(response.body);
        if (body['data'] != null) {
          // Ada pesanan aktif, arahkan ke layar pelacakan
          String orderId = body['data']['id'].toString();
          Get.toNamed('/order-tracking', arguments: {'order_id': orderId});
          return;
        }
      }

      final foodResponse = await ApiClient.get('/user/food/active');
      if (foodResponse.statusCode == 200) {
        var data = jsonDecode(foodResponse.body);
        if (data['data'] != null) {
          Get.toNamed('/food/tracking', arguments: {'order_id': data['data']['id'].toString()});
        }
      }
    } catch (e) {
      debugPrint('Error checking active orders: $e');
    }
  }

  Future<void> fetchSettings() async {
    try {
      final response = await ApiClient.get('/settings');
      if (response.statusCode == 200) {
        var body = jsonDecode(response.body);
        if (body['data'] != null) {
          baseFare.value = body['data']['base_fare'] ?? 12000;
          baseDistance.value = (body['data']['base_fare_distance'] ?? 3.0).toDouble();
          perKmFare.value = body['data']['per_km_fare'] ?? 3000;
          
          rideMobilBaseFare.value = body['data']['ride_mobil_base_fare'] ?? 15000;
          rideMobilBaseDistance.value = (body['data']['ride_mobil_base_fare_distance'] ?? 3.0).toDouble();
          rideMobilPerKmFare.value = body['data']['ride_mobil_per_km_fare'] ?? 4000;
          foodBaseFare.value = body['data']['food_base_fare'] ?? 5000;
          foodPerKmFare.value = body['data']['food_per_km_fare'] ?? 2000;
          
          sendMotorBaseFare.value = int.tryParse(body['data']['send_motor_base_fare'].toString()) ?? 8000;
          sendMotorBaseDistance.value = (body['data']['send_motor_base_distance'] ?? 3.0).toDouble();
          sendMotorPerKm.value = int.tryParse(body['data']['send_motor_per_km'].toString()) ?? 2000;
          
          sendMobilBaseFare.value = int.tryParse(body['data']['send_mobil_base_fare'].toString()) ?? 20000;
          sendMobilBaseDistance.value = (body['data']['send_mobil_base_distance'] ?? 3.0).toDouble();
          sendMobilPerKm.value = int.tryParse(body['data']['send_mobil_per_km'].toString()) ?? 4000;
          
          titipMotorBaseFare.value = int.tryParse(body['data']['titip_motor_base_fare'].toString()) ?? 10000;
          titipMotorBaseDistance.value = (body['data']['titip_motor_base_distance'] ?? 3.0).toDouble();
          titipMotorPerKm.value = int.tryParse(body['data']['titip_motor_per_km'].toString()) ?? 2000;
          
          titipMobilBaseFare.value = int.tryParse(body['data']['titip_mobil_base_fare'].toString()) ?? 25000;
          titipMobilBaseDistance.value = (body['data']['titip_mobil_base_distance'] ?? 3.0).toDouble();
          titipMobilPerKm.value = int.tryParse(body['data']['titip_mobil_per_km'].toString()) ?? 5000;
        }
      }
    } catch (e) {
      debugPrint('Gagal memuat pengaturan tarif: $e');
    }
  }

  var isDynamicPromoActive = false.obs;
  var dynamicPromoText = ''.obs;

  Future<void> fetchDynamicPromo() async {
    try {
      final response = await ApiClient.get('/user/promos/dynamic');
      if (response.statusCode == 200) {
        var body = jsonDecode(response.body);
        if (body['data'] != null && body['data']['active'] == true) {
          isDynamicPromoActive.value = true;
          
          promoType = body['data']['type'];
          promoAmount = int.tryParse(body['data']['amount'].toString()) ?? 0;
          appliedPromo.value = (body['data']['code'] ?? 'Promo Otomatis').toString();
          
          String diskonText = promoType == 'percent' 
              ? '$promoAmount%' 
              : 'Rp ${promoAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
          dynamicPromoText.value = '🎉 Promo ${appliedPromo.value} Diterapkan: Diskon $diskonText (Ditanggung Maijek)';
          
          // Recalculate route to apply discount if locations are set
          if (pickupLocation.value.latitude != 0 && dropoffLocation.value.latitude != 0) {
            calculateRoute();
          }
        } else {
          isDynamicPromoActive.value = false;
        }
      }
    } catch (e) {
      debugPrint('Error fetching dynamic promo: $e');
    }
  }

  void applyPromoDiscount() {
    if (appliedPromo.value == 'Tidak Ada') return;
    
    // Recalculate everything, which will automatically apply promo rules in calculateRoute()
    if (pickupLocation.value.latitude != 0 && dropoffLocation.value.latitude != 0) {
      calculateRoute();
    }
  }

  void removePromo() {
    appliedPromo.value = 'Tidak Ada';
    promoAmount = 0;
    promoType = 'fixed';
    discount.value = 0;
    
    if (pickupLocation.value.latitude != 0 && dropoffLocation.value.latitude != 0) {
      calculateRoute();
    }
  }

  Future<void> setPickup(LatLng loc) async {
    pickupLocation.value = loc;
    pickupAddress.value = 'Mencari alamat...';
    _updateMarker('pickup', loc, 'Penjemputan', BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue));
    
    String address = await _getAddressFromLatLng(loc);
    pickupAddress.value = address;
  }

  Future<void> setDropoff(LatLng loc) async {
    dropoffLocation.value = loc;
    dropoffAddress.value = 'Mencari alamat...';
    _updateMarker('dropoff', loc, 'Tujuan', BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed));
    
    String address = await _getAddressFromLatLng(loc);
    dropoffAddress.value = address;
  }

  Future<String> _getAddressFromLatLng(LatLng loc) async {
    try {
      String url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=${loc.latitude},${loc.longitude}&key=$googleApiKey';
      var response = await http.get(Uri.parse(url));
      var data = jsonDecode(response.body);

      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
        return data['results'][0]['formatted_address'];
      }
    } catch (e) {
      debugPrint('Geocoding Error: $e');
    }
    return 'Titik di Peta yang Dipilih';
  }

  // --- PLACES API FOR SEARCHING ---
  Future<List<dynamic>> searchPlaces(String query, {LatLng? currentLocation}) async {
    if (query.isEmpty) return [];
    try {
      String locationParam = '';
      if (currentLocation != null) {
        // Bias pencarian radius 50km dari lokasi saat ini
        locationParam = '&location=${currentLocation.latitude},${currentLocation.longitude}&radius=50000';
      }
      String url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$googleApiKey&components=country:id$locationParam';
      var response = await http.get(Uri.parse(url));
      var data = jsonDecode(response.body);

      if (data['status'] == 'OK') {
        return data['predictions'];
      } else {
        debugPrint('Places API Error: ${data['error_message']} - Status: ${data['status']}');
      }
    } catch (e) {
      debugPrint('Places Search Exception: $e');
    }
    return [];
  }

  Future<LatLng?> getPlaceDetails(String placeId) async {
    try {
      String url = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$googleApiKey';
      var response = await http.get(Uri.parse(url));
      var data = jsonDecode(response.body);

      if (data['status'] == 'OK') {
        var loc = data['result']['geometry']['location'];
        return LatLng(loc['lat'], loc['lng']);
      }
    } catch (e) {
      debugPrint('Place Details Error: $e');
    }
    return null;
  }

  void _updateMarker(String id, LatLng loc, String title, BitmapDescriptor icon) {
    markers[MarkerId(id)] = Marker(
      markerId: MarkerId(id),
      position: loc,
      infoWindow: InfoWindow(title: title),
      icon: icon,
    );
  }

  Future<void> calculateRoute() async {
    currentState.value = OrderState.calculating;
    
    try {
      String url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${pickupLocation.value.latitude},${pickupLocation.value.longitude}&destination=${dropoffLocation.value.latitude},${dropoffLocation.value.longitude}&key=$googleApiKey';
      var response = await http.get(Uri.parse(url));
      var data = jsonDecode(response.body);

      if (data['status'] == 'OK') {
        String encodedPolyline = data['routes'][0]['overview_polyline']['points'];
        int distanceMeters = data['routes'][0]['legs'][0]['distance']['value'];
        String durationStr = data['routes'][0]['legs'][0]['duration']['text'];
        
        // Terjemahkan "mins" ke "mnt" agar lebih Indonesia
        durationText.value = durationStr.replaceAll('mins', 'mnt').replaceAll('min', 'mnt').replaceAll('hours', 'jam').replaceAll('hour', 'jam');

        List<LatLng> polylineCoordinates = _decodePolyline(encodedPolyline);

        _addPolyLine(polylineCoordinates);
        
        distanceKm.value = distanceMeters / 1000.0;
        if (distanceKm.value < 0.1) distanceKm.value = 0.1; 
        
        // --- LOGIKA TARIF DINAMIS BERDASARKAN KENDARAAN ---
        double baseCost = baseFare.value.toDouble();
        double kmCost = perKmFare.value.toDouble();
        double usedBaseDistance = baseDistance.value;

        if (selectedVehicle.value == 'car') {
           baseCost = rideMobilBaseFare.value.toDouble();
           kmCost = rideMobilPerKmFare.value.toDouble();
           usedBaseDistance = rideMobilBaseDistance.value;
        } else if (selectedVehicle.value == 'mai_send_motor') {
           baseCost = sendMotorBaseFare.value.toDouble();
           kmCost = sendMotorPerKm.value.toDouble();
           usedBaseDistance = sendMotorBaseDistance.value;
        } else if (selectedVehicle.value == 'mai_send_mobil') {
           baseCost = sendMobilBaseFare.value.toDouble();
           kmCost = sendMobilPerKm.value.toDouble();
           usedBaseDistance = sendMobilBaseDistance.value;
        } else if (selectedVehicle.value == 'mai_titip_motor') {
           baseCost = titipMotorBaseFare.value.toDouble();
           kmCost = titipMotorPerKm.value.toDouble();
           usedBaseDistance = titipMotorBaseDistance.value;
        } else if (selectedVehicle.value == 'mai_titip_mobil') {
           baseCost = titipMobilBaseFare.value.toDouble();
           kmCost = titipMobilPerKm.value.toDouble();
           usedBaseDistance = titipMobilBaseDistance.value;
        }

        if (distanceKm.value <= usedBaseDistance) {
          price.value = baseCost.round();
        } else {
          double extraDistance = distanceKm.value - usedBaseDistance;
          double extraCost = extraDistance * kmCost;
          price.value = (baseCost + extraCost).round();
        }

        // Apply discount if any
        if (appliedPromo.value.isNotEmpty && appliedPromo.value != 'Tidak Ada' && promoAmount > 0) {
          if (promoType == 'percent' || promoType == 'percentage') {
            discount.value = (price.value * (promoAmount / 100.0)).round();
          } else {
            discount.value = promoAmount;
          }
        } else {
          discount.value = 0;
        }

        if (discount.value > 0) {
          price.value -= discount.value;
          if (price.value < 0) price.value = 0;
        }

        currentState.value = OrderState.ready;
      } else {
        Get.snackbar('Error Rute', data['error_message'] ?? 'Tidak dapat menemukan rute jalan.');
        currentState.value = OrderState.selectingDropoff;
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal memanggil API rute Google.');
      currentState.value = OrderState.selectingDropoff;
    }
  }

  void _addPolyLine(List<LatLng> polylineCoordinates) {
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.blue,
      points: polylineCoordinates,
      width: 5,
    );
    polylines[id] = polyline;
  }

  Future<void> createOrder() async {
    // Cek saldo jika menggunakan Mai-Pay
    if (paymentMethod.value == 'maipay') {
      double currentBalance = double.tryParse(_authController.userData['balance']?.toString() ?? '0') ?? 0;
      double orderPrice = price.value.toDouble();
      if (currentBalance < orderPrice) {
        InsufficientBalanceSheet.show(
          currentBalance: currentBalance,
          requiredAmount: orderPrice,
          onPayCash: () {
            paymentMethod.value = 'cash';
            createOrder();
          },
        );
        return;
      }
    }

    isLoading.value = true;
    try {
      final rawResponse = await ApiClient.post('/user/orders/create', {
        'user_id': _authController.userData['id'] ?? 1,
        'pickup_address': pickupAddress.value.isEmpty ? 'Lokasi Jemput' : pickupAddress.value,
        'pickup_lat': pickupLocation.value.latitude,
        'pickup_lng': pickupLocation.value.longitude,
        'dropoff_address': dropoffAddress.value.isEmpty ? 'Lokasi Tujuan' : dropoffAddress.value,
        'dropoff_lat': dropoffLocation.value.latitude,
        'dropoff_lng': dropoffLocation.value.longitude,
        'service_type': selectedVehicle.value,
        'notes': notes.value,
        'distance': distanceKm.value,
        'price': price.value,
        'payment_method': paymentMethod.value,
        'promo_code': appliedPromo.value == 'Tidak Ada' ? '' : appliedPromo.value,
        'recipient_name': recipientName.value,
        'recipient_phone': recipientPhone.value,
        'item_description': itemDescription.value,
        'item_weight': itemWeight.value,
        'titip_item_price': titipItemPrice.value,
        'estimated_time': currentEstimatedArrival,
        'estimated_duration': currentEstimatedDuration,
      });

      final response = jsonDecode(rawResponse.body);

      if (rawResponse.statusCode == 201 || response['status'] == 201 || response['status'] == 200) {
        var orderId = response['data']['order_id'];
        Get.toNamed('/order-tracking', arguments: {'order_id': orderId});
      } else if (response['message']?.contains('Saldo Mai-Pay tidak mencukupi') == true) {
        double currentBalance = double.tryParse(_authController.userData['balance']?.toString() ?? '0') ?? 0;
        InsufficientBalanceSheet.show(
          currentBalance: currentBalance,
          requiredAmount: price.value.toDouble(),
          onPayCash: () {
            paymentMethod.value = 'cash';
            createOrder();
          },
        );
      } else if (response['message']?.contains('aktif') == true) {
        // Jika ada pesanan aktif, paksa ambil data pesanan aktif dan arahkan ke tracking
        _checkActiveOrder();
        Get.snackbar('Dialihkan', 'Mengembalikan Anda ke pesanan yang sedang berjalan', backgroundColor: Colors.orange, colorText: Colors.white);
      } else {
        Get.snackbar('Gagal', response['message'] ?? 'Gagal membuat pesanan', backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Terjadi kesalahan sistem');
    } finally {
      isLoading.value = false;
    }
  }

  void reset() {
    currentState.value = OrderState.idle;
    polylines.clear();
    markers.clear();
    pickupAddress.value = '';
    dropoffAddress.value = '';
    appliedPromo.value = '';
    discount.value = 0;
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
}
