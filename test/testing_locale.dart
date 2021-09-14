// This code is not null safe yet.
// @dart=2.11

import 'package:flutter/widgets.dart';

class TestingLocale {
  static TestingLocale _instance;
  factory TestingLocale({@required Locale locale}) {
    return _instance = TestingLocale._internal(locale: locale);
  }

  // _internal is a named constructor only used by the factory
  TestingLocale._internal({
    @required this.locale,
  }) : assert(locale != null);

  static TestingLocale get() {
    if (_instance == null) {
      throw Exception('TestingLocale has not been initialized');
    }
    return _instance;
  }

  final Locale locale;
}
