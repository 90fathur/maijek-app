import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:audioplayers/audioplayers.dart';
import 'notification_service.dart';

/// Layanan Peringatan Jarak Dekat Kurir (Proximity Alert Service)
/// Membunyikan nada dering notifikasi khusus saat kurir berada dalam radius <= 100 meter
/// dari lokasi pelanggan.
class ProximityAlertService {
  static AudioPlayer? _audioPlayer;
  static final Set<String> _alertedOrders = {};
  static const double proximityThresholdMeters = 100.0;
  static bool _isPlaying = false;

  /// Inisialisasi Audio Player
  static void init() {
    _audioPlayer ??= AudioPlayer();
  }

  /// Evaluasi posisi kurir terhadap titik tujuan.
  /// Jika jarak <= 100 meter dan belum pernah dibunyikan untuk pesanan ini, bunyikan alarm notifikasi!
  static Future<bool> checkAndTriggerProximityAlert({
    required String orderId,
    required String orderType,
    required double driverLat,
    required double driverLng,
    required double targetLat,
    required double targetLng,
    String? driverName,
    String? driverPlate,
  }) async {
    // Abaikan jika koordinat tidak valid (0, 0)
    if (driverLat == 0 || driverLng == 0 || targetLat == 0 || targetLng == 0) {
      return false;
    }

    // Hindari membunyikan berkali-kali untuk pesanan yang sama
    final alertKey = '${orderType}_$orderId';
    if (_alertedOrders.contains(alertKey)) {
      return false;
    }

    try {
      final double distanceMeters = Geolocator.distanceBetween(
        driverLat,
        driverLng,
        targetLat,
        targetLng,
      );

      debugPrint(
        'ProximityAlert: Order #$orderId ($orderType) Distance to target: ${distanceMeters.toStringAsFixed(1)}m (Threshold: ${proximityThresholdMeters}m)',
      );

      if (distanceMeters <= proximityThresholdMeters) {
        // Tandai pesanan ini sudah dibunyikan
        _alertedOrders.add(alertKey);

        // 1. Putar Nada Dering Suara Notifikasi Khusus
        await playProximitySound();

        // 2. Berikan getaran haptic
        try {
          HapticFeedback.vibrate();
        } catch (_) {}

        // 3. Tampilkan Banner Dialog / Notifikasi Visual di Layar
        _showVisualAlert(
          orderType: orderType,
          distanceMeters: distanceMeters,
          driverName: driverName,
          driverPlate: driverPlate,
        );

        // 4. Notifikasi lokal bar status jika aplikasi berada di background
        try {
          NotificationService.showLocalAlert(
            title: '🛵 Kurir Sudah Tiba di Dekat Anda!',
            body:
                'Kurir berjarak ~${distanceMeters.round()} meter dari lokasi Anda. Silakan bersiap menyambut kurir!',
            sound: 'courier_near',
          );
        } catch (_) {}

        return true;
      }
    } catch (e) {
      debugPrint('ProximityAlertService Error: $e');
    }

    return false;
  }

  /// Memutar file audio notifikasi khusus kurir dekat
  static Future<void> playProximitySound() async {
    if (_isPlaying) return;
    try {
      _isPlaying = true;
      _audioPlayer ??= AudioPlayer();
      await _audioPlayer?.stop();
      await _audioPlayer?.setVolume(1.0);
      await _audioPlayer?.play(AssetSource('audio/courier_near.mp3'));
      
      // Reset flag isPlaying setelah 3 detik
      Timer(const Duration(seconds: 3), () {
        _isPlaying = false;
      });
    } catch (e) {
      _isPlaying = false;
      debugPrint('Error playing proximity sound: $e');
    }
  }

  /// Tampilkan notifikasi banner visual di bagian atas layar
  static void _showVisualAlert({
    required String orderType,
    required double distanceMeters,
    String? driverName,
    String? driverPlate,
  }) {
    String roleLabel = 'Kurir Makanan';
    if (orderType.contains('ride')) {
      roleLabel = 'Driver Penjemput';
    } else if (orderType.contains('mart')) {
      roleLabel = 'Kurir Belanjaan';
    } else if (orderType.contains('titip') || orderType.contains('send')) {
      roleLabel = 'Kurir Pengantaran';
    }

    final dName = (driverName != null && driverName.isNotEmpty) ? ' ($driverName)' : '';
    final dPlate = (driverPlate != null && driverPlate.isNotEmpty) ? ' • $driverPlate' : '';

    if (Get.context != null) {
      Get.snackbar(
        '🛵 $roleLabel Sudah Dekat!',
        'Kurir$dName berjarak ±${distanceMeters.round()} meter dari lokasi Anda. Silakan bersiap menyambut kedatangan kurir!$dPlate',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF0E1B38),
        colorText: Colors.white,
        icon: Container(
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFFFDB813),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.near_me, color: Color(0xFF0E1B38), size: 24),
        ),
        duration: const Duration(seconds: 6),
        margin: const EdgeInsets.all(12),
        borderRadius: 14,
        isDismissible: true,
        boxShadows: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );
    }
  }

  /// Reset penanda order jika selesai/batal
  static void resetOrder(String orderId) {
    _alertedOrders.removeWhere((key) => key.endsWith('_$orderId'));
  }

  /// Bersihkan seluruh cache alarm
  static void clear() {
    _alertedOrders.clear();
    try {
      _audioPlayer?.stop();
    } catch (_) {}
  }
}

