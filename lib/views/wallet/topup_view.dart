import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../controllers/wallet_controller.dart';

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
    
    if (amount < 10000) {
      Get.snackbar('Error', 'Minimal top-up Rp 10.000', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    await walletController.topUp(amount.toDouble());
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
                      hintText: 'Minimal Rp 10.000',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  if (selectedAmount >= 10000) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryNavy.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.primaryNavy.withValues(alpha: 0.15)),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Biaya Layanan (0,9%)', style: TextStyle(fontSize: 13, color: Colors.black87)),
                              Text(Formatter.currency((selectedAmount * 0.009).ceil()), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange)),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Pembayaran', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy)),
                              Text(
                                Formatter.currency(selectedAmount + (selectedAmount * 0.009).ceil()),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '*Saldo Mai-Pay Anda akan bertambah utuh sesuai nominal saldo.',
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
                      color: AppTheme.primaryNavy.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.primaryNavy.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: const Icon(Icons.qr_code_scanner, color: AppTheme.primaryNavy, size: 28),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('QRIS Otomatis', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
        child: Obx(() => ElevatedButton(
          onPressed: walletController.isTopUpLoading.value ? null : requestTopUp,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: walletController.isTopUpLoading.value 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
              : Text(
                  selectedAmount >= 10000 
                      ? 'Bayar ${Formatter.currency(selectedAmount + (selectedAmount * 0.009).ceil())} via QRIS'
                      : 'Bayar via QRIS', 
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
                ),
        )),
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
