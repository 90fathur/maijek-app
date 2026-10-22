import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';

class QrisPaymentSheet extends StatefulWidget {
  final String orderRef;
  final double amount;
  final String? qrisImageBase64;
  final String? qrisPayload;
  final int? expiresAt;
  final String checkEndpoint; // e.g. '/user/topup/checkNotivgoStatus/' or '/user/orders/checkQrisStatus/'
  final VoidCallback onSuccess;
  final String title;

  const QrisPaymentSheet({
    super.key,
    required this.orderRef,
    required this.amount,
    this.qrisImageBase64,
    this.qrisPayload,
    this.expiresAt,
    required this.checkEndpoint,
    required this.onSuccess,
    this.title = 'Pembayaran QRIS',
  });

  static Future<void> show({
    required BuildContext context,
    required String orderRef,
    required double amount,
    String? qrisImageBase64,
    String? qrisPayload,
    int? expiresAt,
    required String checkEndpoint,
    required VoidCallback onSuccess,
    String title = 'Pembayaran QRIS',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QrisPaymentSheet(
        orderRef: orderRef,
        amount: amount,
        qrisImageBase64: qrisImageBase64,
        qrisPayload: qrisPayload,
        expiresAt: expiresAt,
        checkEndpoint: checkEndpoint,
        onSuccess: onSuccess,
        title: title,
      ),
    );
  }

  @override
  State<QrisPaymentSheet> createState() => _QrisPaymentSheetState();
}

class _QrisPaymentSheetState extends State<QrisPaymentSheet> {
  Timer? _pollingTimer;
  Timer? _countdownTimer;
  int _secondsLeft = 900;
  bool _isChecking = false;
  bool _isPaid = false;
  Uint8List? _qrBytes;

  @override
  void initState() {
    super.initState();
    _decodeImage();
    _initCountdown();
    _startPolling();
  }

  void _decodeImage() {
    if (widget.qrisImageBase64 != null && widget.qrisImageBase64!.isNotEmpty) {
      try {
        String clean = widget.qrisImageBase64!.replaceFirst(RegExp(r'data:image/[^;]+;base64,'), '');
        setState(() {
          _qrBytes = base64Decode(clean);
        });
      } catch (e) {
        debugPrint('Error decoding QRIS image: $e');
      }
    }
  }

  void _initCountdown() {
    if (widget.expiresAt != null && widget.expiresAt! > 0) {
      int nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      int diff = widget.expiresAt! - nowSeconds;
      _secondsLeft = diff > 0 ? diff : 900;
    } else {
      _secondsLeft = 900;
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_isChecking && !_isPaid) {
        _checkStatus(isAuto: true);
      }
    });
  }

  Future<void> _checkStatus({bool isAuto = false}) async {
    if (!mounted || _isChecking || _isPaid) return;

    if (!isAuto) {
      setState(() => _isChecking = true);
    }

    try {
      String url = widget.checkEndpoint;
      if (!url.endsWith('/')) url += '/';
      url += widget.orderRef;

      final res = await ApiClient.get(url);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map && (body['paid'] == true || body['data']?['status'] == 'success' || body['data']?['payment_status'] == 'paid')) {
          _pollingTimer?.cancel();
          _countdownTimer?.cancel();
          if (mounted) {
            setState(() {
              _isPaid = true;
              _isChecking = false;
            });
          }
          await Future.delayed(const Duration(milliseconds: 1200));
          if (mounted) {
            Get.back();
            widget.onSuccess();
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Check QRIS status error: $e');
    } finally {
      if (mounted && !isAuto) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.qr_code_2, color: Color(0xFF0284C7), size: 24),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Text('QRIS Standar Nasional (Bank & E-Wallet)', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Get.back(),
              )
            ],
          ),
          const Divider(height: 24),

          if (_isPaid) ...[
            // Status Sukses
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 72),
                  const SizedBox(height: 16),
                  const Text('Pembayaran Berhasil! 🎉', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 8),
                  Text('Pembayaran sebesar ${Formatter.currency(widget.amount)} telah diterima.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                ],
              ),
            ),
          ] else ...[
            // Nominal Pembayaran & Timer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Pembayaran', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      Text(Formatter.currency(widget.amount), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _secondsLeft < 180 ? Colors.red.shade50 : Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _secondsLeft < 180 ? Colors.red.shade200 : Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 14, color: _secondsLeft < 180 ? Colors.red.shade700 : Colors.amber.shade800),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(_secondsLeft),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _secondsLeft < 180 ? Colors.red.shade700 : Colors.amber.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // QR Code Container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  if (_qrBytes != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        _qrBytes!,
                        width: 210,
                        height: 210,
                        fit: BoxFit.contain,
                      ),
                    )
                  else
                    Container(
                      width: 210,
                      height: 210,
                      color: Colors.grey.shade100,
                      child: const Center(
                        child: CircularProgressIndicator(color: Color(0xFF0284C7)),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Ref: ${widget.orderRef}',
                    style: const TextStyle(fontSize: 10.5, color: Colors.grey, fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Panduan Singkat
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Color(0xFF15803D)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Buka m-Banking atau E-Wallet (BCA, BRI, Mandiri, Dana, GoPay, OVO, ShopeePay, dll) lalu scan QRIS di atas.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF15803D), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Tombol Aksi
            Row(
              children: [
                if (widget.qrisPayload != null && widget.qrisPayload!.isNotEmpty)
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: widget.qrisPayload!));
                        Get.snackbar('Disalin', 'Kode QRIS payload berhasil disalin ke clipboard', backgroundColor: Colors.grey.shade800, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Icon(Icons.copy, size: 18),
                    ),
                  ),
                if (widget.qrisPayload != null && widget.qrisPayload!.isNotEmpty)
                  const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed: _isChecking ? null : () => _checkStatus(isAuto: false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isChecking
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.refresh, size: 16),
                              SizedBox(width: 6),
                              Text('Cek Status Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
