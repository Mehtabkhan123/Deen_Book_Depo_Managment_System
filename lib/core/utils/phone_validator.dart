/// Utility class for validating and formatting customer phone numbers
class PhoneValidator {
  PhoneValidator._();

  // Permitted phone pattern: optional '+' followed by digits, spaces, hyphens, and parenthesis
  static final RegExp _phonePattern = RegExp(r'^\+?[0-9\s\-()]{7,20}$');

  /// Checks if [phone] is a valid phone number.
  /// Requires between 7 and 15 digits (standard E.164 and Pakistani landline/mobile formats).
  static bool isValid(String? phone) {
    if (phone == null) return false;
    final trimmed = phone.trim();
    if (trimmed.isEmpty || trimmed == '--' || trimmed.toLowerCase() == 'n/a') {
      return false;
    }
    if (!_phonePattern.hasMatch(trimmed)) return false;

    final digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');
    return digitsOnly.length >= 7 && digitsOnly.length <= 15;
  }

  /// Formats validation error message or returns `null` if valid.
  static String? validate(String? phone, {bool isRequired = true}) {
    if (phone == null || phone.trim().isEmpty) {
      return isRequired ? 'Phone number is required for wholesale bills.' : null;
    }
    final trimmed = phone.trim();
    if (!isValid(trimmed)) {
      return 'Please enter a valid phone number (e.g., 0300-1234567 or 042-37234567).';
    }
    return null;
  }

  /// Normalizes phone number by trimming whitespace
  static String clean(String phone) {
    return phone.trim();
  }
}

