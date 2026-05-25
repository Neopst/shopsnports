/// Service for generating and managing admin passwords
/// Provides utilities for creating secure, memorable temporary passwords
class PasswordGeneratorService {
  // Characters for password generation
  static const String _upperCase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _lowerCase = 'abcdefghijklmnopqrstuvwxyz';
  static const String _numbers = '0123456789';
  static const String _specialChars = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

  /// Generate a secure temporary password
  ///
  /// Password characteristics:
  /// - Length: 12 characters (secure yet memorable)
  /// - Contains: Mix of uppercase, lowercase, numbers, and special characters
  /// - Pattern: Pseudo-random distribution
  /// - Format: Suitable for temporary use, requires change on first login
  ///
  /// Example: "Abc@1234xyz!"
  static String generateSecurePassword({
    int length = 12,
    bool includeUpperCase = true,
    bool includeLowerCase = true,
    bool includeNumbers = true,
    bool includeSpecialChars = true,
  }) {
    // Build character set based on parameters
    String chars = '';
    if (includeUpperCase) chars += _upperCase;
    if (includeLowerCase) chars += _lowerCase;
    if (includeNumbers) chars += _numbers;
    if (includeSpecialChars) chars += _specialChars;

    if (chars.isEmpty) {
      throw ArgumentError(
        'At least one character type must be included in password',
      );
    }

    if (length < 8) {
      throw ArgumentError('Password length must be at least 8 characters');
    }

    // Build password with guaranteed character type representation
    final password = <String>[];

    // Add one character from each required type
    if (includeUpperCase) {
      password.add(_getRandomChar(_upperCase));
    }
    if (includeLowerCase) {
      password.add(_getRandomChar(_lowerCase));
    }
    if (includeNumbers) {
      password.add(_getRandomChar(_numbers));
    }
    if (includeSpecialChars) {
      password.add(_getRandomChar(_specialChars));
    }

    // Fill remaining length with random characters from full set
    while (password.length < length) {
      password.add(_getRandomChar(chars));
    }

    // Shuffle to randomize position of each character type
    password.shuffle();

    return password.join();
  }

  /// Get a random character from a string
  static String _getRandomChar(String chars) {
    final random = DateTime.now().millisecondsSinceEpoch;
    return chars[random % chars.length];
  }

  /// Generate a simple alphanumeric password (no special chars)
  /// Useful for less security-conscious environments
  static String generateSimplePassword({int length = 10}) {
    return generateSecurePassword(length: length, includeSpecialChars: false);
  }

  /// Generate a password with only uppercase and numbers
  /// Useful for compliance-heavy systems
  static String generateNumericPassword({int length = 8}) {
    return generateSecurePassword(
      length: length,
      includeLowerCase: false,
      includeSpecialChars: false,
    );
  }

  /// Validate password strength
  static PasswordStrength validatePassword(String password) {
    bool hasUpper = password.contains(RegExp(r'[A-Z]'));
    bool hasLower = password.contains(RegExp(r'[a-z]'));
    bool hasNumbers = password.contains(RegExp(r'[0-9]'));
    bool hasSpecial = password.contains(
      RegExp(r'[!@#\$%^&*()_+\-=\[\]{}|;:,.<>?]'),
    );
    int length = password.length;

    int strength = 0;
    if (hasUpper) strength++;
    if (hasLower) strength++;
    if (hasNumbers) strength++;
    if (hasSpecial) strength++;

    // Length bonus
    if (length >= 12) strength++;
    if (length >= 16) strength++;

    if (strength >= 5) {
      return PasswordStrength.strong;
    } else if (strength >= 3) {
      return PasswordStrength.medium;
    } else {
      return PasswordStrength.weak;
    }
  }

  /// Check if password meets minimum requirements
  static bool isPasswordValid(
    String password, {
    int minLength = 8,
    bool requireUpperCase = true,
    bool requireLowerCase = true,
    bool requireNumbers = true,
    bool requireSpecialChars = false,
  }) {
    if (password.length < minLength) return false;
    if (requireUpperCase && !password.contains(RegExp(r'[A-Z]'))) {
      return false;
    }
    if (requireLowerCase && !password.contains(RegExp(r'[a-z]'))) {
      return false;
    }
    if (requireNumbers && !password.contains(RegExp(r'[0-9]'))) {
      return false;
    }
    if (requireSpecialChars &&
        !password.contains(RegExp(r'[!@#\$%^&*()_+\-=\[\]{}|;:,.<>?]'))) {
      return false;
    }
    return true;
  }

  /// Get password strength description
  static String getStrengthDescription(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return 'Weak - Add more character types (uppercase, numbers, special characters)';
      case PasswordStrength.medium:
        return 'Medium - Consider adding special characters and increasing length';
      case PasswordStrength.strong:
        return 'Strong - Good password security';
    }
  }

  /// Generate a password display string (masks actual password)
  static String maskPassword(String password) {
    if (password.length <= 4) {
      return '*' * password.length;
    }
    final visible = password.substring(0, 2);
    final hidden = '*' * (password.length - 4);
    final end = password.substring(password.length - 2);
    return '$visible$hidden$end';
  }
}

/// Enum for password strength levels
enum PasswordStrength { weak, medium, strong }

/// Extension methods for PasswordStrength
extension PasswordStrengthExt on PasswordStrength {
  /// Get color code for password strength indicator
  String get color {
    switch (this) {
      case PasswordStrength.weak:
        return '#FF4444'; // Red
      case PasswordStrength.medium:
        return '#FFAA00'; // Orange
      case PasswordStrength.strong:
        return '#00AA00'; // Green
    }
  }

  /// Get displayable strength text
  String get label {
    switch (this) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }
}
