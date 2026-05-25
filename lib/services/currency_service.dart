// lib/services/currency_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  static Future<double> fetchRate(String from, String to) async {
    final uri =
        Uri.parse('https://api.exchangerate.host/convert?from=$from&to=$to');
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      if (data['result'] != null) {
        return (data['result'] as num).toDouble();
      }
    }
    // Fallback to 1.0 if API fails
    return 1.0;
  }
}
