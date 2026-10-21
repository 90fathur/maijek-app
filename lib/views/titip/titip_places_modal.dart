import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';

class TitipPlacesModal extends StatefulWidget {
  final LatLng? userLocation;

  const TitipPlacesModal({super.key, this.userLocation});

  static Future<Map<String, dynamic>?> show(BuildContext context, {LatLng? userLocation}) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TitipPlacesModal(userLocation: userLocation),
    );
  }

  @override
  State<TitipPlacesModal> createState() => _TitipPlacesModalState();
}

class _TitipPlacesModalState extends State<TitipPlacesModal> {
  final TextEditingController _searchCtrl = TextEditingController();
  
  bool _isLoading = true;
  String _selectedCategory = 'Semua';
  List<String> _categories = ['Semua'];
  List<dynamic> _allPlaces = [];
  List<dynamic> _filteredPlaces = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch categories
      try {
        final catRes = await ApiClient.get('/user/titip/categories');
        if (catRes.statusCode == 200) {
          final catData = jsonDecode(catRes.body);
          if (catData['status'] == 200 && catData['data'] is List) {
            final List<String> list = ['Semua'];
            for (var item in catData['data']) {
              if (item != null && item.toString().isNotEmpty) {
                list.add(item.toString());
              }
            }
            if (mounted) {
              setState(() {
                _categories = list;
              });
            }
          }
        }
      } catch (e) {
        debugPrint('Gagal fetch kategori titip: $e');
      }

      // 2. Fetch places
      final res = await ApiClient.get('/user/titip/places');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 200 && data['data'] is List) {
          _allPlaces = data['data'];
          _applyFilter();
        }
      }
    } catch (e) {
      debugPrint('Gagal fetch tempat titip: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    final query = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filteredPlaces = _allPlaces.where((item) {
        final name = (item['name'] ?? '').toString().toLowerCase();
        final addr = (item['address'] ?? '').toString().toLowerCase();
        final cat = (item['category'] ?? '').toString();
        final desc = (item['description'] ?? '').toString().toLowerCase();

        final matchQuery = query.isEmpty ||
            name.contains(query) ||
            addr.contains(query) ||
            cat.toLowerCase().contains(query) ||
            desc.contains(query);

        final matchCategory = _selectedCategory == 'Semua' || cat == _selectedCategory;

        return matchQuery && matchCategory;
      }).toList();

      // Sort by distance if user location is available
      if (widget.userLocation != null) {
        _filteredPlaces.sort((a, b) {
          double latA = double.tryParse(a['latitude'].toString()) ?? 0.0;
          double lngA = double.tryParse(a['longitude'].toString()) ?? 0.0;
          double latB = double.tryParse(b['latitude'].toString()) ?? 0.0;
          double lngB = double.tryParse(b['longitude'].toString()) ?? 0.0;

          double distA = Geolocator.distanceBetween(
              widget.userLocation!.latitude, widget.userLocation!.longitude, latA, lngA);
          double distB = Geolocator.distanceBetween(
              widget.userLocation!.latitude, widget.userLocation!.longitude, latB, lngB);

          return distA.compareTo(distB);
        });
      }
    });
  }

  IconData _getCategoryIcon(String? category) {
    switch ((category ?? '').toLowerCase()) {
      case 'pasar':
        return Icons.store_mall_directory_rounded;
      case 'kuliner':
        return Icons.restaurant_rounded;
      case 'toko & sembako':
      case 'toko':
        return Icons.shopping_basket_rounded;
      case 'apotek & obat':
      case 'apotek':
        return Icons.medical_services_rounded;
      case 'atk & fotocopy':
      case 'atk':
        return Icons.print_rounded;
      case 'elektronik & servis':
      case 'elektronik':
        return Icons.phonelink_setup_rounded;
      case 'fashion & pakaian':
      case 'fashion':
        return Icons.checkroom_rounded;
      default:
        return Icons.storefront_rounded;
    }
  }

  String _formatDistance(double lat, double lng) {
    if (widget.userLocation == null || (lat == 0 && lng == 0)) return '';
    double distMeters = Geolocator.distanceBetween(
      widget.userLocation!.latitude,
      widget.userLocation!.longitude,
      lat,
      lng,
    );
    if (distMeters >= 1000) {
      return '${(distMeters / 1000).toStringAsFixed(1)} KM';
    }
    return '${distMeters.round()} M';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.stars_rounded, color: Colors.amber, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tempat Rekomendasi Titip',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMain,
                        ),
                      ),
                      Text(
                        'Pilih toko populer tanpa repot cari koordinat',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => _applyFilter(),
                decoration: InputDecoration(
                  hintText: 'Cari pasar, warung, toko, apotek...',
                  hintStyle: const TextStyle(fontSize: 13.5, color: AppTheme.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryNavy, size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            _applyFilter();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Category Chips
          SizedBox(
            height: 38,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat == _selectedCategory;
                return ChoiceChip(
                  label: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : AppTheme.textMain,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryNavy,
                  backgroundColor: AppTheme.backgroundLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? AppTheme.primaryNavy : Colors.grey.shade300,
                    ),
                  ),
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedCategory = cat);
                      _applyFilter();
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),

          // Places List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _filteredPlaces.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.storefront_outlined, size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'Belum ada tempat ditemukan',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _searchCtrl.text.isNotEmpty
                                  ? 'Coba gunakan kata kunci pencarian lain'
                                  : 'Tempat rekomendasi akan segera ditambahkan',
                              style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredPlaces.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _filteredPlaces[index];
                          final lat = double.tryParse(item['latitude'].toString()) ?? 0.0;
                          final lng = double.tryParse(item['longitude'].toString()) ?? 0.0;
                          final distanceStr = _formatDistance(lat, lng);

                          return InkWell(
                            onTap: () {
                              Navigator.pop(context, {
                                'latLng': LatLng(lat, lng),
                                'name': item['name'] ?? '',
                                'address': item['address'] ?? '',
                                'fullAddress': '${item['name']} - ${item['address']}',
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Category Icon Box
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.teal.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _getCategoryIcon(item['category']),
                                      color: Colors.teal.shade700,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item['name'] ?? '',
                                                style: const TextStyle(
                                                  fontSize: 14.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.textMain,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (distanceStr.isNotEmpty)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  distanceStr,
                                                  style: TextStyle(
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blue.shade700,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            item['category'] ?? 'Umum',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item['address'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textMuted,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (item['description'] != null &&
                                            item['description'].toString().trim().isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.info_outline_rounded,
                                                  size: 13, color: Colors.amber.shade800),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  item['description'].toString(),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontStyle: FontStyle.italic,
                                                    color: Colors.amber.shade900,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
