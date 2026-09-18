import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme.dart';

class VerifyOtpView extends StatefulWidget {
  const VerifyOtpView({super.key});

  @override
  State<VerifyOtpView> createState() => _VerifyOtpViewState();
}

class _VerifyOtpViewState extends State<VerifyOtpView> {
  final AuthController authController = Get.find<AuthController>();
  final TextEditingController otpController = TextEditingController();
  String phone = '';

  @override
  void initState() {
    super.initState();
    _initPhone();

    // Pastikan countdown berjalan saat pertama kali masuk halaman
    if (authController.resendCountdown.value == 0) {
      authController.startResendTimer(60);
    }
  }

  Future<void> _initPhone() async {
    final prefs = await SharedPreferences.getInstance();
    if (Get.arguments != null) {
      if (Get.arguments is Map && Get.arguments['phone'] != null) {
        phone = AuthController.normalizePhone(Get.arguments['phone'].toString());
      } else if (Get.arguments is String) {
        phone = AuthController.normalizePhone(Get.arguments as String);
      }
      if (phone.isNotEmpty) {
        await prefs.setString('pending_otp_phone', phone);
      }
    }
    if (phone.isEmpty) {
      phone = prefs.getString('pending_otp_phone') ?? '';
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  String _formatDisplayPhone(String raw) {
    String clean = AuthController.normalizePhone(raw);
    if (clean.startsWith('0')) {
      return '+62 ${clean.substring(1)}';
    }
    return raw;
  }

  void _submitOtp() {
    final code = otpController.text.trim();
    if (code.length == 6) {
      authController.verifyOtp(phone, code);
    } else {
      Get.snackbar(
        'Kode Belum Lengkap',
        'Masukkan 6 digit kode OTP yang diterima',
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (phone.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textMain, size: 20),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Verifikasi Akun',
          style: TextStyle(color: AppTheme.textMain, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // WhatsApp OTP Badge Header
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.mark_chat_unread_outlined,
                      color: Color(0xFF25D366),
                      size: 38,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Masukkan Kode OTP',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMain,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Penjelasan target nomor HP
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Kode verifikasi 6-digit telah dikirimkan melalui pesan resmi WhatsApp ke nomor:',
                      style: TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('💬 ', style: TextStyle(fontSize: 15)),
                        Text(
                          _formatDisplayPhone(phone),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textMain,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => Get.back(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Ubah Nomor',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // OTP Input Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                child: Column(
                  children: [
                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        letterSpacing: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '••••••',
                        hintStyle: TextStyle(
                          letterSpacing: 14,
                          color: Colors.grey.shade300,
                          fontSize: 26,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
                        ),
                      ),
                      onChanged: (val) {
                        if (val.length == 6) {
                          _submitOtp();
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Verifikasi Button
                    Obx(() => SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: authController.isLoading.value ? null : _submitOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: authController.isLoading.value
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text(
                                'Verifikasi Sekarang',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Countdown Timer & Kirim Ulang OTP
              Center(
                child: Obx(() {
                  final countdown = authController.resendCountdown.value;
                  if (countdown > 0) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timer_outlined, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Text(
                          'Kirim ulang kode dalam $countdown detik',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  }

                  return TextButton.icon(
                    onPressed: () {
                      authController.resendOtp(phone);
                    },
                    icon: const Icon(Icons.refresh, size: 18, color: AppTheme.primaryBlue),
                    label: const Text(
                      'Kirim Ulang Kode OTP',
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),

              Center(
                child: Text(
                  'Pastikan nomor WhatsApp Anda aktif dan memiliki koneksi internet.',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
