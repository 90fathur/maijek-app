import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import '../../controllers/auth_controller.dart';

class RatingView extends StatefulWidget {
  const RatingView({super.key});

  @override
  State<RatingView> createState() => _RatingViewState();
}

class _RatingViewState extends State<RatingView> {
  int _rating = 5;
  int _selectedTip = 0;
  final TextEditingController _reviewController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Ambil data driver yang dikirim dari OrderTrackingController
    final driverData = Get.arguments as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Beri Penilaian'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text(
              'Perjalanan Selesai!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bagaimana pengalaman Anda berkendara bersama Maijek?',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 40),
            
            // Driver Info
            CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(ApiClient.getImageUrl(driverData?['driver_photo'])),
              backgroundColor: Colors.grey.shade200,
            ),
            const SizedBox(height: 16),
            Text(
              driverData?['name'] ?? 'Driver Maijek',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              driverData?['vehicle_plate'] ?? '-',
              style: const TextStyle(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 32),
            
            // Star Rating (Interactive)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 40,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 24),
            
            // Review Text
            TextField(
              controller: _reviewController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Tulis ulasan Anda (opsional)...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 32),
            
            // Tip Section
            const Text('Beri Tip (Opsional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTipOption(2000, 'Rp. 2k'),
                _buildTipOption(5000, 'Rp. 5k'),
                _buildTipOption(10000, 'Rp. 10k'),
              ],
            ),
            const SizedBox(height: 40),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (driverData?['order_id'] == null) {
                    Get.offAllNamed('/home');
                    return;
                  }

                  // Tampilkan loading
                  Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
                  
                  try {
                    await ApiClient.post('/user/orders/rate', {
                      'order_id': driverData!['order_id'],
                      'rating': _rating,
                      'review': _reviewController.text,
                      'tip': _selectedTip,
                    });
                    
                    Get.back(); // Tutup loading
                    Get.snackbar('Terima Kasih', 'Ulasan Anda telah tersimpan.', backgroundColor: Colors.green, colorText: Colors.white);
                    
                    // Paksa sinkronisasi profil (termasuk potong saldo jika ada tip)
                    await Get.find<AuthController>().fetchProfile();
                    
                    Future.delayed(const Duration(seconds: 1), () {
                      if (Get.previousRoute == '/order-history') {
                        Get.back(); // Kembali ke history
                      } else {
                        Get.offAllNamed('/home'); // Ke home jika dari tracking
                      }
                    });
                  } catch (e) {
                    Get.back();
                    Get.snackbar('Error', 'Gagal mengirim ulasan', backgroundColor: Colors.red, colorText: Colors.white);
                    Get.offAllNamed('/home');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(_selectedTip > 0 ? 'KIRIM & BAYAR TIP' : 'KIRIM PENILAIAN', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Get.offAllNamed('/home'),
              child: const Text('Lewati', style: TextStyle(color: AppTheme.textMuted)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipOption(int amount, String label) {
    bool isSelected = _selectedTip == amount;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedTip = 0;
          } else {
            _selectedTip = amount;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.white,
          border: Border.all(color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppTheme.textMain,
          ),
        ),
      ),
    );
  }
}
