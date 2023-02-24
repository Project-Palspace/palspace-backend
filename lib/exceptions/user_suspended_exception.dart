class UserSuspendedException implements Exception {
  final String message;

  UserSuspendedException({this.message = 'User is suspended.'});
}
