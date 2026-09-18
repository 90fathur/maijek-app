import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import 'topup_view.dart';

class InsufficientBalanceSheet extends StatelessWidget {
  final double currentBalance;
  final double requiredAmount;
  final VoidCallback onPayCash;

  const InsufficientBalanceSheet({
    super.key,
    required this.currentBalance,
    required this.requiredAmount,
    required this.onPayCash,
  });

  static void show({
    required double currentBalance,
    required double requiredAmount,
    required VoidCallback onPayCash,
  }) {
    Get.bottomSheet(
      InsufficientBalanceSheet(
        currentBalance: currentBalance,
        requiredAmount: requiredAmount,
        onPayCash: onPayCash,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final double deficit = (requiredAmount - currentBalance).clamp(0, double.infinity);

    // Hitung rekomendasi top-up (minimal 10.000, kelipatan 10.000 terdekat ke atas)
    int recommendedTopUp = 10000;
    if (deficit > 10000) {
      recommendedTopUp = ((deficit / 10000).ceil()) * 10000;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header Icon & Title
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.account_balance_wallet_outlined, color: Colors.orange.shade800, size: 36),
          ),
          const SizedBox(height: 12),
          const Text(
            'Saldo Mai-Pay Kurang',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain),
          ),
          const SizedBox(height: 6),
          Text(
            'Saldo dompet Anda tidak cukup untuk membayar pesanan ini.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),

          // Comparison Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _buildRow('Saldo Mai-Pay Anda', currency.format(currentBalance)),
                const SizedBox(height: 8),
                _buildRow('Total Biaya Pesanan', currency.format(requiredAmount), isBold: true),
                const Divider(height: 20),
                _buildRow(
                  'Kekurangan Saldo',
                  '-${currency.format(deficit)}',
                  isBold: true,
                  valueColor: Colors.red.shade700,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action 1: Top Up Sekarang (Primary Button)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Get.back(); // Tutup bottom sheet
                Get.to(() => TopUpView(initialAmount: recommendedTopUp));
              },
              icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
              label: Text(
                'Isi Saldo Cepat (${currency.format(recommendedTopUp)})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Action 2: Ganti ke Tunai (Secondary Button)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                Get.back(); // Tutup bottom sheet
                onPayCash(); // Jalankan pesanan dengan tunai
              },
              icon: Icon(Icons.payments_outlined, color: Colors.green.shade700, size: 20),
              label: Text(
                'Beralih ke Bayar Tunai Saja',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Colors.green.shade800),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.green.shade400, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? AppTheme.textMain,
          ),
        ),
      ],
    );
  }
}
