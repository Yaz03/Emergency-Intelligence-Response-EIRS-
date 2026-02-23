/// Reusable form‑field validators.
class Validators {
  Validators._();

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final _phoneRegex = RegExp(r'^\+?[\d\s\-]{7,15}$');

  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? email(String? value) {
    final req = required(value, 'Email');
    if (req != null) return req;
    if (!_emailRegex.hasMatch(value!.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    final req = required(value, 'Password');
    if (req != null) return req;
    if (value!.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain an uppercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain a digit';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    final req = required(value, 'Confirm password');
    if (req != null) return req;
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? phone(String? value) {
    final req = required(value, 'Phone number');
    if (req != null) return req;
    if (!_phoneRegex.hasMatch(value!.trim())) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String? name(String? value) {
    final req = required(value, 'Name');
    if (req != null) return req;
    if (value!.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }
}
