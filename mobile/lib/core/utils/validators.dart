class Validators {
  Validators._();

  static final _emailRe = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9\-]+(\.[a-zA-Z0-9\-]+)*\.[a-zA-Z]{2,}$',
  );

  static String? email(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Enter your email';
    if (!_emailRe.hasMatch(value)) return 'Invalid email address';
    return null;
  }

  static String? loginPassword(String? v) =>
      (v == null || v.isEmpty) ? 'Enter your password' : null;

  static String? strongPassword(String? v) {
    final value = v ?? '';
    if (value.isEmpty) return 'Enter a password';
    if (value.length < 8) return 'Min 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Add at least 1 uppercase letter (A-Z)';
    if (!RegExp(r'[a-z]').hasMatch(value)) return 'Add at least 1 lowercase letter (a-z)';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Add at least 1 number (0-9)';
    return null;
  }
}