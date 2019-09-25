import 'package:flutter/material.dart';

const Map<String, Map<String, Object>> mockIssuers = {
  'amsterdam': {
    'name': 'Gemeente Amsterdam',
    'color': Colors.white,
    'bg-color': Color(0xffec0000),
    'bg': 'amsterdam.png'
  },
  'duo': {'name': 'Dienst Uitvoering Onderwijs', 'color': Colors.white, 'bg-color': Color(0xff82a2b9), 'bg': 'duo.png'},
  'idin': {
    'name': 'iDIN',
    'color': Color(0xff424242), // darkgrey
    'bg-color': Color(0xff4ca9d6),
    'bg': 'idin.png'
  },
};

const Map<String, Map<String, List<Map<String, String>>>> mockCredentials = {
  'personalData': {
    'data': [
      {'key': 'Naam', 'value': 'Anouk Meijer', 'hidden': 'true'},
      {'key': 'Geboren', 'value': '4 juli 1990', 'hidden': 'true'},
      {'key': 'E-mail', 'value': 'anouk.meijer@gmail.com', 'hidden': 'false'},
    ],
    'metadata': [
      {'key': 'Geldig tot', 'value': '18 november 2019'}
    ]
  }
};
