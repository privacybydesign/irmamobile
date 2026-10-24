import "package:flutter/painting.dart";

/// The colours of the document and phone pictures in the document flow
/// (the NFC stages, the scan scene, the document faces). They have no theme
/// token: they are the same in both themes.
class DocumentColors {
  DocumentColors._();

  /// The passport's cover.
  static const passportCover = Color(0xFF7A1F2E);

  /// The fill of an identity card and of a driving licence.
  static const identityCardFill = Color(0xFFE5EDF6);
  static const drivingLicenceFill = Color(0xFFFCEBE4);

  /// A card's border, its printed lines and its chip.
  static const cardBorder = Color(0xFFC9D4E0);
  static const cardLines = Color(0xFFC3CFDC);
  static const cardChip = Color(0xFFD6C27A);

  /// The body of the phone held to the document.
  static const phone = Color(0xFF1D1D1D);
}
