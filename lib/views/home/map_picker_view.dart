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
  const MapPickerView({Key? key}) : super(key: key);

  @override
  State<MapPickerView> createState() => _MapPickerViewState();
}

class _MapPickerViewState extends State<MapPickerView> {
  final OrderController orderController = Get.isRegistered<OrderController>() ? Get.find<OrderController>() : Get.put(OrderController());
  
  GoogleMapController? _mapController;
  LatLng _centerPosition = const LatLng(-3.425900, 119.337700); // Polewali Default
  String _currentAddress = "Geser peta untuk menentukan titik";
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    _determineInitialPosition();
  }

  Future<void> _determineInitialPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _centerPosition = LatLng(position.latitude, position.longitude);
      });
      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_centerPosition, 16));
      }
      _fetchAddressForCenter();
    } catch (e) {
      // Fallback
    }
  }

  Future<void> _fetchAddressForCenter() async {
    setState(() => _isLoadingAddress = true);
    
    // We can't use private _getAddressFromLatLng directly unless we expose it, but we can copy the logic
    try {
      String url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=${_centerPosition.latitude},${_centerPosition.longitude}&key=${orderController.googleApiKey}';
      var response = await http.get(Uri.parse(url));
      var data = jsonDecode(response.body);

      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
        setState(() {
          _currentAddress = data['results'][0]['formatted_address'];
        });
      } else {
        setState(() {
          _currentAddress = 'Titik di Peta yang Dipilih';
        });
      }
    } catch (e) {
      setState(() {
        _currentAddress = 'Titik di Peta yang Dipilih';
      });
    }
    
    setState(() => _isLoadingAddress = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _centerPosition, zoom: 15),
            onMapCreated: (controller) {
              _mapController = controller;
              _mapController?.setMapStyle(MapStyle.cleanStyle);
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
              padding: const EdgeInsets.only(bottom: 35.0), // Adjust to make the point of the pin exactly center
              child: Icon(Icons.location_on, size: 50, color: Colors.red),
            ),
          ),
          
          // Back button and Search Bar Overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Get.back(),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        var result = await Get.to(() => const LocationSearchView(), arguments: 'dropoff');
                        if (result != null) {
                          LatLng loc = result['latLng'];
                          _mapController?.animateCamera(CameraUpdate.newLatLngZoom(loc, 17));
                          setState(() {
                            _centerPosition = loc;
                            _currentAddress = result['address'];
                          });
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: Colors.grey),
                            SizedBox(width: 8),
                            Text('Cari lokasi tujuan...', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Info & Confirm Button
          Positioned(
            right: 16,
            bottom: 200, // Above the bottom sheet
            child: FloatingActionButton(
              heroTag: 'map_picker_gps',
              backgroundColor: Colors.white,
              onPressed: () {
                _determineInitialPosition();
              },
              child: const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))]
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Lokasi Terpilih', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: AppTheme.primaryBlue),
                      SizedBox(width: 12),
                      Expanded(
                        child: _isLoadingAddress 
                          ? Text("Memuat alamat...", style: TextStyle(color: Colors.grey))
                          : Text(_currentAddress, style: TextStyle(color: Colors.grey[700])),
                      )
                    ],
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!_isLoadingAddress) {
                          Get.back(result: {'latLng': _centerPosition, 'address': _currentAddress});
                        }
                      },
                      child: Text('Pilih Titik Lokasi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      )
    );
  }
}
