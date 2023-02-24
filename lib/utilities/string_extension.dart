extension StringEx on String {
  String get convertCamelCaseToReadable {
    String output = '';
    for (int i = 0; i < length; i++) {
      if (i == 0) {
        output += this[i].toUpperCase();
      } else if (this[i].toUpperCase() == this[i]) {
        output += ' ${this[i]}';
      } else {
        output += this[i];
      }
    }
    return output;
  }

  String get insertDashes {
    //TODO: FIXME
    // String result = '';
    // int step = (length % 2 == 0) ? 4 : 5; // if even length, step is 4, else step is 5
    // for (int i = 0; i < length; i += step) {
    //   result += substring(i, i + step);
    //   if (i + step < length) {
    //     result += '-';
    //   }
    // }
    return this;
  }
}
