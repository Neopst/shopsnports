/// Firebase Authentication configuration
/// Handles all auth-related settings including security policies
class AuthConfig {
  final String? firebaseProjectId;
  final String? firebaseApiKey;
  final String? firebaseAuthDomain;
  final String? firebaseAppId;
  final Duration tokenRefreshInterval;
  final Duration sessionTimeout;
  final int maxLoginAttempts;
  final Duration lockoutDuration;
  final bool enableTwoFactor;
  final bool requireEmailVerification;
  final bool requirePhoneVerification;
  final int passwordMinLength;
  final bool passwordRequireUppercase;
  final bool passwordRequireNumbers;
  final bool passwordRequireSpecialChars;
  final bool enableBiometric;
  final Duration inactivityLockout;

  AuthConfig({
    this.firebaseProjectId,
    this.firebaseApiKey,
    this.firebaseAuthDomain,
    this.firebaseAppId,
    required this.tokenRefreshInterval,
    required this.sessionTimeout,
    required this.maxLoginAttempts,
    required this.lockoutDuration,
    required this.enableTwoFactor,
    required this.requireEmailVerification,
    required this.requirePhoneVerification,
    required this.passwordMinLength,
    required this.passwordRequireUppercase,
    required this.passwordRequireNumbers,
    required this.passwordRequireSpecialChars,
    required this.enableBiometric,
    required this.inactivityLockout,
  });

  factory AuthConfig.development() {
    return AuthConfig(
      firebaseProjectId: 'admin-dashboard-dev',
      firebaseApiKey: 'dev-api-key',
      firebaseAuthDomain: 'admin-dashboard-dev.firebaseapp.com',
      firebaseAppId: 'dev-app-id',
      tokenRefreshInterval: const Duration(hours: 23),
      sessionTimeout: const Duration(hours: 24),
      maxLoginAttempts: 10, // More lenient in dev
      lockoutDuration: const Duration(minutes: 5),
      enableTwoFactor: false,
      requireEmailVerification: false,
      requirePhoneVerification: false,
      passwordMinLength: 6,
      passwordRequireUppercase: false,
      passwordRequireNumbers: false,
      passwordRequireSpecialChars: false,
      enableBiometric: true,
      inactivityLockout: const Duration(hours: 24),
    );
  }

  factory AuthConfig.staging() {
    return AuthConfig(
      firebaseProjectId: 'admin-dashboard-staging',
      firebaseApiKey: 'staging-api-key',
      firebaseAuthDomain: 'admin-dashboard-staging.firebaseapp.com',
      firebaseAppId: 'staging-app-id',
      tokenRefreshInterval: const Duration(hours: 23),
      sessionTimeout: const Duration(hours: 24),
      maxLoginAttempts: 5,
      lockoutDuration: const Duration(minutes: 15),
      enableTwoFactor: true,
      requireEmailVerification: true,
      requirePhoneVerification: false,
      passwordMinLength: 8,
      passwordRequireUppercase: true,
      passwordRequireNumbers: true,
      passwordRequireSpecialChars: false,
      enableBiometric: true,
      inactivityLockout: const Duration(hours: 12),
    );
  }

  factory AuthConfig.production() {
    return AuthConfig(
      firebaseProjectId: 'admin-dashboard-prod',
      firebaseApiKey: 'prod-api-key',
      firebaseAuthDomain: 'admin-dashboard-prod.firebaseapp.com',
      firebaseAppId: 'prod-app-id',
      tokenRefreshInterval: const Duration(hours: 23),
      sessionTimeout: const Duration(hours: 24),
      maxLoginAttempts: 5,
      lockoutDuration: const Duration(minutes: 15),
      enableTwoFactor: true,
      requireEmailVerification: true,
      requirePhoneVerification: true,
      passwordMinLength: 12,
      passwordRequireUppercase: true,
      passwordRequireNumbers: true,
      passwordRequireSpecialChars: true,
      enableBiometric: false,
      inactivityLockout: const Duration(hours: 4),
    );
  }

  @override
  String toString() =>
      'AuthConfig(2FA: $enableTwoFactor, emailVerify: $requireEmailVerification, timeout: $sessionTimeout)';
}
