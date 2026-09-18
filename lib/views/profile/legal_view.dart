import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme.dart';
import '../../core/contact_helper.dart';

enum LegalType { terms, privacy }

class LegalView extends StatelessWidget {
  final LegalType type;

  const LegalView({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    bool isTerms = type == LegalType.terms;
    String title = isTerms ? 'Syarat & Ketentuan' : 'Kebijakan Privasi';

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: AppTheme.textMain, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textMain),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryBlue, Color(0xFF1E88E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isTerms ? Icons.gavel_rounded : Icons.security_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Maijek Indonesia • Polewali Mandar\nTerakhir diperbarui: 6 September 2026',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Content Section
            if (isTerms) ..._buildTermsContent() else ..._buildPrivacyContent(),

            const SizedBox(height: 28),

            // CS Help Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  const Text(
                    'Punya pertanyaan mengenai ketentuan ini?',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tim Layanan Pelanggan Maijek siap membantu Anda 24/7.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ContactHelper.openWhatsApp(
                          phone: '085117228559',
                          name: 'CS Maijek',
                          customMessage: 'Halo CS Maijek, saya ingin bertanya mengenai ${isTerms ? 'Syarat & Ketentuan' : 'Kebijakan Privasi'} layanan Maijek.',
                        );
                      },
                      icon: const Icon(Icons.chat, color: Colors.white, size: 18),
                      label: const Text('Hubungi CS via WhatsApp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTermsContent() {
    return [
      _buildSectionCard(
        number: '1',
        title: 'Ketentuan Akun Pengguna',
        content:
            'Pengguna wajib memberikan informasi yang akurat (nama lengkap dan nomor WhatsApp aktif) saat melakukan pendaftaran. Akun bersifat pribadi dan pengguna bertanggung jawab penuh atas segala aktivitas yang terjadi pada akun masing-masing.',
      ),
      _buildSectionCard(
        number: '2',
        title: 'Pemesanan Layanan (Ojek, Mobil, Send, MaiFood)',
        content:
            'Pengguna dapat memesan armada transportasi ojek motor (Mai-Ride), mobil (Mai-Car), kurir instan (Mai-Send & Titip), serta pemesanan kuliner makanan (MaiFood). Tarif dihitung secara otomatis dan transparan berdasarkan jarak tempuh atau harga menu mitra.',
      ),
      _buildSectionCard(
        number: '3',
        title: 'Metode Pembayaran',
        content:
            'Maijek mendukung pembayaran Tunai langsung kepada Mitra Driver saat pesanan tiba, maupun pembayaran nontunai menggunakan saldo MaiPay / QRIS Driver Resmi. Pengguna wajib menyelesaikan pembayaran sesuai dengan tagihan pesanan yang tertera pada aplikasi.',
      ),
      _buildSectionCard(
        number: '4',
        title: 'Kebijakan Pembatalan Pesanan',
        content:
            'Pengguna diharapkan menghargai mitra driver dengan tidak membatalkan pesanan tanpa alasan sah setelah driver menuju ke lokasi jemput atau setelah makanan mulai diproses oleh pihak restoran.',
      ),
      _buildSectionCard(
        number: '5',
        title: 'Standar Keamanan & Etika Bermitra',
        content:
            'Dilarang menggunakan layanan Maijek untuk membawa barang terlarang, narkotika, senjata tajam, atau melanggar hukum NKRI. Maijek berhak membekukan atau menonaktifkan akun yang melanggar ketentuan hukum atau melakukan kecurangan.',
      ),
    ];
  }

  List<Widget> _buildPrivacyContent() {
    return [
      _buildSectionCard(
        number: '1',
        title: 'Informasi Pribadi yang Dikumpulkan',
        content:
            'Kami mengumpulkan informasi yang Anda berikan secara langsung, termasuk Nama, Nomor WhatsApp, Alamat Email, dan Foto Profil untuk keperluan verifikasi akun dan kemudahan identifikasi penjemputan oleh mitra pengemudi.',
      ),
      _buildSectionCard(
        number: '2',
        title: 'Penggunaan Data Lokasi GPS (Penting)',
        content:
            'Aplikasi Maijek mengakses data lokasi presisi perangkat Anda saat aplikasi dibuka guna menentukan titik penjemputan akurat, menghitung jarak serta estimasi biaya perjalanan, dan menampilkan live tracking pergerakan driver secara real-time.',
      ),
      _buildSectionCard(
        number: '3',
        title: 'Keamanan Data & Privasi Pengguna',
        content:
            'Maijek berkomitmen melindungi data privasi Anda sesuai Undang-Undang Perlindungan Data Pribadi (UU PDP). Kami tidak pernah menjual, menyewakan, atau membagikan informasi pribadi Anda kepada pihak ketiga untuk kepentingan periklanan.',
      ),
      _buildSectionCard(
        number: '4',
        title: 'Izin Perangkat (Kamera & Penyimpanan)',
        content:
            'Izin kamera dan penyimpanan foto hanya digunakan saat Anda memilih untuk mengunggah atau mengganti foto profil akun secara sukarela.',
      ),
      _buildSectionCard(
        number: '5',
        title: 'Hak Pengguna & Penghapusan Akun',
        content:
            'Sesuai ketentuan Google Play Data Safety, Anda memiliki hak penuh untuk meminta penghapusan akun dan penghapusan seluruh data pribadi Anda kapan saja langsung melalui menu "Hapus Akun" di halaman profil aplikasi Maijek.',
      ),
    ];
  }

  Widget _buildSectionCard({
    required String number,
    required String title,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMain,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
