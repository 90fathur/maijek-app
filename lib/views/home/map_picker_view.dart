import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';
import '../../core/theme.dart';
import '../../core/map_style.dart';
import '../../controllers/order_controller.dart';
import 'location_search_view.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MapPickerView extends StatefulWidget {
  final LatLng? initialPosition;
  final String? initialAddress;
  final String title;

  const MapPickerView({
    Key? key,
    this.initialPosition,
    this.initialAddress,
    this.title = 'Pilih Titik di Peta',
  }) : super(key: key);

  @override
  State<MapPickerView> createState() => _MapPickerViewState();
}

class _MapPickerViewState extends State<MapPickerView> {
  final OrderController orderController = Get.isRegistered<OrderController>() ? Get.find<OrderController>() : Get.put(OrderController());
  
  GoogleMapController? _mapController;
  LatLng _centerPosition = const LatLng(-3.425900, 119.337700); // Polewali Default
  String _currentAddress = "Geser peta untuk menentukan titik";
  bool _isLoadingAddress = false;
  bool _hasUserSelectedLocation = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPosition != null && widget.initialPosition!.latitude != 0) {
      _centerPosition = widget.initialPosition!;
      _hasUserSelectedLocation = true;
      if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
        _currentAddress = widget.initialAddress!;
      } else {
        _fetchAddressForCenter();
      }
    } else {
      _determineInitialPosition();
    }
  }

  Future<void> _determineInitialPosition() async {
    if (_hasUserSelectedLocation) return;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (_hasUserSelectedLocation) return; // Lindungi agar tidak menimpa lokasi pilihan user
      setState(() {
        _centerPosition = LatLng(position.latitude, position.longitude);
      });
      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_centerPosition, 16));
      }
      _fetchAddressForCenter();
    } catch (e) {
      debugPrint('Determine initial pos error: $e');
    }
  }

  Future<void> _fetchAddressForCenter() async {
    if (!mounted) return;
    setState(() => _isLoadingAddress = true);
    
    try {
      String url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=${_centerPosition.latitude},${_centerPosition.longitude}&key=${orderController.googleApiKey}';
      var response = await http.get(Uri.parse(url));
      var data = jsonDecode(response.body);

      if (mounted && data['status'] == 'OK' && data['results'] != null && (data['results'] as List).isNotEmpty) {
        setState(() {
          _currentAddress = data['results'][0]['formatted_address'];
        });
      } else if (mounted) {
        if (_currentAddress == "Geser peta untuk menentukan titik") {
          setState(() {
            _currentAddress = 'Titik di Peta yang Dipilih';
          });
        }
      }
    } catch (e) {
      debugPrint('Geocode center error: $e');
    }
    
    if (mounted) {
      setState(() => _isLoadingAddress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            style: MapStyle.cleanStyle,
            initialCameraPosition: CameraPosition(target: _centerPosition, zoom: 16),
            onMapCreated: (controller) {
              _mapController = controller;
              if (widget.initialPosition != null && widget.initialPosition!.latitude != 0) {
                _mapController?.animateCamera(CameraUpdate.newLatLngZoom(widget.initialPosition!, 17));
              }
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onCameraMove: (CameraPosition position) {
              _centerPosition = position.target;
            },
            onCameraIdle: () {
              _fetchAddressForCenter();
            },
          ),
          
          // Center Marker (Pin)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 36.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNavy,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: const Text(
                      'Geser peta ke titik pas',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.location_on, size: 48, color: Colors.red),
                ],
              ),
            ),
          ),
          
          // Back button and Search Bar Overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Get.back(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        var result = await Get.to(() => const LocationSearchView(), arguments: 'dropoff');
                        if (result != null && result is Map) {
                          LatLng loc = result['latLng'];
                          _hasUserSelectedLocation = true;
                          setState(() {
                            _centerPosition = loc;
                            _currentAddress = result['address'] ?? 'Titik di Peta';
                          });
                          _mapController?.animateCamera(CameraUpdate.newLatLngZoom(loc, 17));
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: AppTheme.primaryBlue, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _currentAddress != "Geser peta untuk menentukan titik" ? _currentAddress : 'Ketik nama lokasi...',
                                style: TextStyle(
                                  color: _currentAddress != "Geser peta untuk menentukan titik" ? AppTheme.textMain : Colors.grey,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // GPS Recenter Button
          Positioned(
            right: 16,
            bottom: 210,
            child: FloatingActionButton(
              heroTag: 'map_picker_gps',
              backgroundColor: Colors.white,
              elevation: 4,
              onPressed: () {
                _hasUserSelectedLocation = false;
                _determineInitialPosition();
              },
              child: const Icon(Icons.my_location, color: AppTheme.primaryBlue),
            ),
          ),

          // Bottom Info & Confirm Button
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit_location_alt, color: AppTheme.primaryBlue, size: 18),
                      const SizedBox(width: 8),
                      Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, color: Colors.red, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _isLoadingAddress 
                          ? const Text("Memuat alamat titik...", style: TextStyle(color: Colors.grey, fontSize: 13))
                          : Text(
                              _currentAddress,
                              style: const TextStyle(color: AppTheme.textMain, fontSize: 13, fontWeight: FontWeight.w500),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back(result: {'latLng': _centerPosition, 'address': _currentAddress});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Pilih Titik Lokasi Ini',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
