import 'package:flutter/material.dart';

ThemeData themeData = ThemeData(
// Define the default brightness and colors.
  brightness: Brightness.light,
  primaryColor: Colors.lightBlue[800],
  accentColor: Colors.cyan[600],

// Define the default font family.
  fontFamily: 'Montserrat',

// Define the default TextTheme. Use this to specify the default
// text styling for headlines, titles, bodies of text, and more.
  textTheme: TextTheme(
    headline: TextStyle(
        fontSize: 18.0, fontWeight: FontWeight.w700, color: Colors.white),
    body1: TextStyle(
        fontSize: 14.0, fontWeight: FontWeight.w300, color: Colors.white),
  ),
);
