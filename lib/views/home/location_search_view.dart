import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme.dart';
import 'map_picker_view.dart';
import '../../controllers/order_controller.dart';

class LocationSearchView extends StatefulWidget {
  const LocationSearchView({super.key});

  @override
  State<LocationSearchView> createState() => _LocationSearchViewState();
}

class _LocationSearchViewState extends State<LocationSearchView> {
  final OrderController orderController = Get.isRegistered<OrderController>() ? Get.find<OrderController>() : Get.put(OrderController());
  final TextEditingController _searchController = TextEditingController();
  
  List<dynamic> _predictions = [];
  bool _isLoading = false;
  late bool _isPickup;
  
  Map<String, dynamic>? _savedHome;
  Map<String, dynamic>? _savedWork;

  @override
  void initState() {
    super.initState();
    // Mendapatkan tipe pencarian dari arguments: 'pickup' atau 'dropoff'
    _isPickup = Get.arguments == 'pickup';
    _loadSavedPlaces();
  }
  
  Future<void> _loadSavedPlaces() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
       String? homeLat = prefs.getString('saved_home_lat');
       if (homeLat != null) {
          _savedHome = {
            'address': prefs.getString('saved_home_address') ?? 'Rumah',
            'latLng': LatLng(double.parse(homeLat), double.parse(prefs.getString('saved_home_lng')!))
          };
       }
       String? workLat = prefs.getString('saved_work_lat');
       if (workLat != null) {
          _savedWork = {
            'address': prefs.getString('saved_work_address') ?? 'Kantor',
            'latLng': LatLng(double.parse(workLat), double.parse(prefs.getString('saved_work_lng')!))
          };
       }
    });
  }

  void _onSearchChanged(String query) async {
    if (query.length > 2) {
      setState(() => _isLoading = true);
      // Kirim lokasi saat ini agar hasil pencarian diprioritaskan di sekitar pengguna
      var results = await orderController.searchPlaces(query, currentLocation: orderController.pickupLocation.value);
      setState(() {
        _predictions = results;
        _isLoading = false;
      });
    } else {
      setState(() => _predictions = []);
    }
  }

  void _onPlaceSelected(String placeId, String description) async {
    setState(() => _isLoading = true);
    
    var latLng = await orderController.getPlaceDetails(placeId);
    
    setState(() => _isLoading = false);
    
    if (latLng != null) {
      Get.back(result: {'latLng': latLng, 'address': description});
    } else {
      Get.snackbar('Error', 'Gagal mendapatkan koordinat lokasi');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textMain),
          onPressed: () => Get.back(),
        ),
        title: Text(
          _isPickup ? 'Cari Titik Jemput' : 'Cari Lokasi Tujuan',
          style: const TextStyle(color: AppTheme.textMain, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Ketik nama gedung, jalan, atau area...',
                prefixIcon: Icon(
                  _isPickup ? Icons.trip_origin : Icons.location_on, 
                  color: _isPickup ? AppTheme.primaryBlue : Colors.red
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _predictions = []);
                  },
                ),
                filled: true,
                fillColor: AppTheme.backgroundLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          
          // Loading Indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: LinearProgressIndicator(),
            ),

          // Saved Places Shortcuts
          if (_predictions.isEmpty && !_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSavedPlaceCard(
                      Icons.home, 
                      'Rumah', 
                      _savedHome != null ? _savedHome!['address'] : 'Set lokasi rumah',
                      _savedHome != null
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSavedPlaceCard(
                      Icons.work, 
                      'Kantor', 
                      _savedWork != null ? _savedWork!['address'] : 'Set lokasi kantor',
                      _savedWork != null
                    ),
                  ),
                ],
              ),
            ),

          // Results List
          Expanded(
            child: ListView.separated(
              itemCount: _predictions.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                var prediction = _predictions[index];
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on, color: Colors.grey, size: 20),
                  ),
                  title: Text(
                    prediction['structured_formatting']['main_text'] ?? prediction['description'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    prediction['structured_formatting']['secondary_text'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _onPlaceSelected(prediction['place_id'], prediction['description']),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedPlaceCard(IconData icon, String title, String subtitle, bool isSet) {
    return GestureDetector(
      onTap: () async {
        if (isSet) {
          // If set, use it directly
          if (title == 'Rumah' && _savedHome != null) {
            Get.back(result: _savedHome);
          } else if (title == 'Kantor' && _savedWork != null) {
            Get.back(result: _savedWork);
          }
        } else {
          // Prompt user to search and set
          Get.snackbar(
            'Atur $title',
            'Silakan cari alamat lalu lokasi ini akan tersimpan otomatis.',
            backgroundColor: AppTheme.primaryBlue,
            colorText: Colors.white,
          );
          // Kita arahkan user ke MapPickerView untuk memilih lokasi
          final selectedLocation = await Get.to(() => const MapPickerView());
          if (selectedLocation != null && selectedLocation is Map<String, dynamic>) {
            final prefs = await SharedPreferences.getInstance();
            if (title == 'Rumah') {
              await prefs.setString('saved_home_lat', selectedLocation['lat'].toString());
              await prefs.setString('saved_home_lng', selectedLocation['lng'].toString());
              await prefs.setString('saved_home_address', selectedLocation['address'].toString());
            } else {
              await prefs.setString('saved_work_lat', selectedLocation['lat'].toString());
              await prefs.setString('saved_work_lng', selectedLocation['lng'].toString());
              await prefs.setString('saved_work_address', selectedLocation['address'].toString());
            }
            _loadSavedPlaces(); // Reload
            Get.snackbar('Sukses', 'Alamat $title berhasil disimpan!', backgroundColor: Colors.green, colorText: Colors.white);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSet ? AppTheme.primaryBlue.withOpacity(0.05) : Colors.white,
          border: Border.all(color: isSet ? AppTheme.primaryBlue : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: isSet ? AppTheme.primaryBlue : AppTheme.backgroundLight, shape: BoxShape.circle),
              child: Icon(icon, size: 20, color: isSet ? Colors.white : AppTheme.primaryBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
