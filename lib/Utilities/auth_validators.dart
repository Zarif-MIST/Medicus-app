class AuthValidators {
  const AuthValidators._();

  static String? requiredField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  static String? email(String? value) {
    final String? requiredResult = requiredField(value);
    if (requiredResult != null) {
      return requiredResult;
    }

    final String email = value!.trim();
    final RegExp pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? userId(String? value) {
    final String? requiredResult = requiredField(value);
    if (requiredResult != null) {
      return requiredResult;
    }

    if (!RegExp(r'^\d{4}$').hasMatch(value!.trim())) {
      return 'Enter the 4-digit user ID';
    }
    return null;
  }

  static String? password(String? value) {
    final String? requiredResult = requiredField(value);
    if (requiredResult != null) {
      return requiredResult;
    }

    final String password = value!.trim();
    final List<String> missingParts = <String>[];
    if (password.length < 8) {
      missingParts.add('8+ characters');
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      missingParts.add('one uppercase letter');
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      missingParts.add('one lowercase letter');
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      missingParts.add('one number');
    }
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) {
      missingParts.add('one special character');
    }

    if (missingParts.isNotEmpty) {
      return 'Use a stronger password with ${missingParts.join(', ')}';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    final String? requiredResult = requiredField(value);
    if (requiredResult != null) {
      return requiredResult;
    }

    if (value!.trim() != password.trim()) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? bangladeshPhone(String? value) {
    final String? requiredResult = requiredField(value);
    if (requiredResult != null) {
      return requiredResult;
    }

    final String digitsOnly = value!.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^1[3-9]\d{8}$').hasMatch(digitsOnly)) {
      return 'Enter a valid number after +880';
    }
    return null;
  }

  static String? numericCode(String? value, {int length = 6}) {
    final String? requiredResult = requiredField(value);
    if (requiredResult != null) {
      return requiredResult;
    }

    if (!RegExp('^\\d{' + length.toString() + r'}$').hasMatch(value!.trim())) {
      return 'Enter the $length digit code';
    }
    return null;
  }

  static String? nid(String? value) {
    final String? requiredResult = requiredField(value);
    if (requiredResult != null) {
      return requiredResult;
    }

    final String normalized = value!.replaceAll(RegExp(r'\s'), '');
    if (!RegExp(r'^\d{10,17}$').hasMatch(normalized)) {
      return 'Enter a valid NID or birth certificate number';
    }
    return null;
  }
}
