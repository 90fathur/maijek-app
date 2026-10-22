import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/api_client.dart';
import '../../controllers/wallet_controller.dart';
import '../../controllers/auth_controller.dart';
import 'qris_payment_sheet.dart';

class TopUpView extends StatefulWidget {
  final int? initialAmount;
  const TopUpView({super.key, this.initialAmount});

  @override
  State<TopUpView> createState() => _TopUpViewState();
}

class _TopUpViewState extends State<TopUpView> {
  int selectedAmount = 0;
  final TextEditingController amountController = TextEditingController();
  final walletController = Get.find<WalletController>();
  bool isLoadingQris = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialAmount != null && widget.initialAmount! > 0) {
      selectedAmount = widget.initialAmount!;
      amountController.text = widget.initialAmount.toString();
    }
  }

  void selectAmount(int amount) {
    setState(() {
      selectedAmount = amount;
      amountController.text = amount.toString();
    });
  }

  Future<void> requestTopUp() async {
    int amount = int.tryParse(amountController.text.replaceAll('.', '')) ?? 0;
    
    if (amount < 5000) {
      Get.snackbar('Nominal Kurang', 'Minimal top-up Rp 5.000', backgroundColor: Colors.red.shade700, colorText: Colors.white);
      return;
    }

    setState(() => isLoadingQris = true);
    try {
      final res = await ApiClient.post('/user/topup/createNotivgoQris', {
        'amount': amount,
      });

      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['status'] == 200 && body['data'] != null) {
        final d = body['data'];
        if (!mounted) return;
        QrisPaymentSheet.show(
          context: context,
          orderRef: d['order_ref'],
          amount: double.tryParse(d['amount'].toString()) ?? amount.toDouble(),
          qrisImageBase64: d['qris_image_base64'],
          qrisPayload: d['qris_payload'],
          expiresAt: d['expires_at'],
          checkEndpoint: '/user/topup/checkNotivgoStatus',
          title: 'Top Up QRIS NotivGo',
          onSuccess: () async {
            await walletController.fetchHistory();
            if (Get.isRegistered<AuthController>()) {
              Get.find<AuthController>().fetchProfile();
            }
            Get.back();
            Get.snackbar(
              'Top Up Berhasil! 💰',
              'Saldo Mai-Pay Anda sebesar ${Formatter.currency(amount)} telah ditambahkan.',
              backgroundColor: Colors.green,
              colorText: Colors.white,
              duration: const Duration(seconds: 4),
            );
          },
        );
      } else {
        Get.snackbar('Gagal', body['message'] ?? 'Gagal membuat QRIS Top Up', backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Terjadi kesalahan jaringan: $e', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => isLoadingQris = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Top Up Saldo'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pilih Nominal Top Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.5,
                    children: [
                      _buildAmountOption(10000, '10.000'),
                      _buildAmountOption(20000, '20.000'),
                      _buildAmountOption(50000, '50.000'),
                      _buildAmountOption(100000, '100.000'),
                      _buildAmountOption(200000, '200.000'),
                      _buildAmountOption(500000, '500.000'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Atau masukkan nominal lain', style: TextStyle(fontSize: 14, color: AppTheme.textMuted)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      setState(() {
                        selectedAmount = int.tryParse(val) ?? 0;
                      });
                    },
                    decoration: InputDecoration(
                      prefixText: 'Rp. ',
                      hintText: 'Minimal Rp 5.000',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  if (selectedAmount >= 5000) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFBAE6FD)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Nominal Saldo', style: TextStyle(fontSize: 13, color: Colors.black87)),
                              Text(Formatter.currency(selectedAmount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Biaya Layanan Gateway', style: TextStyle(fontSize: 13, color: Colors.black87)),
                              Text('GRATIS (Rp 0)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Pembayaran', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
                              Text(
                                Formatter.currency(selectedAmount),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '*Saldo Mai-Pay Anda akan bertambah instan 100% penuh.',
                            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Metode Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE).withOpacity(0.4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBAE6FD)),
                          ),
                          child: const Icon(Icons.qr_code_2, color: Color(0xFF0284C7), size: 28),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('QRIS Instan (NotivGo)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                  SizedBox(width: 6),
                                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Scan instan via BCA, Mandiri, BRI, BNI, GoPay, OVO, DANA, ShopeePay, dll.',
                                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoadingQris ? null : requestTopUp,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0284C7),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: isLoadingQris 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(
                  selectedAmount >= 5000 
                      ? 'Bayar ${Formatter.currency(selectedAmount)} via QRIS'
                      : 'Bayar via QRIS', 
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
                ),
        ),
      ),
    );
  }

  Widget _buildAmountOption(int amount, String label) {
    bool isSelected = selectedAmount == amount;
    return GestureDetector(
      onTap: () => selectAmount(amount),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue.withOpacity(0.1) : Colors.white,
          border: Border.all(color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isSelected ? AppTheme.primaryBlue : Colors.black87
        )),
      ),
    );
  }
}
