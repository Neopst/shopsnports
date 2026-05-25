import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopsnports/services/currency_service.dart';
import 'package:shopsnports/services/geolocation_service.dart';
import 'package:shopsnports/providers/geolocation_provider.dart';

class CurrencyState {
  final String code;
  final double rate;
  const CurrencyState({this.code = 'NGN', this.rate = 1.0});

  CurrencyState copyWith({String? code, double? rate}) => CurrencyState(
        code: code ?? this.code,
        rate: rate ?? this.rate,
      );
}

class CurrencyNotifier extends StateNotifier<CurrencyState> {
  CurrencyNotifier(this.ref) : super(const CurrencyState());

  final Ref ref;

  static const _prefsKey = 'selected_currency';

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved != null && saved.isNotEmpty) {
        final rate = await CurrencyService.fetchRate('NGN', saved);
        state = state.copyWith(code: saved, rate: rate);
        return;
      }

      // No saved preference — attempt to derive from geolocation provider
      final geo = ref.read(geolocationProvider);
      String? country;
      if (geo.position != null) {
        country = await GeolocationService.getCountryCode();
      } else {
        // fallback to device locale handled by caller if needed
        country = null;
      }
      final currency = GeolocationService.currencyForCountry(country);
      final rate = await CurrencyService.fetchRate('NGN', currency);
      state = state.copyWith(code: currency, rate: rate);
    } catch (_) {
      // ignore and keep defaults
    }
  }

  Future<void> setCurrency(String code) async {
    try {
      final rate = await CurrencyService.fetchRate('NGN', code);
      state = state.copyWith(code: code, rate: rate);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, code);
    } catch (_) {
      // fallback: update only code
      state = state.copyWith(code: code);
    }
  }

  /// Sets currency code only without fetching or persisting. Useful for
  /// fallbacks where network calls are undesirable. This updates the in-memory
  /// state only. Use sparingly.
  void setCodeOnly(String code) {
    state = state.copyWith(code: code);
  }
}

final currencyProvider = StateNotifierProvider<CurrencyNotifier, CurrencyState>(
    (ref) => CurrencyNotifier(ref));
