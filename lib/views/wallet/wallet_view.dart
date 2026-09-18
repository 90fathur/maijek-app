import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/wallet_controller.dart';
import 'topup_view.dart';
import 'withdraw_view.dart';

class WalletView extends StatefulWidget {
  const WalletView({super.key});

  @override
  State<WalletView> createState() => _WalletViewState();
}

class _WalletViewState extends State<WalletView> {
  final authController = Get.find<AuthController>();
  final walletController = Get.put(WalletController());

  @override
  void initState() {
    super.initState();
    authController.fetchProfile();
    walletController.fetchHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('MaiPay'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {},
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await authController.fetchProfile();
          await walletController.fetchHistory();
        },
        color: AppTheme.primaryBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildWalletCard(),
              const SizedBox(height: 24),
              _buildTransactionHistory(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Saldo Aktif',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Premium', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 8),
          Obx(() {
            final bal = authController.userData['balance'] ?? 0;
            final formatted = 'Rp. ${bal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
            return Text(
              formatted,
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            );
          }),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWalletAction(Icons.add_card, 'Top Up', () => Get.to(() => const TopUpView())),
              _buildWalletAction(Icons.send, 'Transfer', () {
                Get.snackbar('Fitur Segera Hadir', 'Fitur Transfer Saldo antar pengguna sedang dalam pengembangan');
              }),
              _buildWalletAction(Icons.account_balance, 'Tarik Tunai', () => Get.to(() => const WithdrawView())),
              _buildWalletAction(Icons.history, 'Riwayat', () {
                walletController.fetchHistory();
                Get.snackbar('Riwayat Diperbarui', 'Memuat mutasi transaksi terbaru');
              }),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildWalletAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          )
        ],
      ),
    );
  }

  Widget _buildTransactionHistory() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Transaksi Terakhir',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain),
              ),
              TextButton(
                onPressed: () {
                  walletController.fetchHistory();
                },
                child: const Text('Refresh', style: TextStyle(color: AppTheme.primaryBlue)),
              )
            ],
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (walletController.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (walletController.transactions.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('Belum ada transaksi', style: TextStyle(color: Colors.grey)),
                )
              );
            }
            
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: walletController.transactions.length,
              itemBuilder: (context, index) {
                var tx = walletController.transactions[index];
                bool isIncome = tx['type'] == 'credit';
                String amount = 'Rp. ${tx['amount'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
                
                // Format date roughly (should use intl package in real scenario)
                String date = tx['created_at'] ?? '';
                
                return _buildTransactionItem(
                  tx['description'] ?? (isIncome ? 'Pemasukan' : 'Pengeluaran'),
                  date,
                  amount,
                  isIncome
                );
              },
            );
          }),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(String title, String date, String amount, bool isIncome) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isIncome ? AppTheme.success.withOpacity(0.1) : AppTheme.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: isIncome ? AppTheme.success : AppTheme.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(date, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}$amount',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isIncome ? AppTheme.success : AppTheme.textMain,
            ),
          )
        ],
      ),
    );
  }
}
