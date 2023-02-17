class UsernameTakenException implements Exception {
  final String message;

  UsernameTakenException(this.message);

  @override
  String toString() {
    return message;
  }
}
