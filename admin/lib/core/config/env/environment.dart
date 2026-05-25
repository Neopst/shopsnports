/// Environment configuration enum
/// Determines which configuration set to load (dev, staging, production)
enum Environment {
  development,
  staging,
  production;

  String get displayName {
    switch (this) {
      case Environment.development:
        return 'Development';
      case Environment.staging:
        return 'Staging';
      case Environment.production:
        return 'Production';
    }
  }

  String get apiBaseName {
    switch (this) {
      case Environment.development:
        return 'dev';
      case Environment.staging:
        return 'staging';
      case Environment.production:
        return 'prod';
    }
  }

  bool get isDevelopment => this == Environment.development;
  bool get isStaging => this == Environment.staging;
  bool get isProduction => this == Environment.production;
  bool get isDevOrStaging => isDevelopment || isStaging;
  bool get isNotProduction => !isProduction;
}

/// Get the current environment (defaults to development)
/// In production, this should be read from environment variables or build config
Environment getCurrentEnvironment() {
  const envString = String.fromEnvironment(
    'FLUTTER_ENV',
    defaultValue: 'development',
  );
  try {
    return Environment.values.byName(envString.toLowerCase());
  } catch (e) {
    // Default to development if invalid environment specified
    return Environment.development;
  }
}

/// Get environment from string value
Environment getEnvironmentFromString(String value) {
  try {
    return Environment.values.byName(value.toLowerCase());
  } catch (e) {
    return Environment.development;
  }
}
