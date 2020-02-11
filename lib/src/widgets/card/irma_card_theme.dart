import 'package:flutter/material.dart';
import 'package:irmamobile/src/models/credentials.dart';

class IrmaCardTheme {
  static const List<IrmaCardTheme> _defaultThemes = [
    IrmaCardTheme(
      backgroundGradientEnd: Color(0xff6CE6C1),
      backgroundGradientStart: Color(0xff3BB992),
      foregroundColor: Color(0xff15222E),
    ),
    IrmaCardTheme(
      backgroundGradientEnd: Color(0xff43C3E0),
      backgroundGradientStart: Color(0xff00B1E5),
      foregroundColor: Color(0xff15222E),
    ),
    IrmaCardTheme(
      backgroundGradientEnd: Color(0xffFFE8CD),
      backgroundGradientStart: Color(0xffFFB54C),
      foregroundColor: Color(0xff15222E),
    ),
    IrmaCardTheme(
      backgroundGradientEnd: Color(0xff2574A6),
      backgroundGradientStart: Color(0xff014483),
      foregroundColor: Color(0xffffffff),
    ),
    IrmaCardTheme(
      backgroundGradientEnd: Color(0xffD3263B),
      backgroundGradientStart: Color(0xffBD2D3B),
      foregroundColor: Color(0xffffffff),
    ),
  ];

  final Color foregroundColor;
  final Color backgroundGradientStart;
  final Color backgroundGradientEnd;

  const IrmaCardTheme({this.foregroundColor, this.backgroundGradientStart, this.backgroundGradientEnd});

  factory IrmaCardTheme.fromCredentialType(Credential credential) {
    final credentialType = credential.credentialType;
    final credentialTypeTheme = IrmaCardTheme(
      foregroundColor: credentialType.foregroundColor,
      backgroundGradientStart: credentialType.backgroundGradientStart,
      backgroundGradientEnd: credentialType.backgroundGradientEnd,
    );

    // If the credentialType theme is incomplete, use a default theme based on the issuer full id
    // This will make all cards from the same issuer appear the same
    if (!credentialTypeTheme.isComplete) {
      final int issuerHash = credential.issuer.fullId.runes.reduce((oldChar, newChar) => (oldChar << 1) ^ newChar);
      return _defaultThemes[issuerHash % _defaultThemes.length];
    }

    return credentialTypeTheme;
  }

  bool get isComplete => foregroundColor != null && backgroundGradientStart != null && backgroundGradientEnd != null;
}
