import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/app_logger.dart';
import '../models/company_details.dart';

class CompanyDetailsService {
  static const String _storageKey = 'company_details';

  Future<CompanyDetails> loadCompanyDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return CompanyDetails.fromJson(json);
      }
    } catch (e) {
      AppLogger.error('Error loading company details: $e', tag: 'Settings');
    }

    // Return default values
    return CompanyDetails();
  }

  Future<void> saveCompanyDetails(CompanyDetails details) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(details.toJson());
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      AppLogger.error('Error saving company details: $e', tag: 'Settings');
      rethrow;
    }
  }

  Future<void> clearCompanyDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      AppLogger.error('Error clearing company details: $e', tag: 'Settings');
    }
  }
}
