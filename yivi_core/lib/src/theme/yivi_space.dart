/// The app's spacing scale: gaps and padding in steps of 4. Screens use
/// the role names where one fits, the scale where none does.
abstract final class YiviSpace {
  /// Hairline gaps, optical nudges.
  static const double x2 = 2;

  /// Icon to text in a chip, tight stacks.
  static const double x4 = 4;

  /// Between related items.
  static const double x8 = 8;

  /// Leading to text in a row, between cards.
  static const double x12 = 12;

  /// Page and sheet side gutter, inside cards.
  static const double x16 = 16;

  /// Between groups.
  static const double x24 = 24;

  /// Between sections.
  static const double x32 = 32;

  /// Around a hero or status picture.
  static const double x48 = 48;

  /// The widest gap on the scale.
  static const double x64 = 64;

  /// The side gutter of a page or sheet.
  static const double pageSide = x16;

  /// Padding inside a card.
  static const double cardInside = x16;

  /// Between rows and cards in a list.
  static const double rowGap = x12;

  /// Between groups on a page.
  static const double groupGap = x24;

  /// Between sections on a page.
  static const double sectionGap = x32;
}
