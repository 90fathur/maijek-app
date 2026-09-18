import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme.dart';

import '../../controllers/auth_controller.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final AuthController authController = Get.find<AuthController>();
  final TextEditingController phoneC = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Logo
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              const Text(
                'Selamat Datang di Maijek',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMain,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Masuk dengan nomor handphone Anda untuk mulai bepergian.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Form
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    TextFormField(
                      controller: phoneC,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Nomor WhatsApp / HP',
                        hintText: '81234567890 atau 0812...',
                        prefixIcon: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🇮🇩', style: TextStyle(fontSize: 18)),
                              const SizedBox(width: 6),
                              Text(
                                '+62',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700, fontSize: 14),
                              ),
                              const SizedBox(width: 8),
                              Container(width: 1, height: 20, color: Colors.grey.shade300),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Obx(() => ElevatedButton(
                      onPressed: authController.isLoading.value ? null : () {
                        authController.login(phoneC.text);
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: authController.isLoading.value 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Lanjutkan'),
                    )),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Belum punya akun? ', style: TextStyle(color: AppTheme.textMuted)),
                  TextButton(
                    onPressed: () {
                      Get.toNamed('/register');
                    },
                    child: const Text('Daftar Sekarang', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
