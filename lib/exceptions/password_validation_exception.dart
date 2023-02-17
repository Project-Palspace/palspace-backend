class PasswordValidationException implements Exception {
  final String message;

  PasswordValidationException(this.message);

  @override
  String toString() {
    return message;
  }
}
