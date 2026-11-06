import "package:vcmrtd/vcmrtd.dart";

extension DocumentTranslationKeys on DocumentType {
  /// The document's prefix of its translation keys.
  String get keySegment => switch (this) {
    .passport => "passport",
    .identityCard => "id_card",
    .residencePermit => "residence_permit",
    .drivingLicence => "driving_licence",
  };

  /// App bar title shared with the MRZ scanning screen of this document.
  String get scanTitleKey => "$keySegment.scan.title";

  /// App bar title of the chip-reading screen.
  String get nfcTitleKey => "$keySegment.nfc.title";

  /// Where to find the details, under the manual entry fields.
  String get manualTipKey => "document_flow.manual.tip_$keySegment";

  /// The document's name, to fill the `{document}` placeholder of
  /// `document_flow.nfc.*` texts.
  String get nameKey => "document_flow.document.$keySegment";

  String get instructionKey => "document_flow.instruction.$keySegment";

  /// Names the NFC progress ring for screen readers.
  String get readingLabelKey => "document_flow.nfc.reading_label.$keySegment";
}
