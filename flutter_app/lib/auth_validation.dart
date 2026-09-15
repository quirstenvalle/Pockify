class ValidationResult {
  final bool ok;
  final String? message;

  const ValidationResult._(this.ok, this.message);

  const ValidationResult.valid() : this._(true, null);

  const ValidationResult.invalid(String message) : this._(false, message);
}

bool isValidEmail(String email) {
  final trimmed = email.trim();
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed);
}

/// Password must start with a capital letter, be at least 8 characters,
/// and include at least one special character.
ValidationResult validatePassword(String password) {
  if (password.length < 8) {
    return const ValidationResult.invalid(
      'Password must be at least 8 characters.',
    );
  }
  if (!RegExp(r'^[A-Z]').hasMatch(password)) {
    return const ValidationResult.invalid(
      'Password must start with a capital letter.',
    );
  }
  if (!RegExp(r'''[!@#$%^&*(),.?":{}|<>_\-\+=\[\]\\\/;'`~]''').hasMatch(password)) {
    return const ValidationResult.invalid(
      'Password must include at least one special character.',
    );
  }
  return const ValidationResult.valid();
}

ValidationResult validateOtp(String code, {int length = 6}) {
  final trimmed = code.trim();
  if (trimmed.length != length || !RegExp(r'^\d+$').hasMatch(trimmed)) {
    return ValidationResult.invalid('Enter the $length-digit verification code.');
  }
  return const ValidationResult.valid();
}

ValidationResult validateLogin({
  required String email,
  required String password,
}) {
  if (!isValidEmail(email)) {
    return const ValidationResult.invalid('Enter a valid email address.');
  }
  return validatePassword(password);
}

ValidationResult validateSignup({
  required String name,
  required String email,
  required String password,
  required String confirmPassword,
  String? country,
  String employmentStatus = 'Select status',
  DateTime? birthDate,
}) {
  if (name.trim().isEmpty) {
    return const ValidationResult.invalid('Enter your full name.');
  }
  if (!isValidEmail(email)) {
    return const ValidationResult.invalid('Enter a valid email address.');
  }

  final passwordResult = validatePassword(password);
  if (!passwordResult.ok) return passwordResult;

  if (password != confirmPassword) {
    return const ValidationResult.invalid('Passwords do not match.');
  }
  if (country == null || country.trim().isEmpty) {
    return const ValidationResult.invalid('Select your country/region.');
  }
  if (birthDate == null) {
    return const ValidationResult.invalid('Select your birth date.');
  }
  if (employmentStatus == 'Select status') {
    return const ValidationResult.invalid('Select your employment status.');
  }

  return const ValidationResult.valid();
}
