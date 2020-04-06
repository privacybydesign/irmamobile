import 'package:flutter/material.dart';
import 'package:irmamobile/src/models/credentials.dart';

class IrmaCardTheme {
  static const List<IrmaCardTheme> _defaultThemes = [
    IrmaCardTheme(
      backgroundGradientStart: Color(0xFFE8ECf0),
      backgroundGradientEnd: Color(0xFFFFFFFF),
      foregroundColor: Color(0xFF014483),
    ),
  ];

  final Color foregroundColor;
  final Color backgroundGradientStart;
  final Color backgroundGradientEnd;

  const IrmaCardTheme({this.foregroundColor, this.backgroundGradientStart, this.backgroundGradientEnd});

  factory IrmaCardTheme.fromCredentialInfo(CredentialInfo credentialInfo) {
    final credentialType = credentialInfo.credentialType;
    final credentialTypeTheme = IrmaCardTheme(
      foregroundColor: credentialType.foregroundColor,
      backgroundGradientStart: credentialType.backgroundGradientStart,
      backgroundGradientEnd: credentialType.backgroundGradientEnd,
    );

    // If the credentialType theme is incomplete, use a default theme based on the issuer full id
    // This will make all cards from the same issuer appear the same
    if (!credentialTypeTheme.isComplete) {
      final int issuerHash = credentialInfo.issuer.fullId.runes.reduce((oldChar, newChar) => (oldChar << 1) ^ newChar);
      return _defaultThemes[issuerHash % _defaultThemes.length];
    }

    return credentialTypeTheme;
  }

  bool get isComplete => foregroundColor != null && backgroundGradientStart != null && backgroundGradientEnd != null;
}
