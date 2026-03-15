import 'package:intl/intl.dart';

class CurrencyHelper {
  static const Map<String, Map<String, String>> currencies = {
    // Major currencies
    'USD': {'symbol': '\$', 'name': 'US Dollar'},
    'EUR': {'symbol': '€', 'name': 'Euro'},
    'GBP': {'symbol': '£', 'name': 'British Pound'},
    'JPY': {'symbol': '¥', 'name': 'Japanese Yen'},
    'CHF': {'symbol': 'CHF', 'name': 'Swiss Franc'},
    'CAD': {'symbol': 'CA\$', 'name': 'Canadian Dollar'},
    'AUD': {'symbol': 'A\$', 'name': 'Australian Dollar'},
    'NZD': {'symbol': 'NZ\$', 'name': 'New Zealand Dollar'},
    'CNY': {'symbol': '¥', 'name': 'Chinese Yuan'},
    'HKD': {'symbol': 'HK\$', 'name': 'Hong Kong Dollar'},
    'SGD': {'symbol': 'S\$', 'name': 'Singapore Dollar'},
    // European
    'SEK': {'symbol': 'kr', 'name': 'Swedish Krona'},
    'NOK': {'symbol': 'kr', 'name': 'Norwegian Krone'},
    'DKK': {'symbol': 'kr', 'name': 'Danish Krone'},
    'PLN': {'symbol': 'zł', 'name': 'Polish Zloty'},
    'CZK': {'symbol': 'Kč', 'name': 'Czech Koruna'},
    'HUF': {'symbol': 'Ft', 'name': 'Hungarian Forint'},
    'RON': {'symbol': 'lei', 'name': 'Romanian Leu'},
    'BGN': {'symbol': 'лв', 'name': 'Bulgarian Lev'},
    'HRK': {'symbol': 'kn', 'name': 'Croatian Kuna'},
    'ISK': {'symbol': 'kr', 'name': 'Icelandic Króna'},
    'RUB': {'symbol': '₽', 'name': 'Russian Ruble'},
    'UAH': {'symbol': '₴', 'name': 'Ukrainian Hryvnia'},
    'TRY': {'symbol': '₺', 'name': 'Turkish Lira'},
    'GEL': {'symbol': '₾', 'name': 'Georgian Lari'},
    // Americas
    'BRL': {'symbol': 'R\$', 'name': 'Brazilian Real'},
    'MXN': {'symbol': 'MX\$', 'name': 'Mexican Peso'},
    'ARS': {'symbol': 'AR\$', 'name': 'Argentine Peso'},
    'CLP': {'symbol': 'CL\$', 'name': 'Chilean Peso'},
    'COP': {'symbol': 'CO\$', 'name': 'Colombian Peso'},
    'PEN': {'symbol': 'S/', 'name': 'Peruvian Sol'},
    'UYU': {'symbol': '\$U', 'name': 'Uruguayan Peso'},
    'DOP': {'symbol': 'RD\$', 'name': 'Dominican Peso'},
    'JMD': {'symbol': 'J\$', 'name': 'Jamaican Dollar'},
    'TTD': {'symbol': 'TT\$', 'name': 'Trinidad Dollar'},
    // Asia & Pacific
    'KRW': {'symbol': '₩', 'name': 'South Korean Won'},
    'INR': {'symbol': '₹', 'name': 'Indian Rupee'},
    'PKR': {'symbol': '₨', 'name': 'Pakistani Rupee'},
    'LKR': {'symbol': 'Rs', 'name': 'Sri Lankan Rupee'},
    'BDT': {'symbol': '৳', 'name': 'Bangladeshi Taka'},
    'THB': {'symbol': '฿', 'name': 'Thai Baht'},
    'VND': {'symbol': '₫', 'name': 'Vietnamese Dong'},
    'MYR': {'symbol': 'RM', 'name': 'Malaysian Ringgit'},
    'IDR': {'symbol': 'Rp', 'name': 'Indonesian Rupiah'},
    'PHP': {'symbol': '₱', 'name': 'Philippine Peso'},
    'TWD': {'symbol': 'NT\$', 'name': 'Taiwan Dollar'},
    'MMK': {'symbol': 'K', 'name': 'Myanmar Kyat'},
    'KHR': {'symbol': '៛', 'name': 'Cambodian Riel'},
    'NPR': {'symbol': 'Rs', 'name': 'Nepalese Rupee'},
    // Middle East
    'AED': {'symbol': 'د.إ', 'name': 'UAE Dirham'},
    'SAR': {'symbol': '﷼', 'name': 'Saudi Riyal'},
    'QAR': {'symbol': 'QR', 'name': 'Qatari Riyal'},
    'KWD': {'symbol': 'د.ك', 'name': 'Kuwaiti Dinar'},
    'BHD': {'symbol': 'BD', 'name': 'Bahraini Dinar'},
    'OMR': {'symbol': 'ر.ع.', 'name': 'Omani Rial'},
    'JOD': {'symbol': 'JD', 'name': 'Jordanian Dinar'},
    'ILS': {'symbol': '₪', 'name': 'Israeli Shekel'},
    'EGP': {'symbol': 'E£', 'name': 'Egyptian Pound'},
    'LBP': {'symbol': 'L£', 'name': 'Lebanese Pound'},
    'IQD': {'symbol': 'ع.د', 'name': 'Iraqi Dinar'},
    'IRR': {'symbol': '﷼', 'name': 'Iranian Rial'},
    // Africa
    'ZAR': {'symbol': 'R', 'name': 'South African Rand'},
    'NGN': {'symbol': '₦', 'name': 'Nigerian Naira'},
    'KES': {'symbol': 'KSh', 'name': 'Kenyan Shilling'},
    'GHS': {'symbol': 'GH₵', 'name': 'Ghanaian Cedi'},
    'TZS': {'symbol': 'TSh', 'name': 'Tanzanian Shilling'},
    'UGX': {'symbol': 'USh', 'name': 'Ugandan Shilling'},
    'ETB': {'symbol': 'Br', 'name': 'Ethiopian Birr'},
    'MAD': {'symbol': 'MAD', 'name': 'Moroccan Dirham'},
    'TND': {'symbol': 'DT', 'name': 'Tunisian Dinar'},
    'DZD': {'symbol': 'د.ج', 'name': 'Algerian Dinar'},
    'XOF': {'symbol': 'CFA', 'name': 'West African CFA Franc'},
    'XAF': {'symbol': 'FCFA', 'name': 'Central African CFA Franc'},
    'RWF': {'symbol': 'RF', 'name': 'Rwandan Franc'},
  };

  static String getSymbol(String code) {
    return currencies[code]?['symbol'] ?? code;
  }

  static String getName(String code) {
    return currencies[code]?['name'] ?? code;
  }

  static NumberFormat formatter(String currencyCode) {
    final symbol = getSymbol(currencyCode);
    final noDecimals = {'JPY', 'KRW', 'VND', 'IDR', 'HUF', 'CLP', 'ISK', 'UGX', 'KHR', 'MMK', 'RWF', 'XOF', 'XAF', 'IQD', 'IRR', 'LBP'};
    return NumberFormat.currency(
      symbol: '$symbol ',
      decimalDigits: noDecimals.contains(currencyCode) ? 0 : 2,
    );
  }
}
