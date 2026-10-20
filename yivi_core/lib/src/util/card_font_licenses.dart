import "package:flutter/foundation.dart";
import "package:flutter/services.dart";

import "../../package_name.dart";

/// The licences (SIL Open Font License) of the typefaces the built-in card
/// templates use, for the licence registry. One file holds them all, each a
/// family name, a blank line and its licence, separated by form feeds.
Stream<LicenseEntry> cardFontLicenses() async* {
  final text = await rootBundle.loadString(yiviAsset("card_font_licenses.txt"));
  for (final part in text.split("\n\n\f\n")) {
    final split = part.indexOf("\n\n");
    if (split < 0) continue;
    yield LicenseEntryWithLineBreaks([
      part.substring(0, split).trim(),
    ], part.substring(split + 2));
  }
}
