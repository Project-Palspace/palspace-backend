class EmailValidationException implements Exception {
  final String message;

  EmailValidationException(this.message);

  @override
  String toString() {
    return message;
  }
}
