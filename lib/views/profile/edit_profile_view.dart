import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../controllers/auth_controller.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final AuthController authController = Get.find<AuthController>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  late String _initialName;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initialName = (authController.userData['name'] ?? '').toString().trim();
    _nameController.text = _initialName;
    _phoneController.text = (authController.userData['phone'] ?? '').toString();
    _emailController.text = (authController.userData['email'] ?? '').toString();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _saveProfile(bool canChangeName) {
    String name = _nameController.text.trim();
    String phone = _phoneController.text.trim();
    String email = _emailController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      Get.snackbar(
        'Data Belum Lengkap', 
        'Nama dan Nomor HP tidak boleh kosong', 
        backgroundColor: Colors.orange.shade800, 
        colorText: Colors.white
      );
      return;
    }

    bool isNameChanged = canChangeName && name.toLowerCase() != _initialName.toLowerCase();

    if (isNameChanged) {
      // Dialog Konfirmasi Ubah Nama (Cuma 1 Kali Saja)
      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ubah Nama 1x Saja',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nama akun Anda akan diubah menjadi:'),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryNavy.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primaryNavy.withValues(alpha: 0.2)),
                ),
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryNavy),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.amber.shade900),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'PENTING: Perubahan nama ini HANYA DAPAT DILAKUKAN 1 KALI saja seumur hidup akun untuk menghindari orang ganti-ganti nama. Setelah disimpan, nama terkunci permanen.',
                        style: TextStyle(fontSize: 11.5, color: Colors.amber.shade900, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Apakah Anda yakin nama sudah benar sesuai kartu identitas asli Anda?',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Batal / Periksa Lagi', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Get.back();
                _executeSave(name, phone, email);
              },
              child: const Text('Ya, Simpan Permanen', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      _executeSave(name, phone, email);
    }
  }

  void _executeSave(String name, String phone, String email) async {
    bool success = await authController.updateProfile(name, phone, email: email, imageFile: _imageFile);
    if (success) {
      Get.back();
      Get.snackbar(
        '🎉 Berhasil', 
        'Profil Anda berhasil diperbarui di server',
        backgroundColor: Colors.green.shade700, 
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textMain, size: 20),
          onPressed: () => Get.back(),
        ),
        title: const Text('Edit Profil', style: TextStyle(color: AppTheme.textMain, fontWeight: FontWeight.bold)),
      ),
      body: Obx(() {
        final user = authController.userData;
        int nameChangesCount = int.tryParse(user['name_changes_count']?.toString() ?? '0') ?? 0;
        bool canChangeName = user['can_change_name'] != false && nameChangesCount < 1;
        String currentPhoto = (user['photo_url'] ?? '').toString();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar Section
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primaryBlue, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: ClipOval(
                        child: _imageFile != null
                            ? Image.file(_imageFile!, fit: BoxFit.cover)
                            : (currentPhoto.isNotEmpty
                                ? (currentPhoto.startsWith('http')
                                    ? Image.network(
                                        currentPhoto,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => const Icon(Icons.person, size: 60, color: Colors.grey),
                                      )
                                    : Image.file(
                                        File(currentPhoto),
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => const Icon(Icons.person, size: 60, color: Colors.grey),
                                      ))
                                : const Icon(Icons.person, size: 60, color: Colors.grey)),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Form Section: 1. Nama Lengkap (Cuma 1 Kali Ubah)
              _buildTextField(
                label: 'Nama Lengkap Akun',
                controller: _nameController,
                icon: Icons.person_outline,
                enabled: canChangeName,
                suffixIcon: canChangeName
                    ? Container(
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Bisa Ubah 1x', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                      )
                    : Container(
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.lock_rounded, size: 14, color: Colors.grey),
                            SizedBox(width: 4),
                            Text('Terkunci', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                          ],
                        ),
                      ),
              ),
              
              // Keterangan Pembatasan Ubah Nama
              if (!canChangeName)
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 18, color: Colors.amber.shade900),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Nama akun hanya dapat diubah 1 kali saja untuk menghindari orang ganti-ganti nama. Anda sudah pernah mengubah nama akun sebelumnya.',
                          style: TextStyle(fontSize: 11.5, color: Colors.amber.shade900, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.primaryBlue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Perhatian: Nama akun hanya dapat diubah 1 KALI saja seumur hidup akun untuk mencegah penyalahgunaan. Pastikan nama sesuai kartu identitas asli Anda.',
                          style: TextStyle(fontSize: 11.5, color: AppTheme.primaryNavy, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Form Section: 2. Nomor Handphone (Ditampilkan Jelas & Terkunci untuk Keamanan Login)
              _buildTextField(
                label: 'Nomor Handphone (WhatsApp)',
                controller: _phoneController,
                icon: Icons.phone_android_rounded,
                isPhone: true,
                enabled: false,
                suffixIcon: Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.verified_rounded, size: 14, color: Color(0xFF059669)),
                      SizedBox(width: 4),
                      Text('Terverifikasi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 6, bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 14, color: Color(0xFF059669)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Nomor HP terhubung permanen dengan akun WhatsApp login Anda.',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Form Section: 3. Alamat Email
              _buildTextField(
                label: 'Alamat Email',
                controller: _emailController,
                icon: Icons.email_outlined,
                isEmail: true,
                enabled: true,
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: authController.isUpdatingProfile.value ? null : () => _saveProfile(canChangeName),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: authController.isUpdatingProfile.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Simpan Perubahan',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isPhone = false,
    bool isEmail = false,
    bool enabled = true,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      readOnly: !enabled,
      keyboardType: isPhone ? TextInputType.phone : (isEmail ? TextInputType.emailAddress : TextInputType.text),
      style: TextStyle(
        fontWeight: enabled ? FontWeight.normal : FontWeight.w600,
        color: enabled ? AppTheme.textMain : Colors.grey.shade800,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: enabled ? AppTheme.primaryBlue : Colors.grey),
        suffixIcon: suffixIcon,
        filled: !enabled,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: enabled ? Colors.grey.shade300 : Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
        ),
      ),
    );
  }
}
