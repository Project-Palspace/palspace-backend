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
    String result = '';
    int step = (token.length % 2 == 0) ? 4 : 5; // if even length, step is 4, else step is 5
    for (int i = 0; i < token.length; i += step) {
      result += token.substring(i, i + step);
      if (i + step < token.length) {
        result += '-';
      }
    }
    return result;
  }
}
