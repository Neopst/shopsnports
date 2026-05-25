import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class GeolocationService {
  /// Requests permission and returns the ISO country code (e.g. 'US') or null.
  static Future<String?> getCountryCode() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    // Use desiredAccuracy directly (geolocator 9.x API)
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
    );

    final placemarks =
        await placemarkFromCoordinates(pos.latitude, pos.longitude);
    if (placemarks.isNotEmpty) {
      return placemarks.first.isoCountryCode;
    }
    return null;
  }

  /// Map country code to currency code (extend as needed)
  static String currencyForCountry(String? countryCode) {
    switch (countryCode) {
      case 'US':
        return 'USD';
      case 'GB':
        return 'GBP';
      case 'FR':
      case 'DE':
      case 'ES':
      case 'IT':
        return 'EUR';
      case 'NG':
        return 'NGN';
      case 'IN':
        return 'INR';
      default:
        return 'USD';
    }
  }

  Future<Position> getCurrentLocation() async {
    // Use desiredAccuracy directly (geolocator 9.x API)
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
