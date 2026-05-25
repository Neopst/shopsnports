import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Storage service for app data using SharedPreferences
///
/// Note: For highly sensitive data in production, consider using
/// flutter_secure_storage. This implementation uses SharedPreferences
/// which is suitable for non-critical data like tokens with short expiry.
class SecureStorageService {
  static final SecureStorageService _instance =
      SecureStorageService._internal();
  static SecureStorageService get instance => _instance;

  SecureStorageService._internal();

  SharedPreferences? _prefs;

  Future<void> _ensureInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Keys for stored values
  static const String _authTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _apiKeyKey = 'api_key';

  /// Save authentication token
  Future<void> saveAuthToken(String token) async {
    try {
      await _ensureInitialized();
      await _prefs!.setString(_authTokenKey, token);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving auth token: $e');
      }
    }
  }

  /// Get authentication token
  Future<String?> getAuthToken() async {
    try {
      await _ensureInitialized();
      return _prefs!.getString(_authTokenKey);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error reading auth token: $e');
      }
      return null;
    }
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    try {
      await _ensureInitialized();
      await _prefs!.setString(_refreshTokenKey, token);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving refresh token: $e');
      }
    }
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    try {
      await _ensureInitialized();
      return _prefs!.getString(_refreshTokenKey);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error reading refresh token: $e');
      }
      return null;
    }
  }

  /// Save user ID
  Future<void> saveUserId(String userId) async {
    try {
      await _ensureInitialized();
      await _prefs!.setString(_userIdKey, userId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving user ID: $e');
      }
    }
  }

  /// Get user ID
  Future<String?> getUserId() async {
    try {
      await _ensureInitialized();
      return _prefs!.getString(_userIdKey);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error reading user ID: $e');
      }
      return null;
    }
  }

  /// Save API key (if needed for certain operations)
  Future<void> saveApiKey(String apiKey) async {
    try {
      await _ensureInitialized();
      await _prefs!.setString(_apiKeyKey, apiKey);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving API key: $e');
      }
    }
  }

  /// Get API key
  Future<String?> getApiKey() async {
    try {
      await _ensureInitialized();
      return _prefs!.getString(_apiKeyKey);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error reading API key: $e');
      }
      return null;
    }
  }

  /// Save custom value
  Future<void> saveValue(String key, String value) async {
    try {
      await _ensureInitialized();
      await _prefs!.setString(key, value);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving value for key $key: $e');
      }
    }
  }

  /// Get custom value
  Future<String?> getValue(String key) async {
    try {
      await _ensureInitialized();
      return _prefs!.getString(key);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error reading value for key $key: $e');
      }
      return null;
    }
  }

  /// Delete specific value
  Future<void> deleteValue(String key) async {
    try {
      await _ensureInitialized();
      await _prefs!.remove(key);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting value for key $key: $e');
      }
    }
  }

  /// Clear all stored values (use on logout)
  Future<void> clearAll() async {
    try {
      await _ensureInitialized();
      await _prefs!.clear();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error clearing storage: $e');
      }
    }
  }

  /// Check if a key exists
  Future<bool> containsKey(String key) async {
    try {
      await _ensureInitialized();
      return _prefs!.containsKey(key);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking key existence: $e');
      }
      return false;
    }
  }
}
