import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../controllers/auth_controller.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final AuthController authController = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameC = TextEditingController();
  final TextEditingController phoneC = TextEditingController();
  final TextEditingController emailC = TextEditingController();

  File? _selectedPhoto;
  final ImagePicker _picker = ImagePicker();
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    if (Get.arguments != null) {
      if (Get.arguments is String) {
        phoneC.text = Get.arguments as String;
      } else if (Get.arguments is Map && Get.arguments['phone'] != null) {
        phoneC.text = Get.arguments['phone'].toString();
      }
    }
  }

  @override
  void dispose() {
    nameC.dispose();
    phoneC.dispose();
    emailC.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (file != null) {
        setState(() {
          _selectedPhoto = File(file.path);
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal memilih foto: $e',
          backgroundColor: Colors.red.shade700, colorText: Colors.white);
    }
  }

  void _showPhotoSourceModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih Foto Profil',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                    child: const Icon(Icons.photo_library, color: AppTheme.primaryBlue),
                  ),
                  title: const Text('Buka Galeri HP', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickPhoto(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: Colors.green),
                  ),
                  title: const Text('Ambil Foto Kamera', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickPhoto(ImageSource.camera);
                  },
                ),
                if (_selectedPhoto != null)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                      child: const Icon(Icons.delete_outline, color: Colors.red),
                    ),
                    title: const Text('Hapus Foto', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _selectedPhoto = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.gavel, color: AppTheme.primaryBlue),
            SizedBox(width: 8),
            Text('Syarat & Ketentuan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Selamat datang di Maijek!\n\n'
                  '1. Penggunaan Akun:\n'
                  'Pengguna bertanggung jawab penuh atas keamanan nomor telepon dan akun yang didaftarkan. Dilarang menyalahgunakan akun untuk tindakan ilegal.\n\n'
                  '2. Kebijakan Privasi:\n'
                  'Data seperti nama, nomor WhatsApp, email, dan lokasi GPS hanya digunakan untuk kelancaran layanan penjemputan, pengantaran makanan, serta pengiriman e-receipt bukti transaksi.\n\n'
                  '3. Pembatalan & Transaksi:\n'
                  'Pengguna diharapkan menghargai mitra driver dengan tidak membatalkan pesanan tanpa alasan yang sah setelah driver menuju titik jemput.\n\n'
                  '4. Hak Cipta & Layanan:\n'
                  'Maijek berhak menangguhkan akun yang terindikasi melakukan kecurangan demi menjaga kenyamanan bersama.',
                  style: TextStyle(fontSize: 13, height: 1.6, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _agreedToTerms = true;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Saya Setuju', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _submitRegister() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreedToTerms) {
      Get.snackbar(
        'Persetujuan Diperlukan',
        'Harap centang persetujuan Syarat & Ketentuan serta Kebijakan Privasi Maijek',
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
      );
      return;
    }

    final normalizedPhone = AuthController.normalizePhone(phoneC.text);

    authController.register(
      nameC.text,
      normalizedPhone,
      email: emailC.text,
      photoFile: _selectedPhoto,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textMain, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Titles
                const Text(
                  'Daftar Akun Baru',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMain,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Lengkapi profil Anda untuk mulai bepergian, pesan makanan, dan kirim barang bersama Maijek.',
                  style: TextStyle(fontSize: 14, color: AppTheme.textMuted, height: 1.4),
                ),
                const SizedBox(height: 24),

                // Avatar Picker (Optional)
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _selectedPhoto != null
                              ? Image.file(_selectedPhoto!, fit: BoxFit.cover)
                              : Container(
                                  color: Colors.blue.shade50,
                                  child: const Icon(Icons.person, size: 52, color: AppTheme.primaryBlue),
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _showPhotoSourceModal,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    _selectedPhoto != null ? 'Foto profil terpasang' : 'Pasang Foto Profil (Opsional)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 24),

                // Card Container Form
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
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Field 1: Nama Lengkap
                      const Text(
                        'Nama Lengkap',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: nameC,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: 'Contoh: Ahmad Fadilah',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                          prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primaryBlue, size: 20),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Nama lengkap tidak boleh kosong';
                          }
                          if (val.trim().length < 3) {
                            return 'Nama minimal 3 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Field 2: Nomor WhatsApp
                      const Text(
                        'Nomor WhatsApp / HP',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: phoneC,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: '81234567890 atau 0812...',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
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
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Nomor handphone wajib diisi';
                          }
                          String clean = val.trim().replaceAll(RegExp(r'[^0-9]'), '');
                          if (clean.length < 8 || clean.length > 15) {
                            return 'Nomor handphone tidak valid (8-15 digit)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.info_outline, size: 13, color: AppTheme.primaryBlue),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Bisa diawali 81... atau 08... (Kode OTP dikirim otomatis ke WhatsApp ini).',
                              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Field 3: Alamat Email
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Alamat Email',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                          ),
                          Text(
                            'Disarankan',
                            style: TextStyle(fontSize: 11, color: Colors.orange.shade700, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: emailC,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'nama@email.com',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                          prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.primaryBlue, size: 20),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                          ),
                        ),
                        validator: (val) {
                          if (val != null && val.trim().isNotEmpty) {
                            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegex.hasMatch(val.trim())) {
                              return 'Format email tidak valid';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Digunakan untuk pengiriman bukti pembayaran digital (e-receipt).',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 20),

                      // Terms & Conditions Checkbox
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _agreedToTerms,
                              activeColor: AppTheme.primaryBlue,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (val) {
                                setState(() {
                                  _agreedToTerms = val ?? false;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _agreedToTerms = !_agreedToTerms;
                                });
                              },
                              child: Wrap(
                                children: [
                                  const Text(
                                    'Saya menyetujui ',
                                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                  ),
                                  GestureDetector(
                                    onTap: _showTermsDialog,
                                    child: const Text(
                                      'Syarat & Ketentuan',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.primaryBlue,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    ' serta ',
                                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                  ),
                                  GestureDetector(
                                    onTap: _showTermsDialog,
                                    child: const Text(
                                      'Kebijakan Privasi',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.primaryBlue,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    ' Maijek.',
                                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      Obx(() => SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: authController.isLoading.value ? null : _submitRegister,
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
                                  'Daftar Sekarang',
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

                // Footer: Kembali ke Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Sudah punya akun? ', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: const Text(
                        'Masuk Sekarang',
                        style: TextStyle(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
