import 'package:intl/intl.dart';


class Formatter {
  static String currency(dynamic amount) {
    if (amount == null) return 'Rp. 0';
    double parsedAmount = 0.0;
    if (amount is int) {
      parsedAmount = amount.toDouble();
    } else if (amount is double) {
      parsedAmount = amount;
    } else if (amount is String) {
      parsedAmount = double.tryParse(amount) ?? 0.0;
    }
    final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp. ', decimalDigits: 0);
    return formatter.format(parsedAmount);
  }
}
