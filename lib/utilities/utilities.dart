import 'dart:math';

class Utilities {
  static String generateRandomString(int len) {
    final r = Random();
    const _chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    return List.generate(len, (index) => _chars[r.nextInt(_chars.length)])
        .join();
  }

  static String convertCamelCaseToReadable(String input) {
    String output = '';
    for (int i = 0; i < input.length; i++) {
      if (i == 0) {
        output += input[i].toUpperCase();
      } else if (input[i].toUpperCase() == input[i]) {
        output += ' ${input[i]}';
      } else {
        output += input[i];
      }
    }
    return output;
  }

  static String insertDashes(String token) {
    //TODO: Make functional method that doesn't go boom!
    return token;
  }
}
