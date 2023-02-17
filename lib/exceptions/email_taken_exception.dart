class EmailTakenException implements Exception {
  final String message;

  EmailTakenException(this.message);

  @override
  String toString() {
    return message;
  }
}