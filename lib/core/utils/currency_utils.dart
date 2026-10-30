import 'package:intl/intl.dart';

class CurrencyUtils {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'it_IT',
    symbol: '€',
    decimalDigits: 2,
  );

  static final NumberFormat _compactFormatter = NumberFormat.currency(
    locale: 'it_IT',
    symbol: '€',
    decimalDigits: 0,
  );

  /// Formatta un importo con due cifre decimali (es. 24,50 €)
  static String format(double amount) {
    return _formatter.format(amount);
  }

  /// Formatta un importo senza decimali per grafici o anteprime (es. 25 €)
  static String formatCompact(double amount) {
    return _compactFormatter.format(amount);
  }
}
