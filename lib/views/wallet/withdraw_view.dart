import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/wallet_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme.dart';

class WithdrawView extends StatefulWidget {
  const WithdrawView({super.key});

  @override
  State<WithdrawView> createState() => _WithdrawViewState();
}

class _WithdrawViewState extends State<WithdrawView> {
  final WalletController walletController = Get.find<WalletController>();
  final AuthController authController = Get.find<AuthController>();

  final TextEditingController amountController = TextEditingController();
  final TextEditingController accountNumberController = TextEditingController();
  final TextEditingController accountNameController = TextEditingController();

  final NumberFormat formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  String selectedBank = 'Bank BRI';

  final List<Map<String, dynamic>> bankOptions = [
    {'name': 'Bank BRI', 'type': 'Bank', 'icon': Icons.account_balance},
    {'name': 'Bank BCA', 'type': 'Bank', 'icon': Icons.account_balance},
    {'name': 'Bank Mandiri', 'type': 'Bank', 'icon': Icons.account_balance},
    {'name': 'Bank BNI', 'type': 'Bank', 'icon': Icons.account_balance},
    {'name': 'Bank BSI (Syariah)', 'type': 'Bank', 'icon': Icons.account_balance},
    {'name': 'Bank Jago', 'type': 'Bank', 'icon': Icons.account_balance},
    {'name': 'DANA', 'type': 'E-Wallet', 'icon': Icons.phone_android},
    {'name': 'GoPay', 'type': 'E-Wallet', 'icon': Icons.phone_android},
    {'name': 'OVO', 'type': 'E-Wallet', 'icon': Icons.phone_android},
    {'name': 'ShopeePay', 'type': 'E-Wallet', 'icon': Icons.phone_android},
    {'name': 'LinkAja', 'type': 'E-Wallet', 'icon': Icons.phone_android},
  ];

  final List<int> quickAmounts = [25000, 50000, 100000, 200000];

  @override
  void initState() {
    super.initState();
    walletController.fetchWithdrawStatus();
  }

  @override
  void dispose() {
    amountController.dispose();
    accountNumberController.dispose();
    accountNameController.dispose();
    super.dispose();
  }

  double get currentBalance {
    var b = authController.userData['balance'];
    return double.tryParse(b?.toString() ?? '0') ?? 0;
  }

  double get enteredAmount {
    String clean = amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(clean) ?? 0;
  }

  void _selectQuickAmount(int amt) {
    HapticFeedback.selectionClick();
    amountController.text = amt.toString();
    setState(() {});
  }

  void _selectAllBalance() {
    HapticFeedback.selectionClick();
    int bal = currentBalance.toInt();
    if (bal > 0) {
      amountController.text = bal.toString();
      setState(() {});
    } else {
      Get.snackbar('Perhatian', 'Saldo Anda saat ini Rp 0');
    }
  }

  void _confirmWithdraw() {
    double amt = enteredAmount;
    if (amt < 20000) {
      Get.snackbar('Nominal Kurang', 'Minimal penarikan dana adalah Rp 20.000',
          backgroundColor: Colors.orange.shade800, colorText: Colors.white);
      return;
    }

    if (amt > currentBalance) {
      Get.snackbar('Saldo Tidak Cukup', 'Saldo Anda saat ini: ${formatter.format(currentBalance)}',
          backgroundColor: Colors.red.shade800, colorText: Colors.white);
      return;
    }

    if (accountNumberController.text.trim().isEmpty) {
      Get.snackbar('Data Belum Lengkap', 'Nomor rekening atau nomor handphone e-wallet wajib diisi',
          backgroundColor: Colors.orange.shade800, colorText: Colors.white);
      return;
    }

    if (accountNameController.text.trim().isEmpty) {
      Get.snackbar('Data Belum Lengkap', 'Nama pemilik rekening / akun wajib diisi',
          backgroundColor: Colors.orange.shade800, colorText: Colors.white);
      return;
    }

    // Tampilkan Dialog Konfirmasi
    Get.defaultDialog(
      title: 'Konfirmasi Tarik Tunai',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pastikan data tujuan penarikan sudah benar:', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 14),
          _buildConfirmRow('Tujuan:', selectedBank),
          _buildConfirmRow('No. Rekening/HP:', accountNumberController.text.trim()),
          _buildConfirmRow('Atas Nama:', accountNameController.text.trim()),
          const Divider(),
          _buildConfirmRow('Nominal Tarik:', formatter.format(amt), isBold: true, color: AppTheme.primaryBlue),
          _buildConfirmRow('Biaya Admin:', 'Rp 0 (Gratis)', color: Colors.green),
          _buildConfirmRow('Total Diterima:', formatter.format(amt), isBold: true, color: Colors.green.shade800),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: const [
                Icon(Icons.info_outline, size: 16, color: Colors.amber),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Dana diproses ke rekening Anda maksimal 1x24 jam kerja.',
                      style: TextStyle(fontSize: 11, color: Colors.black87)),
                ),
              ],
            ),
          )
        ],
      ),
      textConfirm: 'Ya, Tarik Sekarang',
      textCancel: 'Batal',
      confirmTextColor: Colors.white,
      buttonColor: AppTheme.primaryBlue,
      onConfirm: () {
        Get.back(); // tutup dialog
        walletController.requestWithdraw(
          amount: amt,
          bankName: selectedBank,
          accountNumber: accountNumberController.text.trim(),
          accountName: accountNameController.text.trim(),
        );
      },
    );
  }

  Widget _buildConfirmRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                  color: color ?? Colors.black87)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Tarik Tunai Saldo', style: TextStyle(color: AppTheme.textMain, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textMain, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Kartu Saldo Pengguna
            _buildBalanceCard(),
            const SizedBox(height: 20),

            // 2. Input & Pilihan Nominal
            _buildAmountSection(),
            const SizedBox(height: 20),

            // 3. Pilihan Bank / E-Wallet
            _buildBankSelection(),
            const SizedBox(height: 20),

            // 4. Data Rekening / E-Wallet
            _buildAccountDataSection(),
            const SizedBox(height: 20),

            // 5. Ringkasan Biaya
            _buildSummaryCard(),
            const SizedBox(height: 24),

            // 6. Tombol Ajukan Tarik Tunai
            Obx(() {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: walletController.isWithdrawLoading.value ? null : _confirmWithdraw,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: walletController.isWithdrawLoading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Ajukan Tarik Tunai',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
              );
            }),
            const SizedBox(height: 28),

            // 7. Riwayat Penarikan Dana
            _buildWithdrawHistorySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Saldo MaiPay Tersedia', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  children: [
                    Icon(Icons.security, color: Colors.white, size: 13),
                    SizedBox(width: 4),
                    Text('Aman & Cepat', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 8),
          Obx(() {
            return Text(
              formatter.format(currentBalance),
              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
            );
          }),
          const SizedBox(height: 12),
          const Text('Minimal pencairan dana Rp 20.000 ke semua rekening & dompet digital.',
              style: TextStyle(color: Colors.white70, fontSize: 11.5)),
        ],
      ),
    );
  }

  Widget _buildAmountSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Nominal Penarikan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              GestureDetector(
                onTap: _selectAllBalance,
                child: const Text('Tarik Semua Saldo',
                    style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // TextField Nominal
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
            decoration: InputDecoration(
              prefixText: 'Rp ',
              prefixStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
              hintText: '20.000',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),

          // Pilihan Cepat Nominal
          Wrap(
            spacing: 8,
            children: quickAmounts.map((amt) {
              bool isSelected = enteredAmount.toInt() == amt;
              return ChoiceChip(
                label: Text(formatter.format(amt), style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                selected: isSelected,
                onSelected: (_) => _selectQuickAmount(amt),
                selectedColor: AppTheme.primaryBlue.withValues(alpha: 0.15),
                labelStyle: TextStyle(color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade800),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBankSelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tujuan Pencairan (Bank / E-Wallet)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: selectedBank,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: bankOptions.map((b) {
              return DropdownMenuItem<String>(
                value: b['name'] as String,
                child: Row(
                  children: [
                    Icon(b['icon'] as IconData, size: 18, color: AppTheme.primaryBlue),
                    const SizedBox(width: 8),
                    Text(b['name'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Text('(${b['type']})', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => selectedBank = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountDataSection() {
    bool isEwallet = selectedBank == 'DANA' || selectedBank == 'GoPay' || selectedBank == 'OVO' || selectedBank == 'ShopeePay' || selectedBank == 'LinkAja';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEwallet ? 'Informasi Akun $selectedBank' : 'Informasi Rekening $selectedBank',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),

          // Nomor Rekening / HP
          Text(
            isEwallet ? 'Nomor Handphone Terdaftar di $selectedBank' : 'Nomor Rekening',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: accountNumberController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: isEwallet ? 'Contoh: 081234567890' : 'Contoh: 1234567890',
              prefixIcon: Icon(isEwallet ? Icons.phone_android : Icons.numbers, size: 18, color: Colors.grey),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 14),

          // Nama Pemilik Rekening
          const Text('Nama Pemilik Rekening / Akun', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 6),
          TextField(
            controller: accountNameController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'Sesuai buku tabungan / nama di aplikasi',
              prefixIcon: const Icon(Icons.person_outline, size: 18, color: Colors.grey),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    double amt = enteredAmount;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Nominal Penarikan:', style: TextStyle(fontSize: 13, color: Colors.black54)),
              Text(formatter.format(amt), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Biaya Admin:', style: TextStyle(fontSize: 13, color: Colors.black54)),
              Text('Rp 0 (Gratis Promo)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total yang Diterima:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              Text(formatter.format(amt), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawHistorySection() {
    return Obx(() {
      if (walletController.withdrawHistory.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Riwayat Penarikan Dana', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          ...walletController.withdrawHistory.map((item) {
            String status = (item['status'] ?? 'pending').toString().toLowerCase();
            Color statusColor = Colors.orange;
            String statusText = 'Diproses';

            if (status == 'approved') {
              statusColor = Colors.green;
              statusText = 'Berhasil Ditransfer';
            } else if (status == 'rejected') {
              statusColor = Colors.red;
              statusText = 'Ditolak';
            }

            int amt = int.tryParse(item['amount']?.toString() ?? '0') ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.account_balance, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item['bank_name']} - ${item['account_number']}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'a.n ${item['account_name']}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                        Text(
                          item['created_at'] != null ? item['created_at'].toString().split(' ')[0] : '',
                          style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(formatter.format(amt), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      );
    });
  }
}
